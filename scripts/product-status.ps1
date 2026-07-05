$ErrorActionPreference = "Continue"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

Write-Host ""
Write-Host "ERA Product Status"
Write-Host "=================="
Write-Host ""

function Test-Port([int]$Port) {
    return [bool](netstat -ano | findstr "LISTENING" | findstr ":$Port ")
}

$apiUp = Test-Port 8000
$feUp = Test-Port 5173

Write-Host "Local stack:"
Write-Host "  API (8000):      $(if ($apiUp) { 'RUNNING' } else { 'stopped' })"
Write-Host "  Frontend (5173): $(if ($feUp) { 'RUNNING' } else { 'stopped' })"
Write-Host ""

if ($apiUp) {
    try {
        $health = Invoke-RestMethod -Uri "http://127.0.0.1:8000/health" -TimeoutSec 5
        Write-Host "API health:"
        Write-Host "  status:     $($health.status)"
        Write-Host "  standalone: $($health.standalone_mode)"
        Write-Host "  demo:       $($health.demo_mode)"
        $artifacts = Invoke-RestMethod -Uri "http://127.0.0.1:8000/artifacts?page=1&page_size=1" -TimeoutSec 5
        Write-Host "  artifacts:  $($artifacts.total)"
    } catch {
        Write-Host "  health check failed: $($_.Exception.Message)"
    }
} else {
    Write-Host "Start local product: .\scripts\start-standalone.ps1"
    Write-Host "Or double-click:     GO.bat"
}

Write-Host ""
Write-Host "Live Vercel:"
try {
    $live = Invoke-RestMethod -Uri "https://frontend-flax-two-11q4abvz2o.vercel.app/health" -TimeoutSec 10
    Write-Host "  status:              $($live.status)"
    Write-Host "  database_persistent: $($live.database_persistent)"
    Write-Host "  billing_configured:  $($live.billing_configured)"
    Write-Host "  openai_for_pro:      $($live.openai_for_pro)"
    if (-not ($live.database_persistent -and $live.billing_configured -and $live.openai_for_pro)) {
        Write-Host "  -> Run SETUP-PRODUCTION.bat then VERIFY-PRODUCTION.bat"
    }
} catch {
    Write-Host "  unreachable: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "Commands:"
Write-Host "  Verify local:  .\scripts\verify-product.ps1"
Write-Host "  Verify live:   .\VERIFY-PRODUCTION.bat"
Write-Host "  Owner setup:   .\SETUP-PRODUCTION.bat"
Write-Host "  Share:         .\scripts\share-local.ps1"
Write-Host "  Deploy:        .\scripts\deploy-paas.ps1"
Write-Host ""
