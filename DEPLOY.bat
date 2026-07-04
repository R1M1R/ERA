@echo off
title ERA - Production Deploy
cd /d "%~dp0"
echo.
echo  ERA Production Deploy (Render + Vercel)
echo  =====================================
echo.
echo  Step 1: Create Neon Postgres + Upstash Redis (free)
echo  Step 2: Render Blueprint deploys API + Celery worker
echo  Step 3: Vercel deploys frontend
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\deploy-paas.ps1"
pause
