param(
    [string]$BaseUrl = "https://frontend-flax-two-11q4abvz2o.vercel.app"
)

$ErrorActionPreference = "Stop"
$BaseUrl = $BaseUrl.TrimEnd("/")

Write-Host ""
Write-Host "========================================"
Write-Host "  ERA - Vercel production verification"
Write-Host "========================================"
Write-Host ""
Write-Host "  URL: $BaseUrl"
Write-Host ""

$ok = $true
$health = $null

function Test-Endpoint {
    param(
        [string]$Label,
        [string]$Path,
        [string]$Method = "GET",
        [scriptblock]$Assert
    )
    Write-Host -NoNewline "  $Label ... "
    try {
        $uri = "$BaseUrl$Path"
        $response = Invoke-WebRequest -Uri $uri -Method $Method -TimeoutSec 30 -UseBasicParsing
        if ($response.StatusCode -ge 400) {
            Write-Host "FAIL ($($response.StatusCode))"
            return $false
        }
        $payload = $null
        if ($response.Content) {
            try { $payload = $response.Content | ConvertFrom-Json } catch { $payload = $response.Content }
        }
        if ($Assert) {
            & $Assert $payload $response
        }
        Write-Host "OK"
        return $true
    } catch {
        Write-Host "FAIL"
        Write-Host "    $($_.Exception.Message)"
        return $false
    }
}

$ok = (Test-Endpoint "GET /health" "/health" -Assert {
        param($payload)
        $script:health = $payload
        if ($payload.status -ne "ok") { throw "status=$($payload.status)" }
    }) -and $ok

if ($health) {
    Write-Host ""
    Write-Host "  Health flags:"
    foreach ($flag in @(
            @{ Name = "database_persistent"; Hint = "Run scripts/setup-neon-vercel.ps1" },
            @{ Name = "billing_configured"; Hint = "Run scripts/setup-lemonsqueezy-webhook.ps1" },
            @{ Name = "openai_for_pro"; Hint = "npx vercel env add OPENAI_API_KEY production" }
        )) {
        $value = $health.($flag.Name)
        $icon = if ($value) { "[OK]" } else { "[--]" }
        Write-Host "    $icon $($flag.Name) = $value"
        if (-not $value) {
            Write-Host "        -> $($flag.Hint)"
        }
    }
}

$ok = (Test-Endpoint "GET /pro/status" "/pro/status" -Assert {
        param($payload)
        if ($payload.tier -ne "free") { throw "unexpected tier=$($payload.tier)" }
    }) -and $ok

$ok = (Test-Endpoint "GET /openapi.json" "/openapi.json" -Assert {
        param($payload)
        foreach ($route in @("/health", "/generate", "/pro/status", "/webhooks/lemonsqueezy")) {
            if (-not $payload.paths.PSObject.Properties.Name.Contains($route)) {
                throw "missing route $route"
            }
        }
    }) -and $ok

Write-Host -NoNewline "  POST /generate + pipeline ... "
try {
    $gen = Invoke-RestMethod -Uri "$BaseUrl/generate" -Method POST -TimeoutSec 30
    $taskId = $gen.task_id
    if (-not $taskId) { throw "missing task_id" }
    $deadline = (Get-Date).AddSeconds(90)
    $completed = $false
    while ((Get-Date) -lt $deadline) {
        $status = Invoke-RestMethod -Uri "$BaseUrl/status/$taskId" -TimeoutSec 15
        if ($status.status -eq "completed") {
            $result = $status.result
            if ($result.authenticity_hash) { throw "authenticity_hash leaked in /status" }
            if ($result.image_path) { throw "image_path leaked in /status" }
            $completed = $true
            break
        }
        if ($status.status -eq "failed") { throw "pipeline failed: $($status.error)" }
        Start-Sleep -Seconds 2
    }
    if (-not $completed) { throw "pipeline timed out" }
    Write-Host "OK (task=$taskId)"
} catch {
    Write-Host "FAIL"
    Write-Host "    $($_.Exception.Message)"
    $ok = $false
}

Write-Host ""
if ($ok) {
    $ready = $health.database_persistent -and $health.billing_configured -and $health.openai_for_pro
    if ($ready) {
        Write-Host "[ERA] Production fully configured and operational."
    } else {
        Write-Host "[ERA] App is live. Complete owner setup for passive Pro income:"
        Write-Host "      .\SETUP-PRODUCTION.bat"
    }
    exit 0
}

Write-Host "[ERA] Production verification failed."
exit 1
