@echo off
title ERA - Verify Vercel production
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\verify-vercel-production.ps1"
pause
