param(
    [string]$ApiUrl = "http://127.0.0.1:8000",
    [string]$FrontendUrl = "http://localhost:5173",
    [switch]$SkipFrontend
)

$ErrorActionPreference = "Continue"
$ok = $true

function Test-Endpoint {
    param([string]$Label, [string]$Url, [int]$TimeoutSec = 10)
    Write-Host -NoNewline "  $Label ... "
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec $TimeoutSec -UseBasicParsing
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
            Write-Host "OK ($($response.StatusCode))"
            return $true
        }
        Write-Host "FAIL ($($response.StatusCode))"
        return $false
    } catch {
        Write-Host "FAIL"
        Write-Host "    $($_.Exception.Message)"
        return $false
    }
}

Write-Host "[ERA] Smoke test"
Write-Host "  API:      $ApiUrl"
if (-not $SkipFrontend) {
    Write-Host "  Frontend: $FrontendUrl"
}
Write-Host ""

if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "Docker containers:"
    docker ps --filter "name=era-" --format "  {{.Names}}: {{.Status}}" 2>$null
    Write-Host ""
}

$ok = (Test-Endpoint "API /health" "$ApiUrl/health") -and $ok
$ok = (Test-Endpoint "API /artifacts" "$ApiUrl/artifacts?page=1&page_size=1") -and $ok

if (-not $SkipFrontend) {
    $ok = (Test-Endpoint "Frontend dev server" $FrontendUrl) -and $ok
}

Write-Host ""
if ($ok) {
    Write-Host "[ERA] All smoke checks passed."
    exit 0
}

Write-Host "[ERA] Some checks failed."
Write-Host "  Start local stack: .\scripts\start-era-local.ps1 -All"
exit 1
