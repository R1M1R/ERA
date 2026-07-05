param(
    [string]$SecretsPath = "",
    [ValidateSet("production", "preview", "development")]
    [string]$Environment = "production",
    [switch]$Deploy
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

if (-not $SecretsPath) {
    $SecretsPath = Join-Path $Root ".secrets.local"
}

if (-not (Test-Path $SecretsPath)) {
    Write-Host "[ERA] Missing secrets file: $SecretsPath"
    Write-Host "      Copy .secrets.local.example and fill in values."
    exit 1
}

$syncKeys = @(
    "ERA_SERVER_SALT",
    "DATABASE_URL",
    "DATABASE_URL_SYNC",
    "LEMONSQUEEZY_WEBHOOK_SECRET",
    "OPENAI_API_KEY",
    "OPENAI_MODEL",
    "VITE_PRO_PAYMENT_LINK",
    "CORS_ORIGINS"
)

function Read-SecretsFile {
    param([string]$Path)
    $result = @{}
    Get-Content $Path | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $result[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
    return $result
}

function Get-VercelEnvNames {
    param([string]$EnvName)
    $output = npx vercel env ls $EnvName 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "vercel env ls failed: $output"
    }
    $names = @()
    foreach ($line in ($output -split "`n")) {
        if ($line -match '^\s+([A-Z0-9_]+)\s+') {
            $names += $matches[1]
        }
    }
    return $names
}

function Set-VercelEnv {
    param(
        [string]$Name,
        [string]$Value,
        [string]$EnvName
    )
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -Path $tempFile -Value $Value -NoNewline -Encoding utf8
        Get-Content $tempFile | npx vercel env add $Name $EnvName --force 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "vercel env add failed for $Name"
        }
        Write-Host "  [OK] $Name"
    } finally {
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "  ERA - Sync secrets to Vercel ($Environment)"
Write-Host "========================================"
Write-Host ""

$secrets = Read-SecretsFile $SecretsPath
$existing = Get-VercelEnvNames $Environment
$updated = 0
$skipped = 0

foreach ($key in $syncKeys) {
    $value = $secrets[$key]
    if (-not $value) {
        Write-Host "  [--] $key (not in .secrets.local)"
        $skipped++
        continue
    }
    if ($existing -contains $key) {
        Write-Host "  [..] $key (refreshing on Vercel)"
    }
    Set-VercelEnv -Name $key -Value $value -EnvName $Environment
    $updated++
}

Write-Host ""
Write-Host "Synced $updated variable(s); skipped $skipped missing local value(s)."
Write-Host ""

if ($Deploy) {
    Write-Host "Deploying production..."
    Push-Location $Root
    try {
        npx vercel --prod --yes 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "vercel --prod failed"
        }
        Write-Host "[OK] Production deployment triggered."
    } finally {
        Pop-Location
    }
}

if ($skipped -gt 0) {
    Write-Host "Still needed in .secrets.local for full Pro production:"
    foreach ($key in $syncKeys) {
        if (-not $secrets[$key]) {
            Write-Host "  - $key"
        }
    }
    Write-Host ""
    Write-Host "Run SETUP-PRODUCTION.bat or edit .secrets.local then re-run this script."
}
