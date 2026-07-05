@echo off
title ERA - Deploy Cloud Backend (24/7)
cd /d "%~dp0"
echo.
echo  ERA Cloud Deploy (Render Lite - no database keys)
echo  =================================================
echo  Opens Render one-click deploy and waits until API is live.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\deploy-render-lite.ps1"
pause
