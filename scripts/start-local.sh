#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="${ROOT}"

echo "[ERA] Starting infrastructure (PostgreSQL + Redis + Celery)..."
docker compose --env-file "${ROOT}/.env" up -d postgres redis celery-worker

cat <<EOF

[ERA] Run these in separate terminals:

  API:
    cd backend
    export PYTHONPATH=${ROOT}
    ./venv/bin/uvicorn main:app --reload --host 127.0.0.1 --port 8000

  Celery worker:
    export PYTHONPATH=${ROOT}
    ./backend/venv/bin/celery -A worker.celery_app worker --loglevel=info

  Frontend:
    cd frontend && npm run dev

[ERA] Health check: http://127.0.0.1:8000/health
EOF
