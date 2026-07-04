param(
    [switch]$InfraOnly,
    [switch]$All
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$env:PYTHONPATH = $Root.Path

function Test-Command($Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Start-DevWindow {
    param([string]$Title, [string]$Command)
    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "`$host.UI.RawUI.WindowTitle = '$Title'; $Command"
    ) | Out-Null
}

Write-Host "[ERA] Local development launcher"
Write-Host ""

if (-not (Test-Path (Join-Path $Root ".env"))) {
    Write-Host "[ERA] No .env found."
    $localExample = Join-Path $Root ".env.local.example"
    if (Test-Path $localExample) {
        Copy-Item $localExample (Join-Path $Root ".env")
        Write-Host "[ERA] Created .env from .env.local.example (localhost defaults)."
    } else {
        Copy-Item (Join-Path $Root ".env.example") (Join-Path $Root ".env")
        Write-Host "[ERA] Created .env from .env.example. Set OPENAI_API_KEY before generating."
    }
    Write-Host "[ERA] Edit .env and set OPENAI_API_KEY for artifact generation."
}

if (Test-Command "docker") {
    & (Join-Path $PSScriptRoot "ensure-docker.ps1") | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERA] Start Docker Desktop manually, then re-run this script."
        if (-not $InfraOnly) {
            Write-Host "[ERA] You can still start API/Frontend, but generation requires Docker infra."
        }
    }

    Write-Host "[ERA] Starting PostgreSQL + Redis + Celery..."
    Push-Location $Root
    $composeResult = docker compose --env-file .env up -d postgres redis celery-worker 2>&1
    Pop-Location

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERA] Docker compose failed. Is Docker Desktop running?"
        Write-Host $composeResult
    } else {
        Write-Host "[ERA] Waiting for infra..."
        $ready = $false
        for ($i = 0; $i -lt 20; $i++) {
            try {
                $pg = docker inspect -f "{{.State.Health.Status}}" era-postgres 2>$null
                $rd = docker inspect -f "{{.State.Health.Status}}" era-redis 2>$null
            } catch {
                $pg = $null
                $rd = $null
            }
            if ($pg -eq "healthy" -and $rd -eq "healthy") {
                $ready = $true
                break
            }
            Start-Sleep -Seconds 1
        }
        if ($ready) {
            Write-Host "[ERA] Infra is healthy."
            try {
                & (Join-Path $PSScriptRoot "init-local-db.ps1")
            } catch {
                Write-Host "[ERA] DB init skipped or failed: $($_.Exception.Message)"
            }
        } else {
            Write-Host "[ERA] Infra still starting - check: docker compose ps"
        }
    }
} else {
    Write-Host "[ERA] Docker not found. Install Docker Desktop."
}

if ($InfraOnly) {
    exit 0
}

if ($All) {
    $venvPython = Join-Path $Root "backend\venv\Scripts\python.exe"
    if (-not (Test-Path $venvPython)) {
        Write-Host "[ERA] Creating Python venv..."
        Push-Location (Join-Path $Root "backend")
        python -m venv venv
        .\venv\Scripts\pip install -r requirements.txt
        Pop-Location
    }

    $apiCmd = "cd '$($Root.Path)\backend'; `$env:PYTHONPATH='$($Root.Path)'; .\venv\Scripts\uvicorn main:app --reload --host 127.0.0.1 --port 8000"
    $feCmd = "cd '$($Root.Path)\frontend'; npm run dev"

    Write-Host "[ERA] Opening API and Frontend windows..."
    Start-DevWindow -Title "ERA API" -Command $apiCmd
    Start-Sleep -Seconds 2
    Start-DevWindow -Title "ERA Frontend" -Command $feCmd

    Write-Host ""
    Write-Host "[ERA] Started:"
    Write-Host "  Infra:    Docker postgres + redis + celery-worker"
    Write-Host "  API:      http://127.0.0.1:8000/health"
    Write-Host "  Frontend: http://localhost:5173"
    Write-Host ""
    Write-Host "Run smoke test in ~10 seconds:"
    Write-Host "  .\scripts\smoke-test.ps1"
    exit 0
}

Write-Host ""
Write-Host "Quick start (opens API + Frontend automatically):"
Write-Host "  .\scripts\start-era-local.ps1 -All"
Write-Host ""
Write-Host "Manual terminals:"
Write-Host ""
Write-Host "  API:"
Write-Host "    cd `"$($Root.Path)\backend`""
Write-Host "    `$env:PYTHONPATH=`"$($Root.Path)`""
Write-Host "    .\venv\Scripts\uvicorn main:app --reload --host 127.0.0.1 --port 8000"
Write-Host ""
Write-Host "  Frontend:"
Write-Host "    cd `"$($Root.Path)\frontend`""
Write-Host "    npm run dev"
Write-Host ""
Write-Host "[ERA] Celery runs in Docker. App: http://localhost:5173"
