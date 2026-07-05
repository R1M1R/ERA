@echo off
title ERA - 24/7 Setup
cd /d "%~dp0"
echo.
echo  ERA 24/7 Setup
echo  ==============
echo  Local:  GO.bat / AUTONOMOUS.bat (this PC)
echo  Cloud:  DEPLOY_CLOUD.bat (Render, no keys, always online)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\setup-24x7.ps1" -OpenDeployPages
pause
