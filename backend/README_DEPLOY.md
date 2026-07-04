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

## 6. Configure Nginx reverse proxy (recommended)

Production compose binds API to `127.0.0.1:8000` only. Expose HTTPS through Nginx on the host.

```bash
sudo apt install -y nginx certbot python3-certbot-nginx
sudo cp deploy/nginx/era-api.conf /etc/nginx/sites-available/era-api.conf
sudo ln -s /etc/nginx/sites-available/era-api.conf /etc/nginx/sites-enabled/era-api.conf
sudo nginx -t
sudo systemctl reload nginx
```

Edit `server_name` in the config to your real API domain, then obtain TLS:

```bash
sudo certbot --nginx -d api.your-domain.com
```

Set CORS in `.env`:

```env
CORS_ORIGINS=https://your-domain.com,https://www.your-domain.com
```

Restart API after changing CORS:

```bash
docker compose --env-file .env -f backend/production.docker-compose.yml up -d api
```

UFW example when Nginx terminates HTTPS:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

---

## 7. Deploy the frontend separately

Build the React app locally or in CI:

```bash
cd frontend
npm ci
VITE_API_URL=https://api.your-domain.com npm run build
```

Option A — static hosting (Vercel, Cloudflare Pages, S3).

Option B — same Ubuntu server with Nginx:

```bash
sudo mkdir -p /var/www/era-frontend
sudo rsync -av frontend/dist/ /var/www/era-frontend/
sudo cp deploy/nginx/era-frontend.conf /etc/nginx/sites-available/era-frontend.conf
sudo ln -s /etc/nginx/sites-available/era-frontend.conf /etc/nginx/sites-enabled/era-frontend.conf
sudo nginx -t && sudo systemctl reload nginx
```

---

## 8. GitHub Actions

Repository: [https://github.com/R1M1R/ERA](https://github.com/R1M1R/ERA)

| Workflow | Trigger | Purpose |
|---|---|---|
| `CI` | push / PR to `main` | Backend import check, compose validation, frontend build |
| `Deploy Backend` | manual (`workflow_dispatch`) | SSH deploy to production server |

### Configure production deploy secrets

In GitHub → **Settings → Secrets and variables → Actions**, add:

| Secret | Description |
|---|---|
| `SSH_HOST` | Server IP or hostname |
| `SSH_USER` | SSH username |
| `SSH_PRIVATE_KEY` | Private key with server access |

Then run **Actions → Deploy Backend → Run workflow**.

---

## 9. Useful operational commands

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

## 10. Architecture summary

```text
Internet
   │
   ├─ Frontend (static hosting, separate deploy)
   │
   └─ Nginx :443 ──► era-api (127.0.0.1:8000)
                    │
                    ├── postgres
                    ├── redis
                    └── celery-worker
```

Shared Docker volume `artifacts_data` stores generated PNG files for both API and Celery.

---

## 11. Security checklist

- [ ] `.env` exists only on the server and is listed in `.gitignore`
- [ ] Strong `POSTGRES_PASSWORD` and `ERA_SERVER_SALT`
- [ ] PostgreSQL and Redis are **not** exposed publicly (only internal Docker network)
- [ ] HTTPS terminates at reverse proxy
- [ ] Frontend uses production `VITE_API_URL`
