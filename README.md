# ERA — Steganographic Historical Artifacts

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

```bash
# Infrastructure
docker compose up -d

# Backend API
cd backend
python -m venv venv
venv\Scripts\pip install -r requirements.txt   # Windows
set PYTHONPATH=..
venv\Scripts\uvicorn main:app --reload

# Celery worker
set PYTHONPATH=..
venv\Scripts\celery -A worker.celery_app worker --loglevel=info

# Frontend
cd frontend
npm install
npm run dev
```

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
