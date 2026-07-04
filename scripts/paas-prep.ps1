param(
    [string]$ApiUrl = "",
    [string]$FrontendUrl = "",
    [string]$NeonDatabaseUrl = "",
    [string]$UpstashRedisUrl = "",
    [string]$OpenAiKey = "",
    [string]$OutputFile = "",
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

if (-not $OutputFile) {
    $OutputFile = Join-Path $Root "paas-env-checklist.txt"
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

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

$secrets = Read-SecretsFile (Join-Path $Root ".secrets.local")
if ($secrets["DATABASE_URL"] -and -not $NeonDatabaseUrl) { $NeonDatabaseUrl = $secrets["DATABASE_URL"] }
if ($secrets["REDIS_URL"] -and -not $UpstashRedisUrl) { $UpstashRedisUrl = $secrets["REDIS_URL"] }
if ($secrets["CELERY_BROKER_URL"] -and -not $UpstashRedisUrl) { $UpstashRedisUrl = $secrets["CELERY_BROKER_URL"] }
if ($secrets["OPENAI_API_KEY"] -and -not $OpenAiKey) { $OpenAiKey = $secrets["OPENAI_API_KEY"] }
if ($secrets["VITE_API_URL"] -and -not $ApiUrl) { $ApiUrl = $secrets["VITE_API_URL"] }
if ($secrets["CORS_ORIGINS"] -and -not $FrontendUrl) { $FrontendUrl = $secrets["CORS_ORIGINS"] }

function Read-OrPrompt([string]$Label, [string]$Current) {
    if ($Current) { return $Current }
    if ($NonInteractive) { return "" }
    return Read-Host $Label
}

Write-Host "[ERA/PaaS] Deployment preparation"
Write-Host ""

$NeonDatabaseUrl = Read-OrPrompt "Neon DATABASE_URL (postgresql://...)" $NeonDatabaseUrl
$UpstashRedisUrl = Read-OrPrompt "Upstash Redis URL (rediss://...)" $UpstashRedisUrl
$OpenAiKey = Read-OrPrompt "OpenAI API key (sk-...)" $OpenAiKey
$ApiUrl = Read-OrPrompt "Render API URL (https://era-api.onrender.com)" $ApiUrl
$FrontendUrl = Read-OrPrompt "Vercel frontend URL (https://xxx.vercel.app)" $FrontendUrl

$demoMode = "false"
if (-not $OpenAiKey -or $OpenAiKey -match "^(sk-your-|sk-ci-test)") {
    $demoMode = "true"
    if (-not $OpenAiKey) { $OpenAiKey = "sk-your-openai-api-key-here" }
}

$eraSalt = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 48 | ForEach-Object { [char]$_ })

$content = @"
ERA PaaS Environment — paste into Render dashboard
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm")
NEVER commit this file to git.

=== era-api (Web Service) ===
DATABASE_URL=$NeonDatabaseUrl
DATABASE_URL_SYNC=$NeonDatabaseUrl
REDIS_URL=$UpstashRedisUrl
CELERY_BROKER_URL=$UpstashRedisUrl
CELERY_RESULT_BACKEND=$UpstashRedisUrl
OPENAI_API_KEY=$OpenAiKey
OPENAI_MODEL=gpt-4o-mini
ERA_DEMO_MODE=$demoMode
ERA_SERVER_SALT=$eraSalt
CORS_ORIGINS=$FrontendUrl
GUNICORN_WORKERS=1
PYTHONPATH=/app

=== era-celery (Worker) — same except CORS not required ===
DATABASE_URL=$NeonDatabaseUrl
DATABASE_URL_SYNC=$NeonDatabaseUrl
REDIS_URL=$UpstashRedisUrl
CELERY_BROKER_URL=$UpstashRedisUrl
CELERY_RESULT_BACKEND=$UpstashRedisUrl
OPENAI_API_KEY=$OpenAiKey
OPENAI_MODEL=gpt-4o-mini
ERA_DEMO_MODE=$demoMode
ERA_SERVER_SALT=$eraSalt
PYTHONPATH=/app

=== Vercel (frontend) ===
VITE_API_URL=$ApiUrl

=== Deploy order ===
1. Render Blueprint: https://dashboard.render.com/blueprints
2. Repo: https://github.com/R1M1R/ERA
3. Paste env vars above into era-api and era-celery
4. Vercel: import repo, root=frontend, set VITE_API_URL
5. Update CORS_ORIGINS on Render with Vercel URL, redeploy API
6. Verify: .\scripts\verify-paas.ps1 -ApiUrl $ApiUrl

Checklist: deploy/paas/CHECKLIST.md
"@

Write-Utf8NoBom $OutputFile $content

Write-Host ""
Write-Host "[ERA/PaaS] Saved: $OutputFile"
if (-not $NeonDatabaseUrl -or -not $UpstashRedisUrl) {
    Write-Host "[ERA/PaaS] Missing Neon or Upstash URLs - add them to .secrets.local and re-run."
}
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. https://dashboard.render.com/blueprints -> New Blueprint -> R1M1R/ERA"
Write-Host "  2. Paste env vars from $OutputFile"
Write-Host "  3. https://vercel.com/new -> frontend/ + VITE_API_URL=$ApiUrl"
Write-Host "  4. .\scripts\verify-paas.ps1 -ApiUrl $ApiUrl"
