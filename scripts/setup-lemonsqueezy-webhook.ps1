param(
    [string]$WebhookSecret = ""
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$secretsPath = Join-Path $Root ".secrets.local"
$liveUrl = "https://frontend-flax-two-11q4abvz2o.vercel.app"
$webhookUrl = "$liveUrl/webhooks/lemonsqueezy"

Write-Host ""
Write-Host "========================================"
Write-Host "  ERA - Lemon Squeezy webhook"
Write-Host "========================================"
Write-Host ""
Write-Host "  1. Lemon Squeezy -> Settings -> Webhooks"
Write-Host "  2. Callback URL:"
Write-Host "     $webhookUrl"
Write-Host "  3. Events: subscription_created, subscription_updated,"
Write-Host "     subscription_cancelled, subscription_expired,"
Write-Host "     subscription_payment_success"
Write-Host ""

if (-not $WebhookSecret) {
    $WebhookSecret = Read-Host "Paste Signing secret from Lemon Squeezy"
}

$WebhookSecret = $WebhookSecret.Trim()
if (-not $WebhookSecret) {
    Write-Host "[ERA] Signing secret is required."
    exit 1
}

$line = "LEMONSQUEEZY_WEBHOOK_SECRET=$WebhookSecret"
if (Test-Path $secretsPath) {
    $content = Get-Content $secretsPath -Raw
    if ($content -match '(?m)^\s*LEMONSQUEEZY_WEBHOOK_SECRET=') {
        $content = $content -replace '(?m)^\s*LEMONSQUEEZY_WEBHOOK_SECRET=.*', $line
        Set-Content -Path $secretsPath -Value $content.TrimEnd() -NoNewline
        Add-Content -Path $secretsPath -Value "`n"
    } else {
        Add-Content -Path $secretsPath -Value "`n# Lemon Squeezy webhook`n$line`n"
    }
} else {
    @"
# ERA secrets (gitignored)
$line
"@ | Set-Content -Path $secretsPath
}

Write-Host ""
Write-Host "[OK] Saved to .secrets.local"
Write-Host ""
Write-Host "Add to Vercel production:"
Write-Host "  cd `"$Root`""
Write-Host "  echo $WebhookSecret | npx vercel env add LEMONSQUEEZY_WEBHOOK_SECRET production"
Write-Host "  npx vercel --prod"
Write-Host ""

$open = Read-Host "Open Lemon Squeezy webhooks page? [Y/n]"
if ($open -ne 'n' -and $open -ne 'N') {
    Start-Process "https://app.lemonsqueezy.com/settings/webhooks"
}
