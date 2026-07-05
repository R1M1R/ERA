@echo off
title ERA - Pro payments setup
cd /d "%~dp0"
echo.
echo  ERA Pro payments (Lemon Squeezy / KG-friendly)
echo  ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\setup-payments.ps1"
pause
