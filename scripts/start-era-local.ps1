param(
    [switch]$InfraOnly
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$env:PYTHONPATH = $Root.Path

function Test-Command($Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

Write-Host "[ERA] Local development launcher"
Write-Host ""

if (-not (Test-Path (Join-Path $Root ".env"))) {
    Write-Host "[ERA] No .env found. Copying from .env.example..."
    Copy-Item (Join-Path $Root ".env.example") (Join-Path $Root ".env")
    Write-Host "[ERA] Edit .env and set OPENAI_API_KEY before generating artifacts."
}

if (Test-Command "docker") {
    Write-Host "[ERA] Starting PostgreSQL + Redis..."
    Push-Location $Root
    docker compose --env-file .env up -d postgres redis
    Pop-Location
} else {
    Write-Host "[ERA] Docker not found. Install Docker Desktop or start postgres/redis manually."
}

if ($InfraOnly) {
    Write-Host "[ERA] Infra only. Exiting."
    exit 0
}

Write-Host ""
Write-Host "Open 3 new terminals and run:"
Write-Host ""
Write-Host "  Terminal 1 — API:"
Write-Host "    cd `"$($Root.Path)\backend`""
Write-Host "    `$env:PYTHONPATH=`"$($Root.Path)`""
Write-Host "    .\venv\Scripts\uvicorn main:app --reload --host 127.0.0.1 --port 8000"
Write-Host ""
Write-Host "  Terminal 2 — Celery:"
Write-Host "    `$env:PYTHONPATH=`"$($Root.Path)`""
Write-Host "    $($Root.Path)\backend\venv\Scripts\celery -A worker.celery_app worker --loglevel=info"
Write-Host ""
Write-Host "  Terminal 3 — Frontend:"
Write-Host "    cd `"$($Root.Path)\frontend`""
Write-Host "    npm run dev"
Write-Host ""
Write-Host "[ERA] App: http://localhost:5173"
Write-Host "[ERA] API: http://127.0.0.1:8000/health"
