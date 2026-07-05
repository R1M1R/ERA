param(
    [switch]$Remove
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$StartupFolder = [Environment]::GetFolderPath("Startup")
$ShortcutPath = Join-Path $StartupFolder "ERA Autonomous.lnk"
$Target = Join-Path $Root "AUTONOMOUS.bat"

$WshShell = New-Object -ComObject WScript.Shell

if ($Remove) {
    if (Test-Path $ShortcutPath) {
        Remove-Item $ShortcutPath -Force
        Write-Host "[ERA] Removed startup shortcut: $ShortcutPath"
    } else {
        Write-Host "[ERA] No startup shortcut found."
    }
    exit 0
}

$shortcut = $WshShell.CreateShortcut($ShortcutPath)
$shortcut.TargetPath = $Target
$shortcut.WorkingDirectory = $Root.Path
$shortcut.WindowStyle = 7
$shortcut.Description = "ERA autonomous start with watchdog"
$shortcut.Save()

Write-Host "[ERA] Startup shortcut created (no admin required):"
Write-Host "  $ShortcutPath"
Write-Host "  ERA will start when you log in to Windows."
