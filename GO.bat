@echo off
title ERA - Steganographic Historical Artifacts
cd /d "%~dp0"
echo.
echo  ========================================
echo   ERA - Starting fully working product
echo  ========================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\restart-era.ps1"
echo.
echo  Open http://localhost:5173 and click Generate
echo.
pause
