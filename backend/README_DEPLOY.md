# ERA — Production Backend Deployment

This guide deploys the **backend stack only** (FastAPI + PostgreSQL + Redis + Celery) on a clean Ubuntu server using Docker Compose.

The frontend is deployed separately (for example, as static files on Nginx, Vercel, or Cloudflare Pages) and should point to the public API URL.

---

## 1. Prepare a clean Ubuntu server

Use Ubuntu 22.04 or 24.04 with SSH access and a sudo-enabled user.

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl git
```

---

## 2. Install Docker Engine + Compose plugin

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
docker --version
docker compose version
```

If `newgrp` is unavailable in your session, log out and log back in so Docker group membership applies.

---

## 3. Clone the repository

```bash
git clone https://github.com/R1M1R/ERA.git
cd ERA
```

Replace the GitHub URL with your actual repository.

---

## 4. Create production environment variables on the server

Do **not** commit secrets to Git. Create a local `.env` file on the server:

```bash
cp .env.example .env
nano .env
```

Set strong values for at least:

| Variable | Example |
|---|---|
| `POSTGRES_PASSWORD` | long random password |
| `DATABASE_URL` | `postgresql+asyncpg://era:PASSWORD@postgres:5432/era_db` |
| `DATABASE_URL_SYNC` | `postgresql+psycopg2://era:PASSWORD@postgres:5432/era_db` |
| `REDIS_URL` | `redis://redis:6379/0` |
| `CELERY_BROKER_URL` | `redis://redis:6379/0` |
| `CELERY_RESULT_BACKEND` | `redis://redis:6379/0` |
| `OPENAI_API_KEY` | your OpenAI key |
| `ERA_SERVER_SALT` | long random secret |

Important: inside Docker Compose use service names `postgres` and `redis`, not `localhost`.

---

## 5. Build and start the production stack

Run from the **repository root**:

```bash
docker compose --env-file .env -f backend/production.docker-compose.yml up -d --build
```

This starts:

| Service | Role |
|---|---|
| `postgres` | PostgreSQL 16 database |
| `redis` | Celery broker + result backend |
| `api` | FastAPI via Gunicorn + Uvicorn workers on port **8000** |
| `celery-worker` | Background artifact generation |

Check status:

```bash
docker compose --env-file .env -f backend/production.docker-compose.yml ps
docker compose --env-file .env -f backend/production.docker-compose.yml logs -f api
```

Health check:

```bash
curl http://127.0.0.1:8000/health
```

Expected response:

```json
{"status":"ok","service":"era-api","version":"0.4.0"}
```

---

## 6. Open the API port (if using a cloud firewall)

Allow inbound TCP **8000** in your provider firewall/security group, or place Nginx/Caddy in front of the API for HTTPS.

Example UFW rule:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 8000/tcp
sudo ufw enable
```

For production traffic, prefer a reverse proxy:

- `https://api.your-domain.com` → `http://127.0.0.1:8000`

---

## 7. Deploy the frontend separately

Build the React app locally or in CI:

```bash
cd frontend
npm ci
VITE_API_URL=https://api.your-domain.com npm run build
```

Upload `frontend/dist/` to your static hosting provider and configure the public API URL via `VITE_API_URL`.

Update backend CORS origins in `backend/main.py` before production if your frontend domain differs from localhost.

---

## 8. Useful operational commands

Restart after code update:

```bash
git pull
docker compose --env-file .env -f backend/production.docker-compose.yml up -d --build
```

Stop stack:

```bash
docker compose --env-file .env -f backend/production.docker-compose.yml down
```

Stop and remove volumes (destructive):

```bash
docker compose --env-file .env -f backend/production.docker-compose.yml down -v
```

View worker logs:

```bash
docker compose --env-file .env -f backend/production.docker-compose.yml logs -f celery-worker
```

---

## 9. Architecture summary

```text
Internet
   │
   ├─ Frontend (static hosting, separate deploy)
   │
   └─ :8000 ──► era-api (Gunicorn/Uvicorn)
                    │
                    ├── postgres
                    ├── redis
                    └── celery-worker
```

Shared Docker volume `artifacts_data` stores generated PNG files for both API and Celery.

---

## 10. Security checklist

- [ ] `.env` exists only on the server and is listed in `.gitignore`
- [ ] Strong `POSTGRES_PASSWORD` and `ERA_SERVER_SALT`
- [ ] PostgreSQL and Redis are **not** exposed publicly (only internal Docker network)
- [ ] HTTPS terminates at reverse proxy
- [ ] Frontend uses production `VITE_API_URL`
