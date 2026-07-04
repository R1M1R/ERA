param(
    [Parameter(Mandatory = $true)]
    [string]$ApiUrl,

    [switch]$FullE2E
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$ApiUrl = $ApiUrl.TrimEnd("/")
$venvPython = Join-Path $Root "backend\venv\Scripts\python.exe"

Write-Host "[ERA/PaaS] Verifying: $ApiUrl"
Write-Host "(Render free tier: first request may take 30-90s cold start)"
Write-Host ""

if ($FullE2E) {
    & $venvPython (Join-Path $Root "backend\scripts\e2e_standalone.py") --api-url $ApiUrl --production
    exit $LASTEXITCODE
}

$ok = $true

function Test-Get([string]$Label, [string]$Path) {
    Write-Host -NoNewline "  $Label ... "
    try {
        $response = Invoke-RestMethod -Uri "$ApiUrl$Path" -TimeoutSec 120
        Write-Host "OK"
        if ($response) {
            Write-Host "    $($response | ConvertTo-Json -Compress -Depth 3)"
        }
        return $true
    } catch {
        Write-Host "FAIL"
        Write-Host "    $($_.Exception.Message)"
        return $false
    }
}

$ok = (Test-Get "GET /health" "/health") -and $ok
$ok = (Test-Get "GET /artifacts" "/artifacts?page=1&page_size=1") -and $ok

Write-Host ""
if ($ok) {
    Write-Host "[ERA/PaaS] API looks healthy."
    Write-Host "  Frontend env: VITE_API_URL=$ApiUrl"
    Write-Host "  Full test:    .\scripts\verify-paas.ps1 -ApiUrl $ApiUrl -FullE2E"
} else {
    Write-Host "[ERA/PaaS] Some checks failed."
    Write-Host "  - Is Render service running?"
    Write-Host "  - Check era-celery worker logs if /generate fails"
    exit 1
}
