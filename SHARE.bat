@echo off
title ERA - Public Demo
cd /d "%~dp0"
echo.
echo  ERA Public Demo - Cloudflare Tunnel
echo  ===================================
echo.
if not exist "tools\cloudflared.exe" (
  echo Downloading cloudflared...
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "New-Item -ItemType Directory -Force -Path 'tools' | Out-Null; Invoke-WebRequest -Uri 'https://github.com/cloudflare/cloudflared/releases/download/2026.6.1/cloudflared-windows-amd64.exe' -OutFile 'tools\cloudflared.exe' -UseBasicParsing"
)
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\share-local.ps1" -SkipStart
pause
