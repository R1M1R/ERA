param(
    [int]$IntervalSec = 60
)

$ErrorActionPreference = "Continue"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$LogFile = Join-Path $Root "logs\era-watchdog.log"
$PidFile = Join-Path $Root "logs\watchdog.pid"

function Write-Log([string]$Message) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    $logDir = Split-Path $LogFile -Parent
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
}

try {
    Set-Content -Path $PidFile -Value $PID -Encoding ASCII -NoNewline
} catch {
    Write-Log "Could not write PID file: $_"
}

function Test-Healthy {
    try {
        $api = Invoke-RestMethod "http://127.0.0.1:8000/health" -TimeoutSec 5
        $fe = Invoke-RestMethod "http://localhost:5173/health" -TimeoutSec 5
        return ($api.status -eq "ok") -and ($fe.status -eq "ok")
    } catch {
        return $false
    }
}

Write-Log "Watchdog started pid=$PID (interval ${IntervalSec}s)"

$tick = 0
while ($true) {
    Start-Sleep -Seconds $IntervalSec
    $tick++
    if ($tick % 10 -eq 0) {
        Write-Log "Heartbeat: watchdog alive"
    }
    if (Test-Healthy) {
        continue
    }
    Write-Log "Health check failed - restarting stack"
    try {
        $env:ERA_AUTONOMOUS = "true"
        & (Join-Path $PSScriptRoot "restart-era.ps1") -SkipVerify
        Start-Sleep -Seconds 10
        if (Test-Healthy) {
            Write-Log "Stack recovered"
        } else {
            Write-Log "Restart did not restore health"
        }
    } catch {
        Write-Log "Restart error: $_"
    }
}
