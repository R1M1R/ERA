# ERA — Steganographic Historical Artifacts

[![CI](https://github.com/R1M1R/ERA/actions/workflows/ci.yml/badge.svg)](https://github.com/R1M1R/ERA/actions/workflows/ci.yml)

SaaS platform: AI historical riddles → LSB steganography in PNG → server-side verification.

## Project URL

| | Link |
|---|------|
| **Repository** | **https://github.com/R1M1R/ERA** |
| **Live app (frontend)** | **https://frontend-flax-two-11q4abvz2o.vercel.app** |
| **Enable full cloud** | **[DEPLOY_CLOUD.bat](DEPLOY_CLOUD.bat)** or [Deploy on Render](https://render.com/deploy?repo=https://github.com/R1M1R/ERA) |

## Live deployment status

| Service | URL | Status |
|---------|-----|--------|
| **GitHub (source)** | **[github.com/R1M1R/ERA](https://github.com/R1M1R/ERA)** | ✅ Online |
| **Frontend (Vercel, 24/7)** | **[frontend-flax-two-11q4abvz2o.vercel.app](https://frontend-flax-two-11q4abvz2o.vercel.app)** | ✅ Online |
| **Backend API (Render)** | [era-api.onrender.com](https://era-api.onrender.com) | ⏳ One-click deploy (2 min) |
| **Full cloud product** | — | ⏳ Deploy backend once (no keys needed) |

> **24/7 without your laptop:** frontend is already live on Vercel.  
> **One click** to enable Generate / Gallery / Verify in the cloud (free Render, **no Neon/Upstash keys**):  
> **[Deploy backend on Render](https://render.com/deploy?repo=https://github.com/R1M1R/ERA)** → sign in → Apply.  
> First request after idle may take 30–90 s (Render free tier cold start).

## Links

| Resource | URL |
|----------|-----|
| **GitHub (source code)** | **https://github.com/R1M1R/ERA** |
| **Live frontend (Vercel)** | **https://frontend-flax-two-11q4abvz2o.vercel.app** |
| **Local app** (this PC) | http://localhost:5173 |
| **Cloud API** (deploy required) | https://era-api.onrender.com |
| **One-click backend deploy** | [Deploy on Render](https://render.com/deploy?repo=https://github.com/R1M1R/ERA) |
| **Frontend deploy** | [Import on Vercel](https://vercel.com/new/clone?repository-url=https://github.com/R1M1R/ERA&project-name=era&root-directory=frontend) |

> **24/7 without your laptop:** Vercel frontend is live; click **[Deploy on Render](https://render.com/deploy?repo=https://github.com/R1M1R/ERA)** once (lite mode, no database keys).  
> Local mode (`GO.bat` / `AUTONOMOUS.bat`) works only while this PC is on.

---

## Quick start (Windows, no Docker)

| Launcher | Purpose |
|----------|---------|
| **`GO.bat`** | Start API + frontend, open browser |
| **`AUTONOMOUS.bat`** | Silent start + watchdog (self-heal) |
| **`STATUS.bat`** | Check API / frontend / watchdog |
| **`DEPLOY_CLOUD.bat`** | One-click Render backend (24/7, no keys) |
| **`24x7.bat`** | Local + open cloud deploy pages |
| **`SHARE.bat`** | Temporary public URL (Cloudflare tunnel) |

```powershell
git clone https://github.com/R1M1R/ERA.git
cd ERA
.\GO.bat
```

Full guide: **[GETTING_STARTED.ru.md](GETTING_STARTED.ru.md)**

---

## Cloud 24/7 (laptop off)

Stack: **Vercel** (frontend, already live) → **Render** (API, one-click).

### Quick deploy (recommended, ~2 min, no keys)

1. Open **[Deploy on Render](https://render.com/deploy?repo=https://github.com/R1M1R/ERA)**
2. Sign in with GitHub → **Apply** (uses `render.yaml` lite mode: SQLite + in-process Celery)
3. Wait until `era-api` is **Live** → open [frontend](https://frontend-flax-two-11q4abvz2o.vercel.app)

CORS and demo mode are preconfigured. Gallery may reset after Render cold start on free tier.

```powershell
.\scripts\verify-paas.ps1 -ApiUrl https://era-api.onrender.com -FullE2E
```

### Full production (persistent Postgres + worker)

For durable gallery data: Neon + Upstash + `render-full.yaml`. See **[deploy/paas/README.md](deploy/paas/README.md)**.

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
