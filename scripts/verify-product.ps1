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
    param(
        [string]$FrontendUrl = "http://localhost:5173",
        [int]$WaitSec = 45
    )
    Write-Host -NoNewline "[ERA] Frontend proxy ($FrontendUrl/health) ... "
    $deadline = (Get-Date).AddSeconds($WaitSec)
    while ((Get-Date) -lt $deadline) {
        try {
            $health = Invoke-RestMethod -Uri "$FrontendUrl/health" -TimeoutSec 5
            if ($health.status -eq "ok") {
                Write-Host "OK"
                return $true
            }
        } catch {
            Start-Sleep -Seconds 2
        }
    }
    Write-Host "FAIL (frontend not ready in ${WaitSec}s)"
    return $false
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
