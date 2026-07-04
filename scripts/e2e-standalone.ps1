param(
    [string]$ApiUrl = "http://127.0.0.1:8000"
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$venvPython = Join-Path $Root "backend\venv\Scripts\python.exe"

& $venvPython (Join-Path $Root "backend\scripts\e2e_standalone.py") --api-url $ApiUrl
