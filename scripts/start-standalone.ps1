param(
    [switch]$SkipFrontend,
    [switch]$RunE2E,
    [switch]$Silent
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$env:PYTHONPATH = $Root.Path

$standaloneExample = Join-Path $Root ".env.standalone.example"
$envFile = Join-Path $Root ".env"

if (-not (Test-Path $envFile)) {
    Copy-Item $standaloneExample $envFile
    Write-Host "[ERA] Created .env from .env.standalone.example"
} elseif (-not (Select-String -Path $envFile -Pattern '^\s*ERA_STANDALONE\s*=' -Quiet)) {
    Add-Content -Path $envFile -Value "`nERA_STANDALONE=true"
    Write-Host "[ERA] Added ERA_STANDALONE=true to existing .env"
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Item -Path "env:$name" -Value $value
    }
}

$env:ERA_STANDALONE = "true"
$env:ERA_DEMO_MODE = "true"
$env:PYTHONPATH = $Root.Path

$venvPython = Join-Path $Root "backend\venv\Scripts\python.exe"
if (-not (Test-Path $venvPython)) {
    Write-Host "[ERA] Creating Python venv..."
    Push-Location (Join-Path $Root "backend")
    python -m venv venv
    .\venv\Scripts\pip install -r requirements.txt
    Pop-Location
}

Write-Host "[ERA] Standalone mode - no Docker required"
Write-Host "[ERA] Initializing SQLite database..."
& $venvPython (Join-Path $Root "backend\scripts\init_db.py")

function Start-DevWindow {
    param([string]$Title, [string]$Command)
    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "`$host.UI.RawUI.WindowTitle = '$Title'; $Command"
    ) | Out-Null
}

$apiCmd = @"
cd '$($Root.Path)\backend'
`$env:PYTHONPATH='$($Root.Path)'
`$env:ERA_STANDALONE='true'
`$env:ERA_DEMO_MODE='true'
Get-Content '$envFile' | ForEach-Object { if (`$_ -match '^\s*([^#][^=]+)=(.*)$') { Set-Item -Path `"env:`$(`$matches[1].Trim())`" -Value `$matches[2].Trim() } }
.\venv\Scripts\uvicorn main:app --reload --host 127.0.0.1 --port 8000
"@

function Test-ApiHealthy {
    param([string]$ApiUrl = "http://127.0.0.1:8000")
    try {
        $health = Invoke-RestMethod -Uri "$ApiUrl/health" -TimeoutSec 3
        return $health.status -eq "ok"
    } catch {
        return $false
    }
}

function Test-PortListening {
    param([int]$Port)
    return [bool](netstat -ano | findstr "LISTENING" | findstr ":$Port ")
}

$apiAlreadyRunning = Test-ApiHealthy
$frontendAlreadyRunning = Test-PortListening -Port 5173

if ($apiAlreadyRunning) {
    Write-Host "[ERA] API already running at http://127.0.0.1:8000"
} else {
    Write-Host "[ERA] Starting API..."
    Start-DevWindow -Title "ERA API (Standalone)" -Command $apiCmd
    Start-Sleep -Seconds 4
}

if (-not $SkipFrontend) {
    if ($frontendAlreadyRunning) {
        Write-Host "[ERA] Frontend already running at http://localhost:5173"
    } else {
        $feCmd = "cd '$($Root.Path)\frontend'; npm run dev"
        Start-DevWindow -Title "ERA Frontend" -Command $feCmd
    }
}

Write-Host ""
Write-Host "[ERA] Standalone stack running:"
Write-Host "  API:      http://127.0.0.1:8000/health"
Write-Host "  Frontend: http://localhost:5173"
Write-Host "  DB:       backend/era_standalone.db"
Write-Host ""
Write-Host "Generate works without OpenAI (demo mode) and without Docker."
Write-Host ""

$autonomous = $Silent -or ($env:ERA_AUTONOMOUS -eq "true")

if (-not $SkipFrontend -and -not $autonomous -and (Test-ApiHealthy) -and (Test-PortListening -Port 5173)) {
    Start-Process "http://localhost:5173" | Out-Null
    Write-Host "[ERA] Opened http://localhost:5173 in your browser."
    Write-Host ""
}

if ($RunE2E) {
    & (Join-Path $PSScriptRoot "e2e-standalone.ps1")
}
