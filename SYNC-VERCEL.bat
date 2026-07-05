@echo off
title ERA - Sync secrets to Vercel
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\sync-vercel-env.ps1" -Deploy
pause
