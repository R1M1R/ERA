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
Write-Host "  CLOUD (24/7):    needs Neon + Upstash + Render + Vercel"
Write-Host ""

if ($hasNeon -and $hasRedis) {
    Write-Host "  Production keys found in .secrets.local"
    Write-Host "  Next: double-click DEPLOY.bat or open:"
    Write-Host "  https://render.com/deploy?repo=https://github.com/R1M1R/ERA"
} else {
    Write-Host "  Missing cloud keys (cannot deploy 24/7 automatically):"
    if (-not $hasNeon) { Write-Host "    - DATABASE_URL  (Neon: https://neon.tech)" }
    if (-not $hasRedis) { Write-Host "    - REDIS_URL     (Upstash: https://upstash.com)" }
    Write-Host ""
    Write-Host "  Copy .secrets.local.example -> .secrets.local, paste keys, re-run setup-24x7.ps1"
    Write-Host "  Or run DEPLOY.bat for guided wizard (~15 min, free tier)"
}

if ($OpenDeployPages) {
    Start-Process "https://render.com/deploy?repo=https://github.com/R1M1R/ERA"
    Start-Process "https://neon.tech"
    Start-Process "https://upstash.com"
    Start-Process "https://vercel.com/new"
}

Write-Host ""
