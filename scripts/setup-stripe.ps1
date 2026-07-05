param(
    [string]$StripeProLink = ""
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$secretsPath = Join-Path $Root ".secrets.local"
$liveUrl = "https://frontend-flax-two-11q4abvz2o.vercel.app"

Write-Host ""
Write-Host "========================================"
Write-Host "  ERA - Stripe Pro (passive income)"
Write-Host "========================================"
Write-Host ""
Write-Host "  Live app: $liveUrl"
Write-Host "  GitHub:   https://github.com/R1M1R/ERA"
Write-Host ""

if (-not $StripeProLink) {
    Write-Host "1. Open Stripe Payment Links and create a `$12/month subscription:"
    Write-Host "   https://dashboard.stripe.com/payment-links"
    Write-Host ""
    $StripeProLink = Read-Host "2. Paste your Payment Link URL (https://buy.stripe.com/...)"
}

$StripeProLink = $StripeProLink.Trim()
if (-not $StripeProLink.StartsWith("https://")) {
    Write-Host "[ERA] Invalid URL. Must start with https://"
    exit 1
}

$line = "VITE_STRIPE_PRO_LINK=$StripeProLink"
if (Test-Path $secretsPath) {
    $content = Get-Content $secretsPath -Raw
    if ($content -match '(?m)^\s*VITE_STRIPE_PRO_LINK=') {
        $content = $content -replace '(?m)^\s*VITE_STRIPE_PRO_LINK=.*', $line
        Set-Content -Path $secretsPath -Value $content.TrimEnd() -NoNewline
        Add-Content -Path $secretsPath -Value "`n"
    } else {
        Add-Content -Path $secretsPath -Value "`n# Stripe Pro`n$line`n"
    }
} else {
    @"
# ERA secrets (gitignored) — created by setup-stripe.ps1
VITE_STRIPE_PRO_LINK=$StripeProLink
"@ | Set-Content -Path $secretsPath
}

Write-Host ""
Write-Host "[OK] Saved to .secrets.local"
Write-Host ""
Write-Host "3. Add to Vercel production (run from repo root):"
Write-Host "   cd `"$Root`""
Write-Host "   echo $StripeProLink | npx vercel env add VITE_STRIPE_PRO_LINK production"
Write-Host "   npx vercel --prod"
Write-Host ""
Write-Host "4. Optional: set OPENAI_API_KEY on Vercel for real GPT riddles (Pro tier)."
Write-Host ""

$open = Read-Host "Open Stripe dashboard now? [Y/n]"
if ($open -ne 'n' -and $open -ne 'N') {
    Start-Process "https://dashboard.stripe.com/payment-links"
}
