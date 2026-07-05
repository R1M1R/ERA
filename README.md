# ERA — Steganographic Historical Artifacts

[![CI](https://github.com/R1M1R/ERA/actions/workflows/ci.yml/badge.svg)](https://github.com/R1M1R/ERA/actions/workflows/ci.yml)

SaaS platform: AI historical riddles → LSB steganography in PNG → server-side verification.

> **Русский:** репозиторий — [github.com/R1M1R/ERA](https://github.com/R1M1R/ERA) · **приложение 24/7** — [frontend-flax-two-11q4abvz2o.vercel.app](https://frontend-flax-two-11q4abvz2o.vercel.app) (frontend + API на одном домене).

## Project URL

| | Link |
|---|------|
| **Repository** | **https://github.com/R1M1R/ERA** |
| **Live app (24/7, full stack)** | **https://frontend-flax-two-11q4abvz2o.vercel.app** |
| **Optional backend (Render)** | [era-api.onrender.com](https://era-api.onrender.com) — not required |

## Live deployment status

| Service | URL | Status |
|---------|-----|--------|
| **GitHub (source)** | **[github.com/R1M1R/ERA](https://github.com/R1M1R/ERA)** | ✅ Online |
| **Full app (Vercel, 24/7)** | **[frontend-flax-two-11q4abvz2o.vercel.app](https://frontend-flax-two-11q4abvz2o.vercel.app)** | ✅ Online |
| **API + Frontend** | same URL (serverless FastAPI + React) | ✅ Generate / Gallery / Verify |
| **Render (optional)** | [era-api.onrender.com](https://era-api.onrender.com) | optional fallback |

> **24/7 without your laptop:** the full product runs on Vercel (frontend + API).  
> No Render, Neon, or Upstash required. Demo mode works out of the box.

## Links

| Resource | URL |
|----------|-----|
| **GitHub (source code)** | **https://github.com/R1M1R/ERA** |
| **Live app (24/7)** | **https://frontend-flax-two-11q4abvz2o.vercel.app** |
| **Local app** (this PC) | http://localhost:5173 |
| **Optional Render API** | https://era-api.onrender.com |
| **Redeploy (Vercel)** | `npx vercel --prod` from repo root |

> **24/7 without your laptop:** full stack on Vercel (no extra setup).  
> Local mode (`GO.bat` / `AUTONOMOUS.bat`) works only while this PC is on.

---

## Quick start (Windows, no Docker)

| Launcher | Purpose |
|----------|---------|
| **`GO.bat`** | Start API + frontend, open browser |
| **`AUTONOMOUS.bat`** | Silent start + watchdog (self-heal) |
| **`STATUS.bat`** | Check API / frontend / watchdog |
| **`DEPLOY_CLOUD.bat`** | Optional Render backend (not required) |
| **`24x7.bat`** | Local setup + cloud status |
| **`SHARE.bat`** | Temporary public URL (Cloudflare tunnel) |

```powershell
git clone https://github.com/R1M1R/ERA.git
cd ERA
.\GO.bat
```

Full guide: **[GETTING_STARTED.ru.md](GETTING_STARTED.ru.md)**

---

## Cloud 24/7 (laptop off)

**Default:** Vercel hosts frontend + API on one URL (already live).

```powershell
.\scripts\verify-paas.ps1 -ApiUrl https://frontend-flax-two-11q4abvz2o.vercel.app -FullE2E
```

Redeploy from repo root:

```powershell
npx vercel --prod
```

### Optional: Render backend

For a dedicated Docker API (persistent SQLite on container disk): **[Deploy on Render](https://render.com/deploy?repo=https://github.com/R1M1R/ERA)**. Full Postgres stack: `render-full.yaml`. See **[deploy/paas/README.md](deploy/paas/README.md)**.

---

## Stack

| Layer | Technology |
|-------|------------|
| API (cloud) | FastAPI on Vercel serverless (Mangum) |
| API (local/Docker) | FastAPI, Gunicorn, Uvicorn workers |
| Workers | Celery, Redis (or in-process standalone) |
| Database | PostgreSQL / SQLite (standalone) |
| AI | OpenAI (demo mode without key) |
| Frontend | React, Vite, TypeScript, Tailwind CSS |

## Repository structure

```text
ERA/
├── api/              # Vercel serverless entry (production)
├── backend/          # FastAPI, steganography, LLM
├── worker/           # Celery tasks
├── frontend/         # React SPA
├── vercel.json       # Vercel full-stack deploy config
├── scripts/          # GO.bat, autonomous, deploy helpers
├── render.yaml       # Optional Render Blueprint (lite)
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
