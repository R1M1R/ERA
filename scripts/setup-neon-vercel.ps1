param(
    [string]$DatabaseUrl = "",
    [switch]$SyncVercel
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$liveUrl = "https://frontend-flax-two-11q4abvz2o.vercel.app"

Write-Host ""
Write-Host "========================================"
Write-Host "  ERA - Neon Postgres for Pro licenses"
Write-Host "========================================"
Write-Host ""
Write-Host "  Without DATABASE_URL, Pro licenses reset on Vercel cold starts."
Write-Host "  Neon free tier: https://neon.tech"
Write-Host ""
Write-Host "  1. Create project + database"
Write-Host "  2. Copy connection string (postgresql://...)"
Write-Host "  3. Convert for ERA async API:"
Write-Host "     postgresql+asyncpg://USER:PASS@HOST/DB?sslmode=require"
Write-Host ""

if (-not $DatabaseUrl) {
    $DatabaseUrl = Read-Host "Paste DATABASE_URL (postgresql+asyncpg://...)"
}

$DatabaseUrl = $DatabaseUrl.Trim()
if (-not $DatabaseUrl.StartsWith("postgresql")) {
    Write-Host "[ERA] DATABASE_URL must start with postgresql:// or postgresql+asyncpg://"
    exit 1
}

$SyncUrl = $DatabaseUrl -replace "postgresql\+asyncpg://", "postgresql+psycopg2://"
if ($SyncUrl -eq $DatabaseUrl) {
    $SyncUrl = $DatabaseUrl -replace "postgresql://", "postgresql+psycopg2://"
}

$secretsPath = Join-Path $Root ".secrets.local"
$lines = @(
    "DATABASE_URL=$DatabaseUrl",
    "DATABASE_URL_SYNC=$SyncUrl"
)
foreach ($line in $lines) {
    $key = ($line -split "=", 2)[0]
    if (Test-Path $secretsPath) {
        $content = Get-Content $secretsPath -Raw
        if ($content -match "(?m)^\s*$([regex]::Escape($key))=") {
            $content = $content -replace "(?m)^\s*$([regex]::Escape($key))=.*", $line
            Set-Content -Path $secretsPath -Value $content.TrimEnd() -NoNewline
            Add-Content -Path $secretsPath -Value "`n"
        } else {
            Add-Content -Path $secretsPath -Value "`n$line`n"
        }
    } else {
        Add-Content -Path $secretsPath -Value "$line`n"
    }
}

Write-Host ""
Write-Host "[OK] Saved to .secrets.local"
Write-Host ""
Write-Host "Add to Vercel production:"
Write-Host "  cd `"$Root`""
Write-Host "  echo $DatabaseUrl | npx vercel env add DATABASE_URL production"
Write-Host "  echo $SyncUrl | npx vercel env add DATABASE_URL_SYNC production"
Write-Host "  npx vercel --prod"
Write-Host ""
Write-Host "Verify: GET $liveUrl/health -> database_persistent: true"
Write-Host ""

if ($SyncVercel) {
    & (Join-Path $PSScriptRoot "sync-vercel-env.ps1") -Deploy
}

$open = Read-Host "Open Neon console? [Y/n]"
if ($open -ne 'n' -and $open -ne 'N') {
    Start-Process "https://console.neon.tech"
}
