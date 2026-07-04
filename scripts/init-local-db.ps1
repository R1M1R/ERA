$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$env:PYTHONPATH = $Root.Path

$python = Join-Path $Root "backend\venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
    throw "Python venv not found. Run: cd backend; python -m venv venv; .\venv\Scripts\pip install -r requirements.txt"
}

Write-Host "[ERA] Initializing database schema..."
& $python (Join-Path $Root "backend\scripts\init_db.py")
Write-Host "[ERA] Database ready."
