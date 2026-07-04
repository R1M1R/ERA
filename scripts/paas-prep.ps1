param(
    [string]$ApiUrl = "",
    [string]$FrontendUrl = "",
    [string]$NeonDatabaseUrl = "",
    [string]$UpstashRedisUrl = "",
    [string]$OpenAiKey = "",
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

if (-not $OutputFile) {
    $OutputFile = Join-Path $Root "paas-env-checklist.txt"
}

function Read-OrPrompt([string]$Label, [string]$Current) {
    if ($Current) { return $Current }
    return Read-Host $Label
}

Write-Host "[ERA/PaaS] Deployment preparation"
Write-Host ""

$NeonDatabaseUrl = Read-OrPrompt "Neon DATABASE_URL (postgresql://...)" $NeonDatabaseUrl
$UpstashRedisUrl = Read-OrPrompt "Upstash Redis URL (rediss://...)" $UpstashRedisUrl
$OpenAiKey = Read-OrPrompt "OpenAI API key (sk-...)" $OpenAiKey
$ApiUrl = Read-OrPrompt "Render API URL (https://era-api.onrender.com)" $ApiUrl
$FrontendUrl = Read-OrPrompt "Vercel frontend URL (https://xxx.vercel.app)" $FrontendUrl

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

Set-Content -Path $OutputFile -Value $content -Encoding UTF8

Write-Host ""
Write-Host "[ERA/PaaS] Saved: $OutputFile"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. https://dashboard.render.com/blueprints -> New Blueprint -> R1M1R/ERA"
Write-Host "  2. Paste env vars from $OutputFile"
Write-Host "  3. https://vercel.com/new -> frontend/ + VITE_API_URL=$ApiUrl"
Write-Host "  4. .\scripts\verify-paas.ps1 -ApiUrl $ApiUrl"
