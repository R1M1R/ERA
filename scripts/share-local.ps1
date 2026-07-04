param(
    [switch]$SkipStart
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

function Test-PortListening {
    param([int]$Port)
    return [bool](netstat -ano | findstr "LISTENING" | findstr ":$Port ")
}

function Find-Cloudflared {
    $cmd = Get-Command cloudflared -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $wingetPath = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links\cloudflared.exe"
    if (Test-Path $wingetPath) { return $wingetPath }

    $programFiles = Join-Path ${env:ProgramFiles} "Cloudflare\cloudflared\cloudflared.exe"
    if (Test-Path $programFiles) { return $programFiles }

    $portable = Join-Path $Root "tools\cloudflared.exe"
    if (Test-Path $portable) { return $portable }

    return $null
}

function Install-PortableCloudflared {
    $toolsDir = Join-Path $Root "tools"
    $target = Join-Path $toolsDir "cloudflared.exe"
    if (Test-Path $target) { return $target }

    New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
    $url = "https://github.com/cloudflare/cloudflared/releases/download/2026.6.1/cloudflared-windows-amd64.exe"
    Write-Host "[ERA] Downloading portable cloudflared..."
    Invoke-WebRequest -Uri $url -OutFile $target -UseBasicParsing
    return $target
}

Write-Host ""
Write-Host "[ERA] Public demo tunnel (Cloudflare Quick Tunnel)"
Write-Host ""

if (-not $SkipStart) {
    if (-not (Test-PortListening -Port 8000) -or -not (Test-PortListening -Port 5173)) {
        Write-Host "[ERA] Starting local stack..."
        & (Join-Path $PSScriptRoot "start-standalone.ps1")
        Start-Sleep -Seconds 8
    } else {
        Write-Host "[ERA] Local stack already running."
    }
}

$cloudflared = Find-Cloudflared
if (-not $cloudflared) {
    Write-Host "[ERA] cloudflared not found. Downloading portable binary..."
    try {
        $cloudflared = Install-PortableCloudflared
    } catch {
        Write-Host "[ERA] Portable download failed: $($_.Exception.Message)"
        Write-Host "[ERA] Trying winget install..."
        try {
            winget install --id Cloudflare.cloudflared -e --accept-source-agreements --accept-package-agreements
            $cloudflared = Find-Cloudflared
        } catch {
            Write-Host "[ERA] winget failed: $($_.Exception.Message)"
        }
    }
}

if (-not $cloudflared) {
    Write-Host "[ERA] cloudflared not found."
    Write-Host "Install: winget install Cloudflare.cloudflared"
    Write-Host "Or:      https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/download/"
    exit 1
}

Write-Host "[ERA] Frontend uses Vite proxy -> API (single public URL)."
Write-Host "[ERA] Starting tunnel to http://127.0.0.1:5173 ..."
Write-Host "[ERA] Copy the https://*.trycloudflare.com URL and share it."
Write-Host "[ERA] Press Ctrl+C to stop the tunnel."
Write-Host ""

& $cloudflared tunnel --url http://127.0.0.1:5173
