@echo off
title ERA - 24/7 Local Mode
cd /d "%~dp0"
echo.
echo  ERA 24/7 Local Mode
echo  ===================
echo  1. Configure keys
echo  2. Start API + Frontend
echo  3. Install auto-start on Windows login
echo  4. Optional: public tunnel (SHARE.bat)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\setup-keys.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\restart-era.ps1" -SkipVerify
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\install-auto-start.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\product-ready.ps1"
echo.
echo  Local:  http://localhost:5173
echo  Public: run SHARE.bat for temporary URL
echo  Cloud:  run 24x7.bat for Render+Vercel deploy
echo.
pause
