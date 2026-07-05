param(
    [switch]$WithWatchdog,
    [switch]$SkipKeys
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$LogDir = Join-Path $Root "logs"
$LogFile = Join-Path $LogDir "era-autonomous.log"

function Write-Log([string]$Message) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
    }
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
    Write-Host $line
}

Write-Log "ERA autonomous startup"

if (-not $SkipKeys) {
    & (Join-Path $PSScriptRoot "setup-keys.ps1") 2>&1 | ForEach-Object { Write-Log $_ }
}

$env:ERA_AUTONOMOUS = "true"
& (Join-Path $PSScriptRoot "start-standalone.ps1") -Silent 2>&1 | ForEach-Object { Write-Log $_ }

Start-Sleep -Seconds 6

function Test-StackHealthy {
    try {
        $api = Invoke-RestMethod "http://127.0.0.1:8000/health" -TimeoutSec 5
        $fe = Invoke-RestMethod "http://localhost:5173/health" -TimeoutSec 5
        return ($api.status -eq "ok") -and ($fe.status -eq "ok")
    } catch {
        return $false
    }
}

if (Test-StackHealthy) {
    Write-Log "Stack healthy: API + Frontend OK"
} else {
    Write-Log "Stack not healthy, restarting..."
    & (Join-Path $PSScriptRoot "restart-era.ps1") -SkipVerify 2>&1 | ForEach-Object { Write-Log $_ }
    Start-Sleep -Seconds 8
    if (Test-StackHealthy) {
        Write-Log "Stack recovered after restart"
    } else {
        Write-Log "WARNING: Stack still unhealthy"
        exit 1
    }
}

if ($WithWatchdog) {
    $watchdogScript = Join-Path $PSScriptRoot "watchdog.ps1"
    $already = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*watchdog.ps1*" }
    if (-not $already) {
        Start-Process powershell -ArgumentList @(
            "-NoProfile", "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-File", $watchdogScript
        ) -WorkingDirectory $Root.Path | Out-Null
        Write-Log "Watchdog started in background"
    } else {
        Write-Log "Watchdog already running"
    }
}

Write-Log "Autonomous startup complete"
