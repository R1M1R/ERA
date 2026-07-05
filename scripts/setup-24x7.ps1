param(
    [switch]$SkipLocalStart,
    [switch]$OpenDeployPages
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

Write-Host ""
Write-Host "========================================"
Write-Host "  ERA - 24/7 Setup"
Write-Host "========================================"
Write-Host ""

& (Join-Path $PSScriptRoot "setup-keys.ps1")

Write-Host ""
Write-Host "[1/3] Local product (works while PC is on)..."
if (-not $SkipLocalStart) {
    & (Join-Path $PSScriptRoot "start-standalone.ps1")
}
& (Join-Path $PSScriptRoot "verify-product.ps1")

Write-Host ""
Write-Host "[2/3] Production checklist for always-on cloud..."
& (Join-Path $PSScriptRoot "paas-prep.ps1") -NonInteractive

$secretsPath = Join-Path $Root ".secrets.local"
$hasNeon = Select-String -Path $secretsPath -Pattern '^\s*DATABASE_URL=' -Quiet -ErrorAction SilentlyContinue
$hasRedis = Select-String -Path $secretsPath -Pattern '^\s*(REDIS_URL|CELERY_BROKER_URL)=' -Quiet -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[3/3] 24/7 status"
Write-Host ""
Write-Host "  LOCAL (now):     http://localhost:5173  - works while this PC runs"
Write-Host "  CLOUD (24/7):    DEPLOY_CLOUD.bat -> Render one-click (no Neon/Upstash)"
Write-Host ""

Write-Host "  Quick cloud deploy:"
Write-Host "    Double-click DEPLOY_CLOUD.bat"
Write-Host "    Or open: https://render.com/deploy?repo=https://github.com/R1M1R/ERA"
Write-Host ""

if ($hasNeon -and $hasRedis) {
    Write-Host "  Full PaaS keys found in .secrets.local (render-full.yaml)"
    Write-Host "  Use DEPLOY.bat for Postgres + Celery worker"
} else {
    Write-Host "  Lite mode needs no .secrets.local (SQLite on Render)"
}

if ($OpenDeployPages) {
    Start-Process "https://render.com/deploy?repo=https://github.com/R1M1R/ERA"
    Start-Process "https://frontend-flax-two-11q4abvz2o.vercel.app"
}

Write-Host ""
