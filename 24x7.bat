@echo off
title ERA - 24/7 Setup
cd /d "%~dp0"
echo.
echo  ERA 24/7 Setup
echo  ==============
echo  Local: works now on this PC
echo  Cloud: Neon + Upstash + Render + Vercel (always online)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\setup-24x7.ps1" -OpenDeployPages
pause
