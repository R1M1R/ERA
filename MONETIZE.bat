@echo off
title ERA - Stripe Monetization
cd /d "%~dp0"
echo.
echo  ERA Stripe Setup (passive income / Pro subscriptions)
echo  ====================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\setup-stripe.ps1"
pause
