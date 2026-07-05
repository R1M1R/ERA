@echo off
title ERA - Production owner setup
cd /d "%~dp0"
echo.
echo  ERA Production setup (Neon + Lemon Squeezy + payments)
echo  =====================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\setup-neon-vercel.ps1"
if errorlevel 1 exit /b 1
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\setup-lemonsqueezy-webhook.ps1"
if errorlevel 1 exit /b 1
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\setup-payments.ps1"
echo.
echo  Next: add OPENAI_API_KEY on Vercel for Pro GPT riddles
echo    npx vercel env add OPENAI_API_KEY production
echo    npx vercel --prod
echo.
echo  Verify:
echo    VERIFY-PRODUCTION.bat
echo.
pause
