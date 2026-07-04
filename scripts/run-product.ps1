param(
    [switch]$SkipFrontend,
    [switch]$E2EOnly
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$venvPython = Join-Path $Root "backend\venv\Scripts\python.exe"

function Test-ApiHealthy {
    param([string]$ApiUrl = "http://127.0.0.1:8000")
    try {
        $health = Invoke-RestMethod -Uri "$ApiUrl/health" -TimeoutSec 3
        return $health.status -eq "ok"
    } catch {
        return $false
    }
}

if (-not $E2EOnly) {
    & (Join-Path $PSScriptRoot "start-standalone.ps1") -SkipFrontend:$SkipFrontend
    if (-not (Test-ApiHealthy)) {
        Write-Host "[ERA] Waiting for API..."
        Start-Sleep -Seconds 6
    }
}

& $venvPython (Join-Path $Root "backend\scripts\e2e_standalone.py") --api-url "http://127.0.0.1:8000"

Write-Host ""
Write-Host "[ERA] Product is ready."
Write-Host "  Open http://localhost:5173 and click Generate."
if (-not $SkipFrontend -and -not $E2EOnly) {
    Write-Host "  Frontend window should already be open."
}
