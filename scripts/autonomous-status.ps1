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

$watchdog = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like "*watchdog.ps1*" }
Write-Host "Watchdog: $(if ($watchdog) { 'RUNNING (pid ' + $watchdog.ProcessId + ')' } else { 'NOT RUNNING' })"

$task = Get-ScheduledTask -TaskName "ERA-AutoStart" -ErrorAction SilentlyContinue
Write-Host "Auto-start: $(if ($task -and $task.State -ne 'Disabled') { $task.State } else { 'NOT INSTALLED' })"

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
