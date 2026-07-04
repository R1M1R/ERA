param(
    [string]$OpenAiKey = "",
    [switch]$ForceSalt
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$envFile = Join-Path $Root ".env"
$frontendEnv = Join-Path $Root "frontend\.env"
$standaloneExample = Join-Path $Root ".env.standalone.example"

function New-RandomSalt([int]$Length = 48) {
    $bytes = New-Object byte[] 36
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    -join ($bytes | ForEach-Object { "{0:x2}" -f $_ })
}

function Read-EnvValue([string]$Path, [string]$Key) {
    if (-not (Test-Path $Path)) { return "" }
    $line = Select-String -Path $Path -Pattern "^\s*$([regex]::Escape($Key))\s*=" | Select-Object -First 1
    if (-not $line) { return "" }
    return ($line.Line -split "=", 2)[1].Trim()
}

Write-Host "[ERA] Setting up environment keys..."
Write-Host ""

$systemOpenAi = $env:OPENAI_API_KEY
if (-not $OpenAiKey -and $systemOpenAi) {
    $OpenAiKey = $systemOpenAi
    Write-Host "  Found OPENAI_API_KEY in system environment"
}

$existingSalt = Read-EnvValue $envFile "ERA_SERVER_SALT"
$salt = if ($existingSalt -and -not $ForceSalt) {
    $existingSalt
} else {
    New-RandomSalt
}

$demoMode = "true"
$openAiValue = "sk-your-openai-api-key-here"
if ($OpenAiKey -and $OpenAiKey -notmatch "^(sk-your-|sk-ci-test)") {
    $openAiValue = $OpenAiKey
    $demoMode = "false"
    Write-Host "  Using real OpenAI key - demo mode OFF"
} else {
    Write-Host "  No real OpenAI key - demo mode ON (built-in riddles)"
}

$envContent = @"
# ERA — auto-configured by setup-keys.ps1 ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))
# Local: GO.bat | Production: DEPLOY.bat

ERA_STANDALONE=true
ERA_DEMO_MODE=$demoMode

OPENAI_API_KEY=$openAiValue
OPENAI_MODEL=gpt-4o-mini
ERA_SERVER_SALT=$salt

# Not used in standalone (SQLite + in-process Celery):
# DATABASE_URL / REDIS_URL / CELERY_* — only for Docker or PaaS

# Production (Render): set via paas-prep.ps1
# CORS_ORIGINS=https://your-app.vercel.app
"@

Set-Content -Path $envFile -Value $envContent -Encoding UTF8
Write-Host "  Wrote $envFile"

$frontendContent = @"
# Dev: empty = Vite proxy to API
# Production: VITE_API_URL=https://your-api.onrender.com
VITE_API_URL=
"@

Set-Content -Path $frontendEnv -Value $frontendContent -Encoding UTF8
Write-Host "  Wrote $frontendEnv"

Write-Host ""
Write-Host "[ERA] Keys configured for standalone local product."
Write-Host ""
Write-Host "Required for LOCAL (done):"
Write-Host "  ERA_STANDALONE=true"
Write-Host "  ERA_DEMO_MODE=$demoMode"
Write-Host "  ERA_SERVER_SALT=(set)"
Write-Host "  OPENAI_API_KEY=$(if ($demoMode -eq 'true') { 'placeholder OK' } else { 'real key' })"
Write-Host ""
Write-Host "Required for PRODUCTION (PaaS) - run DEPLOY.bat:"
Write-Host "  DATABASE_URL       - Neon Postgres"
Write-Host "  REDIS_URL          - Upstash rediss://"
Write-Host "  OPENAI_API_KEY     - platform.openai.com"
Write-Host "  ERA_SERVER_SALT    - same on api + worker"
Write-Host "  CORS_ORIGINS       - Vercel URL"
Write-Host "  VITE_API_URL       - Render API URL on Vercel"
Write-Host ""
