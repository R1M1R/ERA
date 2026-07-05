$ErrorActionPreference = "Continue"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

Write-Host ""
Write-Host "ERA Autonomous Status"
Write-Host "====================="
Write-Host ""

function Test-Endpoint([string]$Url) {
    try {
        $r = Invoke-RestMethod $Url -TimeoutSec 5
        return @{ ok = $true; data = $r }
    } catch {
        return @{ ok = $false; data = $null }
    }
}

$api = Test-Endpoint "http://127.0.0.1:8000/health"
$fe = Test-Endpoint "http://localhost:5173/health"

Write-Host "API:      $(if ($api.ok) { 'OK - ' + $api.data.status } else { 'DOWN' })"
Write-Host "Frontend: $(if ($fe.ok) { 'OK - ' + $fe.data.status } else { 'DOWN' })"

$pidFile = Join-Path $Root "logs\watchdog.pid"
$watchdogRunning = $false
$watchdogPid = ""

if (Test-Path $pidFile) {
    $watchdogPid = (Get-Content $pidFile -ErrorAction SilentlyContinue).Trim()
    if ($watchdogPid -match '^\d+$') {
        $proc = Get-Process -Id ([int]$watchdogPid) -ErrorAction SilentlyContinue
        $watchdogRunning = $null -ne $proc
    }
}

if (-not $watchdogRunning) {
    $watchdog = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*watchdog.ps1*" }
    if ($watchdog) {
        $watchdogRunning = $true
        $watchdogPid = $watchdog.ProcessId
    }
}

Write-Host "Watchdog: $(if ($watchdogRunning) { "RUNNING (pid $watchdogPid)" } else { 'NOT RUNNING' })"

$task = Get-ScheduledTask -TaskName "ERA-AutoStart" -ErrorAction SilentlyContinue
$startupShortcut = Join-Path ([Environment]::GetFolderPath("Startup")) "ERA Autonomous.lnk"
$autoStartLabel = if ($task -and $task.State -ne 'Disabled') {
    "ScheduledTask: $($task.State)"
} elseif (Test-Path $startupShortcut) {
    "Startup shortcut: OK"
} else {
    "NOT CONFIGURED"
}
Write-Host "Auto-start: $autoStartLabel"

$autoLog = Join-Path $Root "logs\era-autonomous.log"
$watchLog = Join-Path $Root "logs\era-watchdog.log"
if (Test-Path $autoLog) {
    Write-Host ""
    Write-Host "Last autonomous log:"
    Get-Content $autoLog -Tail 3 | ForEach-Object { Write-Host "  $_" }
}
if (Test-Path $watchLog) {
    Write-Host ""
    Write-Host "Last watchdog log:"
    Get-Content $watchLog -Tail 3 | ForEach-Object { Write-Host "  $_" }
}

Write-Host ""
if ($api.ok -and $fe.ok) {
    Write-Host "Product is operational: http://localhost:5173"
} else {
    Write-Host "Fix: AUTONOMOUS.bat or .\scripts\start-autonomous.ps1 -WithWatchdog"
}
Write-Host ""
