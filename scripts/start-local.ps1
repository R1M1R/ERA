$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

$env:PYTHONPATH = $Root.Path
Set-Location $Root.Path

Write-Host "[ERA] Starting infrastructure (PostgreSQL + Redis)..."
docker compose --env-file (Join-Path $Root.Path ".env") up -d postgres redis
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "[ERA] Run these in separate terminals:"
Write-Host ""
Write-Host "  API:"
Write-Host "    cd backend"
Write-Host "    `$env:PYTHONPATH=`"$($Root.Path)`""
Write-Host "    .\venv\Scripts\uvicorn main:app --reload --host 127.0.0.1 --port 8000"
Write-Host ""
Write-Host "  Celery worker:"
Write-Host "    `$env:PYTHONPATH=`"$($Root.Path)`""
Write-Host "    backend\venv\Scripts\celery -A worker.celery_app worker --loglevel=info"
Write-Host ""
Write-Host "  Frontend:"
Write-Host "    cd frontend"
Write-Host "    npm run dev"
Write-Host ""
Write-Host "[ERA] Health check: http://127.0.0.1:8000/health"
