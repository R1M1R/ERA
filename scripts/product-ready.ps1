param(
    [switch]$OpenBrowser
)

$ErrorActionPreference = "Continue"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

Write-Host ""
Write-Host "============================================"
Write-Host "  ERA - PRODUCT READY"
Write-Host "============================================"
Write-Host ""

& (Join-Path $PSScriptRoot "product-status.ps1")

$publicFile = Join-Path $Root "PUBLIC_URL.txt"
if (Test-Path $publicFile) {
    $publicUrl = (Get-Content $publicFile | Where-Object { $_ -match '^https://' } | Select-Object -First 1)
    if ($publicUrl) {
        Write-Host "Public URL (from PUBLIC_URL.txt):"
        Write-Host "  $publicUrl"
        try {
            $h = Invoke-RestMethod "$publicUrl/health" -TimeoutSec 15
            Write-Host "  status: $($h.status) $(if ($h.status -eq 'ok') { '(ONLINE)' } else { '(check SHARE.bat)' })"
        } catch {
            Write-Host "  status: OFFLINE - run SHARE.bat to start tunnel"
        }
        Write-Host ""
    }
}

Write-Host "Quick start:"
Write-Host "  Local:   GO.bat  or  http://localhost:5173"
Write-Host "  Public:  SHARE.bat"
Write-Host "  Deploy:  .\scripts\deploy-paas.ps1"
Write-Host ""

if ($OpenBrowser) {
    Start-Process "http://localhost:5173"
    if ($publicUrl -and $h.status -eq 'ok') {
        Start-Process $publicUrl
    }
}
