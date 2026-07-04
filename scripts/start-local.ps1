@echo off
setlocal
set "ROOT=%~dp0.."
set "PYTHONPATH=%ROOT%"
cd /d "%ROOT%"

echo [ERA] Starting infrastructure (PostgreSQL + Redis)...
docker compose --env-file "%ROOT%\.env" up -d postgres redis
if errorlevel 1 exit /b 1

echo.
echo [ERA] Run these in separate terminals:
echo.
echo   API:
echo     cd backend
echo     set PYTHONPATH=%ROOT%
echo     venv\Scripts\uvicorn main:app --reload --host 127.0.0.1 --port 8000
echo.
echo   Celery worker:
echo     set PYTHONPATH=%ROOT%
echo     backend\venv\Scripts\celery -A worker.celery_app worker --loglevel=info
echo.
echo   Frontend:
echo     cd frontend
echo     npm run dev
echo.
echo [ERA] Health check: http://127.0.0.1:8000/health
