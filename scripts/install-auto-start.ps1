param(
    [switch]$Remove
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$TaskName = "ERA-AutoStart"

if ($Remove) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "[ERA] Removed scheduled task: $TaskName"
    exit 0
}

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($Root.Path)\scripts\start-autonomous.ps1`" -WithWatchdog"
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
try {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description "Auto-start ERA product on login" -Force | Out-Null
    Write-Host "[ERA] Scheduled task '$TaskName' installed."
    Write-Host "  ERA will start silently on login (no browser popup)."
} catch {
    Write-Host "[ERA] Could not install scheduled task (run PowerShell as Administrator):"
    Write-Host "  $_"
    Write-Host ""
    Write-Host "  Alternative: .\scripts\install-startup-shortcut.ps1 (no admin)"
    exit 1
}
Write-Host "  Logs: logs\era-autonomous.log, logs\era-watchdog.log"
Write-Host "  Remove: .\scripts\install-auto-start.ps1 -Remove"
