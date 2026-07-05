@echo off
title ERA - Status
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\autonomous-status.ps1"
pause
