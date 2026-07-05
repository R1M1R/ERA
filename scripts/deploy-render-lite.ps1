param(
    [string]$ApiUrl = "https://era-api.onrender.com",
    [int]$TimeoutMinutes = 20,
    [switch]$SkipBrowser
)

$ErrorActionPreference = "Continue"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$deployUrl = "https://render.com/deploy?repo=https://github.com/R1M1R/ERA"
$healthUrl = "$ApiUrl/health"

Write-Host ""
Write-Host "========================================"
Write-Host "  ERA - Cloud Backend (Render Lite)"
Write-Host "========================================"
Write-Host ""
Write-Host "  Deploy URL: $deployUrl"
Write-Host "  API health: $healthUrl"
Write-Host ""

if (-not $SkipBrowser) {
    Write-Host "[1/3] Opening Render deploy page..."
    Write-Host "      Sign in with GitHub -> Apply -> wait until era-api is Live"
    Start-Process $deployUrl
} else {
    Write-Host "[1/3] Skipping browser (SkipBrowser)"
}

Write-Host ""
Write-Host "[2/3] Waiting for API (up to $TimeoutMinutes min, cold start may take 90s)..."
$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
$attempt = 0

while ((Get-Date) -lt $deadline) {
    $attempt++
    try {
        $response = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 120 -Method Get
        if ($response.status -eq "ok" -or $response.standalone_mode -eq $true) {
            Write-Host ""
            Write-Host "[OK] API is live!"
            Write-Host "     status: $($response.status)"
            Write-Host "     standalone: $($response.standalone_mode)"
            Write-Host "     demo: $($response.demo_mode)"
            Write-Host ""
            Write-Host "[3/3] Running E2E verification..."
            & (Join-Path $PSScriptRoot "verify-paas.ps1") -ApiUrl $ApiUrl -FullE2E
            Write-Host ""
            Write-Host "Live app: https://frontend-flax-two-11q4abvz2o.vercel.app"
            Write-Host "GitHub:   https://github.com/R1M1R/ERA"
            exit 0
        }
    } catch {
        $msg = $_.Exception.Message
        if ($attempt % 4 -eq 0) {
            Write-Host "  ... still waiting ($attempt) - $msg"
        }
    }
    Start-Sleep -Seconds 15
}

Write-Host ""
Write-Host "[TIMEOUT] API not reachable yet."
Write-Host "  1. Finish Render deploy (era-api -> Live)"
Write-Host "  2. Re-run: .\scripts\deploy-render-lite.ps1"
Write-Host "  3. Or check: $healthUrl"
exit 1
