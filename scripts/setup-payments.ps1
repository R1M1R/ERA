param(
    [string]$PaymentLink = ""
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$secretsPath = Join-Path $Root ".secrets.local"
$liveUrl = "https://frontend-flax-two-11q4abvz2o.vercel.app"

Write-Host ""
Write-Host "========================================"
Write-Host "  ERA - Pro payments (passive income)"
Write-Host "========================================"
Write-Host ""
Write-Host "  Stripe is NOT available in Kyrgyzstan."
Write-Host "  Use Lemon Squeezy, Paddle, or Gumroad (Merchant of Record)."
Write-Host ""
Write-Host "  Guide: docs/MONETIZATION.ru.md"
Write-Host "  Live:   $liveUrl"
Write-Host ""

if (-not $PaymentLink) {
    Write-Host "Recommended: Lemon Squeezy - create ERA Pro subscription `$12/month"
    Write-Host "  https://www.lemonsqueezy.com"
    Write-Host ""
    $PaymentLink = Read-Host "Paste checkout URL (https://...lemonsqueezy.com/... or other)"
}

$PaymentLink = $PaymentLink.Trim()
if (-not $PaymentLink.StartsWith("https://")) {
    Write-Host "[ERA] Invalid URL. Must start with https://"
    exit 1
}

$line = "VITE_PRO_PAYMENT_LINK=$PaymentLink"
if (Test-Path $secretsPath) {
    $content = Get-Content $secretsPath -Raw
    if ($content -match '(?m)^\s*VITE_PRO_PAYMENT_LINK=') {
        $content = $content -replace '(?m)^\s*VITE_PRO_PAYMENT_LINK=.*', $line
        Set-Content -Path $secretsPath -Value $content.TrimEnd() -NoNewline
        Add-Content -Path $secretsPath -Value "`n"
    } else {
        Add-Content -Path $secretsPath -Value "`n# Pro checkout (Lemon Squeezy etc.)`n$line`n"
    }
} else {
    @"
# ERA secrets (gitignored)
VITE_PRO_PAYMENT_LINK=$PaymentLink
"@ | Set-Content -Path $secretsPath
}

Write-Host ""
Write-Host "[OK] Saved to .secrets.local"
Write-Host ""
Write-Host "Add to Vercel production:"
Write-Host "  cd `"$Root`""
Write-Host "  echo $PaymentLink | npx vercel env add VITE_PRO_PAYMENT_LINK production"
Write-Host "  npx vercel --prod"
Write-Host ""

$open = Read-Host "Open Lemon Squeezy now? [Y/n]"
if ($open -ne 'n' -and $open -ne 'N') {
    Start-Process "https://www.lemonsqueezy.com"
}
