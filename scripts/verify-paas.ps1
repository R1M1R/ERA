param(
    [Parameter(Mandatory = $true)]
    [string]$ApiUrl,

    [switch]$TestGenerate
)

$ErrorActionPreference = "Continue"
$ok = $true

$ApiUrl = $ApiUrl.TrimEnd("/")

function Test-Get([string]$Label, [string]$Path) {
    Write-Host -NoNewline "  $Label ... "
    try {
        $response = Invoke-RestMethod -Uri "$ApiUrl$Path" -TimeoutSec 90
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

Write-Host "[ERA/PaaS] Verifying: $ApiUrl"
Write-Host "(Render free tier may take 30-60s on cold start)"
Write-Host ""

$ok = (Test-Get "GET /health" "/health") -and $ok
$ok = (Test-Get "GET /artifacts" "/artifacts?page=1&page_size=1") -and $ok

if ($TestGenerate) {
    Write-Host -NoNewline "  POST /generate ... "
    try {
        $gen = Invoke-RestMethod -Uri "$ApiUrl/generate" -Method POST -TimeoutSec 90
        Write-Host "OK (task_id=$($gen.task_id))"
        Write-Host "    Poll: $ApiUrl/status/$($gen.task_id)"
    } catch {
        Write-Host "FAIL"
        Write-Host "    $($_.Exception.Message)"
        $ok = $false
    }
}

Write-Host ""
if ($ok) {
    Write-Host "[ERA/PaaS] API looks healthy."
    Write-Host "  Frontend env: VITE_API_URL=$ApiUrl"
} else {
    Write-Host "[ERA/PaaS] Some checks failed."
    Write-Host "  - Is Render service running?"
    Write-Host "  - Check era-celery worker logs if /generate fails"
    exit 1
}
