param(
    [switch]$SkipVerify
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

function Stop-PortListener {
    param([int]$Port)
    $lines = netstat -ano | findstr "LISTENING" | findstr ":$Port "
    foreach ($line in $lines) {
        $procId = ($line -split '\s+')[-1]
        if ($procId -match '^\d+$') {
            Write-Host "[ERA] Stopping process $procId on port $Port"
            Stop-Process -Id ([int]$procId) -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "[ERA] Restarting ERA stack (fresh code)..."
Stop-PortListener -Port 8000
Stop-PortListener -Port 5173
Start-Sleep -Seconds 2

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "start-standalone.ps1")

if (-not $SkipVerify) {
    Write-Host ""
    Write-Host "[ERA] Running product verification..."
    Start-Sleep -Seconds 8
    & (Join-Path $PSScriptRoot "verify-product.ps1")
}
