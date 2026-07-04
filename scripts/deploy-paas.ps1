param(
    [switch]$SkipLocalCheck,
    [switch]$SkipBrowser
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

Write-Host ""
Write-Host "========================================"
Write-Host "  ERA - Public Deployment Wizard (PaaS)"
Write-Host "========================================"
Write-Host ""
Write-Host "Stack: Neon + Upstash + Render + Vercel (free tier)"
Write-Host "Repo:  https://github.com/R1M1R/ERA"
Write-Host ""

if (-not $SkipLocalCheck) {
    Write-Host "[1/5] Verifying local product..."
    & (Join-Path $PSScriptRoot "verify-product.ps1")
    Write-Host ""
}

Write-Host "[2/5] Opening PaaS signup pages..."
$urls = @(
    "https://neon.tech",
    "https://upstash.com",
    "https://dashboard.render.com/select-repo?type=blueprint",
    "https://vercel.com/new"
)
if (-not $SkipBrowser) {
    foreach ($url in $urls) {
        Start-Process $url
        Start-Sleep -Milliseconds 500
    }
}

Write-Host ""
Write-Host "[3/5] Generate env checklist for Render + Vercel..."
& (Join-Path $PSScriptRoot "paas-prep.ps1")

Write-Host ""
Write-Host "[4/5] Render Blueprint (one-click):"
Write-Host "  https://render.com/deploy?repo=https://github.com/R1M1R/ERA"
Write-Host "  Paste env vars from paas-env-checklist.txt"
Write-Host "  Set OPENAI_API_KEY on era-api AND era-celery"
Write-Host "  Tip: ERA_DEMO_MODE=true works without OpenAI for first test"
Write-Host ""

Write-Host "[5/5] After Render + Vercel deploy:"
Write-Host "  - Vercel env: VITE_API_URL=https://YOUR-API.onrender.com"
Write-Host "  - Render era-api: CORS_ORIGINS=https://YOUR-APP.vercel.app"
Write-Host "  - Redeploy era-api after CORS update"
Write-Host ""
Write-Host "Verify production:"
Write-Host "  .\scripts\verify-paas.ps1 -ApiUrl https://YOUR-API.onrender.com -FullE2E"
Write-Host ""
Write-Host "Full checklist: deploy\paas\CHECKLIST.md"
Write-Host ""
