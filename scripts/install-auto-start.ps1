param(
    [switch]$Remove
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$TaskName = "ERA-AutoStart"
$GoBat = Join-Path $Root "GO.bat"

if ($Remove) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "[ERA] Removed scheduled task: $TaskName"
    exit 0
}

$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$GoBat`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description "Auto-start ERA product on login" -Force | Out-Null

Write-Host "[ERA] Scheduled task '$TaskName' installed."
Write-Host "  ERA will start automatically when you log in to Windows."
Write-Host "  Remove: .\scripts\install-auto-start.ps1 -Remove"
