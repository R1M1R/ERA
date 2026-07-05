param(
    [switch]$SyncVercel
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$secretsPath = Join-Path $Root ".secrets.local"
$examplePath = Join-Path $Root ".secrets.local.example"

function New-RandomSalt([int]$ByteLength = 36) {
    $bytes = New-Object byte[] $ByteLength
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return -join ($bytes | ForEach-Object { "{0:x2}" -f $_ })
}

function Read-SecretsFile([string]$Path) {
    $result = @{}
    if (-not (Test-Path $Path)) { return $result }
    Get-Content $Path | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $result[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
    return $result
}

function Set-SecretValue {
    param([string]$Key, [string]$Value)
    if (Test-Path $secretsPath) {
        $content = Get-Content $secretsPath -Raw
        $line = "$Key=$Value"
        if ($content -match "(?m)^\s*$([regex]::Escape($Key))=") {
            $content = $content -replace "(?m)^\s*$([regex]::Escape($Key))=.*", $line
            Set-Content -Path $secretsPath -Value $content.TrimEnd() -NoNewline
            Add-Content -Path $secretsPath -Value "`n"
        } else {
            Add-Content -Path $secretsPath -Value "`n$line`n"
        }
    } else {
        if (Test-Path $examplePath) {
            Copy-Item $examplePath $secretsPath
        } else {
            Set-Content -Path $secretsPath -Value "# ERA secrets`n"
        }
        Set-SecretValue -Key $Key -Value $Value
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "  ERA - Bootstrap owner secrets"
Write-Host "========================================"
Write-Host ""

if (-not (Test-Path $secretsPath)) {
    if (Test-Path $examplePath) {
        Copy-Item $examplePath $secretsPath
        Write-Host "  Created .secrets.local from example"
    } else {
        Set-Content -Path $secretsPath -Value "# ERA secrets (gitignored)`n"
        Write-Host "  Created empty .secrets.local"
    }
}

$secrets = Read-SecretsFile $secretsPath
$created = 0

if (-not $secrets["ERA_SERVER_SALT"]) {
    $salt = New-RandomSalt
    Set-SecretValue -Key "ERA_SERVER_SALT" -Value $salt
    Write-Host "  [OK] Generated ERA_SERVER_SALT"
    $created++
} else {
    Write-Host "  [OK] ERA_SERVER_SALT already in .secrets.local"
    Write-Host "       Do not overwrite Vercel ERA_SERVER_SALT unless you intend to rotate hashes."
}

$payment = $secrets["VITE_PRO_PAYMENT_LINK"]
if ($payment) {
    Write-Host "  [OK] VITE_PRO_PAYMENT_LINK already set"
} else {
    Write-Host "  [--] VITE_PRO_PAYMENT_LINK missing (run MONETIZE.bat)"
}

foreach ($key in @("DATABASE_URL", "LEMONSQUEEZY_WEBHOOK_SECRET", "OPENAI_API_KEY")) {
    if ($secrets[$key]) {
        Write-Host "  [OK] $key set"
    } else {
        Write-Host "  [--] $key missing"
    }
}

Write-Host ""
if ($created -gt 0) {
    Write-Host "Updated .secrets.local ($created new value(s))."
} else {
    Write-Host ".secrets.local is ready for review."
}

if ($SyncVercel) {
    Write-Host ""
    & (Join-Path $PSScriptRoot "sync-vercel-env.ps1") -Deploy
}
