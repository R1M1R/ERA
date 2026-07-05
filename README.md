# ERA — Steganographic Historical Artifacts

[![CI](https://github.com/R1M1R/ERA/actions/workflows/ci.yml/badge.svg)](https://github.com/R1M1R/ERA/actions/workflows/ci.yml)

SaaS platform: AI historical riddles → LSB steganography in PNG → server-side verification.

## Project URL

**https://github.com/R1M1R/ERA**

## Live deployment status

| Service | URL | Status |
|---------|-----|--------|
| Source code | [github.com/R1M1R/ERA](https://github.com/R1M1R/ERA) | ✅ Online |
| Frontend (Vercel, 24/7) | [frontend-flax-two-11q4abvz2o.vercel.app](https://frontend-flax-two-11q4abvz2o.vercel.app) | ✅ Online |
| Backend API (Render) | [era-api.onrender.com](https://era-api.onrender.com) | ⏳ Deploy required |
| Full cloud product | — | ⏳ Needs Neon + Upstash keys |

> **Without your laptop:** frontend is already 24/7 on Vercel.  
> **Generate/Gallery/Verify** in the cloud work after you deploy the backend (free, ~10 min):  
> **[Deploy on Render](https://render.com/deploy?repo=https://github.com/R1M1R/ERA)** + paste `DATABASE_URL` and `REDIS_URL` from [Neon](https://neon.tech) and [Upstash](https://upstash.com).

## Links

| Resource | URL |
|----------|-----|
| **GitHub (source code)** | **https://github.com/R1M1R/ERA** |
| **Live frontend (Vercel)** | **https://frontend-flax-two-11q4abvz2o.vercel.app** |
| **Local app** (this PC) | http://localhost:5173 |
| **Cloud API** (deploy required) | https://era-api.onrender.com |
| **One-click backend deploy** | [Deploy on Render](https://render.com/deploy?repo=https://github.com/R1M1R/ERA) |
| **Frontend deploy** | [Import on Vercel](https://vercel.com/new/clone?repository-url=https://github.com/R1M1R/ERA&project-name=era&root-directory=frontend) |

> **24/7 without your laptop** requires **cloud deploy** (Render + Neon + Upstash + Vercel, free tier).  
> Local mode (`GO.bat` / `AUTONOMOUS.bat`) works only while this PC is on.

---

## Quick start (Windows, no Docker)

| Launcher | Purpose |
|----------|---------|
| **`GO.bat`** | Start API + frontend, open browser |
| **`AUTONOMOUS.bat`** | Silent start + watchdog (self-heal) |
| **`STATUS.bat`** | Check API / frontend / watchdog |
| **`24x7.bat`** | Cloud deploy wizard (Neon + Upstash + Render + Vercel) |
| **`SHARE.bat`** | Temporary public URL (Cloudflare tunnel) |

```powershell
git clone https://github.com/R1M1R/ERA.git
cd ERA
.\GO.bat
```

Full guide: **[GETTING_STARTED.ru.md](GETTING_STARTED.ru.md)**

---

## Cloud 24/7 (laptop off)

Stack: **Vercel** (frontend) → **Render** (API + Celery) → **Neon** (Postgres) + **Upstash** (Redis).

### Step 1 — Free databases (5 min)

1. [neon.tech](https://neon.tech) → create project → copy `DATABASE_URL`
2. [upstash.com](https://upstash.com) → Redis → copy `rediss://...` URL

### Step 2 — Backend on Render

1. Open **[Deploy on Render](https://render.com/deploy?repo=https://github.com/R1M1R/ERA)**
2. Paste env vars from `.\scripts\paas-prep.ps1` or `.secrets.local`
3. Set on **era-api** and **era-celery**: `DATABASE_URL`, `REDIS_URL`, `ERA_DEMO_MODE=true` (or real `OPENAI_API_KEY`)

### Step 3 — Frontend on Vercel

1. [Import repo](https://vercel.com/new/clone?repository-url=https://github.com/R1M1R/ERA&project-name=era&root-directory=frontend)
2. Env: `VITE_API_URL=https://YOUR-API.onrender.com`
3. Deploy

### Step 4 — CORS

On Render `era-api`: `CORS_ORIGINS=https://YOUR-APP.vercel.app` → redeploy.

```powershell
.\scripts\verify-paas.ps1 -ApiUrl https://era-api.onrender.com -FullE2E
```

Details: **[deploy/paas/README.md](deploy/paas/README.md)** · **[deploy/paas/CHECKLIST.md](deploy/paas/CHECKLIST.md)**

---

## Stack

| Layer | Technology |
|-------|------------|
| API | FastAPI, Gunicorn, Uvicorn workers |
| Workers | Celery, Redis |
| Database | PostgreSQL / SQLite (standalone) |
| AI | OpenAI (demo mode without key) |
| Frontend | React, Vite, TypeScript, Tailwind CSS |

## Repository structure

```text
ERA/
├── backend/          # FastAPI, steganography, LLM
├── worker/           # Celery tasks
├── frontend/         # React SPA
├── scripts/          # GO.bat, autonomous, deploy helpers
├── render.yaml       # Render Blueprint (API + worker)
└── .github/workflows # CI
```

## Local with Docker

```powershell
.\scripts\ensure-docker.ps1
.\scripts\start-era-local.ps1 -All
```

## API endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/generate` | Queue artifact generation |
| `GET` | `/status/{id}` | Poll task status |
| `GET` | `/artifacts` | Paginated gallery |
| `POST` | `/verify` | Authenticity check |
| `GET` | `/health` | Health probe |

## Production — Oracle Cloud VPS

See **[deploy/oracle-cloud/README.md](deploy/oracle-cloud/README.md)** and **[backend/README_DEPLOY.md](backend/README_DEPLOY.md)**.

## License

Private project — all rights reserved.
