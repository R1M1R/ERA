# ERA — Steganographic Historical Artifacts

[![CI](https://github.com/R1M1R/ERA/actions/workflows/ci.yml/badge.svg)](https://github.com/R1M1R/ERA/actions/workflows/ci.yml)

SaaS platform that autonomously generates historical riddles via LLM, seals them into procedural PNG artifacts using LSB steganography, and verifies authenticity server-side.

## Stack

| Layer | Technology |
|---|---|
| API | FastAPI, Gunicorn, Uvicorn workers |
| Workers | Celery, Redis |
| Database | PostgreSQL, SQLAlchemy (asyncpg) |
| AI | OpenAI |
| Frontend | React, Vite, TypeScript, Tailwind CSS |

## Repository structure

```text
ERA/
├── backend/          # FastAPI app, steganography, LLM service
├── worker/           # Celery tasks
├── frontend/         # React SPA
├── deploy/nginx/     # Nginx configs for production
└── .github/workflows # CI/CD
```

## Quick start (local development)

```powershell
# 1. Copy env and install deps
cp .env.example .env

# 2. Start infra
.\scripts\start-local.ps1

# 3. Backend API (new terminal)
cd backend
$env:PYTHONPATH="c:\path\to\ERA"
.\venv\Scripts\uvicorn main:app --reload --host 127.0.0.1 --port 8000

# 4. Celery (new terminal)
$env:PYTHONPATH="c:\path\to\ERA"
backend\venv\Scripts\celery -A worker.celery_app worker --loglevel=info

# 5. Frontend (new terminal)
cd frontend && npm run dev
```

Linux/macOS: use `scripts/start-local.sh` and `make dev-infra`.

## Production deployment

See **[backend/README_DEPLOY.md](backend/README_DEPLOY.md)** for the full Ubuntu + Docker + Nginx guide.

```bash
git clone https://github.com/R1M1R/ERA.git
cd ERA
cp .env.example .env
docker compose --env-file .env -f backend/production.docker-compose.yml up -d --build
```

## API endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/generate` | Queue autonomous artifact generation |
| `GET` | `/status/{id}` | Poll generation status |
| `GET` | `/artifacts` | Paginated gallery |
| `POST` | `/verify` | Proof-of-authenticity check |
| `GET` | `/health` | Health probe |

## License

Private project — all rights reserved.
