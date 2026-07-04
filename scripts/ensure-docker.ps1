param(
    [int]$TimeoutSec = 180,
    [int]$DockerCmdTimeoutSec = 8
)

$ErrorActionPreference = "Continue"

function Invoke-DockerCheck {
    $job = Start-Job -ScriptBlock {
        docker info *> $null
        return $LASTEXITCODE
    }
    $done = Wait-Job $job -Timeout $DockerCmdTimeoutSec
    if (-not $done) {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -ErrorAction SilentlyContinue
        return $false
    }
    $code = Receive-Job $job
    Remove-Job $job -ErrorAction SilentlyContinue
    return $code -eq 0
}

if (Invoke-DockerCheck) {
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

Write-Host "[ERA] Starting Docker Desktop (wait up to ${TimeoutSec}s)..."
$proc = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
if (-not $proc) {
    Start-Process $exe
}

$deadline = (Get-Date).AddSeconds($TimeoutSec)
$attempt = 0
while ((Get-Date) -lt $deadline) {
    $attempt++
    if (Invoke-DockerCheck) {
        Write-Host "[ERA] Docker is ready (attempt $attempt)."
        exit 0
    }
    if ($attempt % 5 -eq 0) {
        Write-Host "[ERA] Still waiting for Docker..."
    }
    Start-Sleep -Seconds 3
}

Write-Host "[ERA] Docker did not become ready within ${TimeoutSec}s."
Write-Host "      1. Open Docker Desktop manually"
Write-Host "      2. Wait until status shows 'Engine running'"
Write-Host "      3. Re-run: .\scripts\ensure-docker.ps1"
exit 1
