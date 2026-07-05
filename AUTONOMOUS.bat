@echo off
title ERA - Autonomous Mode
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\start-autonomous.ps1" -WithWatchdog
echo.
echo  ERA running autonomously.
echo  Local: http://localhost:5173
echo  Logs:  logs\era-autonomous.log
echo.
