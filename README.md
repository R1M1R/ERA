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

**[GETTING_STARTED.ru.md](GETTING_STARTED.ru.md)** — полный гайд на русском.

```powershell
.\scripts\ensure-docker.ps1          # запустить Docker Desktop
.\scripts\start-era-local.ps1 -All   # Docker + API + Frontend
.\scripts\smoke-test.ps1             # проверка
```

- Frontend: http://localhost:5173 (индикатор API в шапке)
- API: http://127.0.0.1:8000/health

Linux/macOS: `scripts/start-local.sh` and `make dev-infra`.

## Production deployment

### Free PaaS (recommended)

**[deploy/paas/README.md](deploy/paas/README.md)** — Render + Neon + Upstash + Vercel ($0).

```text
Vercel (frontend) → Render (API + Celery) → Neon (Postgres) + Upstash (Redis)
```

Quick start: connect repo to Render Blueprint (`render.yaml`), then Vercel with `VITE_API_URL`.

```powershell
.\scripts\paas-prep.ps1    # generate env checklist for Render + Vercel
.\scripts\verify-paas.ps1 -ApiUrl https://era-api.onrender.com
```

Checklist: [deploy/paas/CHECKLIST.md](deploy/paas/CHECKLIST.md)

## Production — Oracle Cloud (бесплатно)

See **[backend/README_DEPLOY.md](backend/README_DEPLOY.md)** for the full Ubuntu + Docker + Nginx guide.

### Quick path (3 commands on server)

```bash
# 1. Bootstrap backend
bash scripts/server-first-deploy.sh

# 2. Nginx + TLS (replace domains and email)
sudo bash scripts/setup-nginx.sh \
  --api-domain api.your-domain.com \
  --frontend-domain your-domain.com \
  --email you@example.com

# 3. Deploy frontend from GitHub Actions
# Actions → Deploy Frontend → set VITE_API_URL=https://api.your-domain.com
```

### Generate production `.env` locally (Windows)

```powershell
.\scripts\generate-prod-env.ps1 -ApiDomain api.your-domain.com -FrontendDomain your-domain.com -OpenAiKey sk-...
# Copy .env.production.generated to server as ~/ERA/.env
```

### Alternative: Vercel for frontend only

1. Import repo in Vercel, set root directory to `frontend`
2. Add env var `VITE_API_URL=https://api.your-domain.com`
3. Deploy — `frontend/vercel.json` handles SPA routing

### Oracle Cloud Always Free (recommended $0 VPS)

Full guide: **[deploy/oracle-cloud/README.md](deploy/oracle-cloud/README.md)**

```powershell
# Full deploy in one command (IP-only, no domain):
.\scripts\deploy-all-oci.ps1 -ServerIp YOUR_IP -IpOnly -OpenAiKey sk-...

# Checklist: deploy/oracle-cloud/CHECKLIST.md
# GitHub Actions secrets: .\scripts\setup-github-actions.ps1 -ServerIp YOUR_IP
```

```bash
# On OCI Ubuntu instance after creating VM.Standard.A1.Flex:
git clone https://github.com/R1M1R/ERA.git ~/ERA
# copy .env to ~/ERA/.env first
bash ~/ERA/scripts/oracle-cloud-bootstrap.sh
```

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
