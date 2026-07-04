param(
    [int]$TimeoutSec = 180
)

$ErrorActionPreference = "Continue"

function Test-DockerReady {
    docker info *> $null
    return $LASTEXITCODE -eq 0
}

if (Test-DockerReady) {
    Write-Host "[ERA] Docker is already running."
    exit 0
}

$dockerPaths = @(
    "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
    "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe"
)

$exe = $dockerPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $exe) {
    Write-Host "[ERA] Docker Desktop not installed."
    Write-Host "      Download: https://www.docker.com/products/docker-desktop/"
    exit 1
}

Write-Host "[ERA] Starting Docker Desktop..."
Start-Process $exe

$deadline = (Get-Date).AddSeconds($TimeoutSec)
while ((Get-Date) -lt $deadline) {
    if (Test-DockerReady) {
        Write-Host "[ERA] Docker is ready."
        exit 0
    }
    Start-Sleep -Seconds 3
}

Write-Host "[ERA] Docker did not become ready within ${TimeoutSec}s."
Write-Host "      Open Docker Desktop manually and wait until it shows 'Running'."
exit 1
