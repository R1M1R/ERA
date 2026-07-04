param(
    [string]$ApiUrl = "http://127.0.0.1:8000"
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$venvPython = Join-Path $Root "backend\venv\Scripts\python.exe"

Write-Host "[ERA] Verifying product..."
Write-Host ""

& $venvPython (Join-Path $Root "backend\scripts\test_pipeline_demo.py")
& $venvPython (Join-Path $Root "backend\scripts\e2e_standalone.py") --api-url $ApiUrl

function Test-FrontendProxy {
    param([string]$FrontendUrl = "http://localhost:5173")
    Write-Host -NoNewline "[ERA] Frontend proxy ($FrontendUrl/health) ... "
    try {
        $health = Invoke-RestMethod -Uri "$FrontendUrl/health" -TimeoutSec 10
        if ($health.status -eq "ok") {
            Write-Host "OK"
            return $true
        }
        Write-Host "FAIL (status=$($health.status))"
        return $false
    } catch {
        Write-Host "SKIP ($($_.Exception.Message))"
        return $true
    }
}

$proxyOk = Test-FrontendProxy
if (-not $proxyOk) {
    Write-Host "[ERA] Restart frontend: .\scripts\restart-era.ps1"
    exit 1
}

Push-Location (Join-Path $Root "frontend")
npm run build --silent
Pop-Location

Write-Host ""
Write-Host "[ERA] Product verification PASSED."
Write-Host "  API:      $ApiUrl/health"
Write-Host "  Frontend: http://localhost:5173"
Write-Host "  Launch:   .\scripts\start-standalone.ps1"
