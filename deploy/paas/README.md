# ERA на бесплатном PaaS

Рекомендуемый стек ($0):

| Сервис | Платформа | Роль |
|---|---|---|
| Frontend | **Vercel** | React SPA |
| API | **Render** (Web) | FastAPI |
| Celery Worker | **Render** (Background Worker) | генерация артефактов |
| PostgreSQL | **Neon** | база данных |
| Redis | **Upstash** | очередь Celery |

PNG-артефакты хранятся **в PostgreSQL** (`image_bytes`), потому что диск PaaS эфемерный.

---

## Часть 1. Neon (PostgreSQL)

1. [neon.tech](https://neon.tech) → создать проект `era`
2. Скопировать **connection string** (pooled):
   ```
   postgresql://user:pass@ep-xxx.neon.tech/era_db?sslmode=require
   ```
3. Использовать для `DATABASE_URL` и `DATABASE_URL_SYNC`

---

## Часть 2. Upstash (Redis)

1. [upstash.com](https://upstash.com) → Redis database → **Global**
2. Скопировать **TLS URL** (`rediss://...`)
3. Установить в:
   - `REDIS_URL`
   - `CELERY_BROKER_URL`
   - `CELERY_RESULT_BACKEND`

---

## Часть 3. Render (API + Worker)

### Вариант A — Blueprint (рекомендуется)

1. [render.com](https://render.com) → **New → Blueprint**
2. Подключить репозиторий `R1M1R/ERA`
3. Render найдёт `render.yaml` в корне
4. Заполнить env vars (см. `.env.paas.example`):
   - `DATABASE_URL`, `DATABASE_URL_SYNC` — из Neon
   - `CELERY_BROKER_URL`, `CELERY_RESULT_BACKEND`, `REDIS_URL` — из Upstash
   - `OPENAI_API_KEY` — ваш ключ (или `ERA_DEMO_MODE=true` для первого теста без OpenAI)
   - `CORS_ORIGINS` — URL Vercel (после деплоя фронта)
5. Deploy

После деплоя API будет на: `https://era-api.onrender.com`

> **Free tier:** сервис засыпает после 15 мин неактивности. Первый запрос ~30–60 с (cold start).

### Вариант B — Вручную

**Web Service:**
- Docker → `backend/Dockerfile`, context: `.`
- Health check: `/health`
- `GUNICORN_WORKERS=1`

**Background Worker:**
- Docker → `worker/Dockerfile`, context: `.`
- Command: `celery -A worker.celery_app worker --loglevel=info --concurrency=1`

---

## Часть 4. Vercel (Frontend)

1. [vercel.com](https://vercel.com) → Import `R1M1R/ERA`
2. **Root Directory:** `frontend`
3. **Environment Variable:**
   ```
   VITE_API_URL=https://era-api.onrender.com
   ```
4. Deploy

5. В Render → `era-api` → Environment → обновить:
   ```
   CORS_ORIGINS=https://your-project.vercel.app
   ```
6. Redeploy API

---

## Проверка

```bash
curl https://era-api.onrender.com/health
# {"status":"ok","service":"era-api","version":"0.4.0"}

curl -X POST https://era-api.onrender.com/generate
# {"task_id":"..."}
```

Откройте Vercel URL → зелёный индикатор **API online** → нажмите Generate.

---

## Env template

См. [`.env.paas.example`](../../.env.paas.example) в корне репозитория.

### Windows: подготовка env

```powershell
.\scripts\paas-prep.ps1
# → создаёт paas-env-checklist.txt для вставки в Render + Vercel
```

Чеклист: [CHECKLIST.md](CHECKLIST.md)

---

## Альтернативы

| PaaS | Плюсы | Минусы |
|---|---|---|
| **Render** (этот гайд) | Docker, worker, free | Cold start |
| **Railway** | проще UI, $5 кредитов/мес | лимит кредитов |
| **Fly.io** | глобальный edge | сложнее настройка |
| **Oracle Cloud** | always-on VM | нужен VPS гайд |

Oracle Cloud: [deploy/oracle-cloud/README.md](../oracle-cloud/README.md)

---

## Troubleshooting

| Проблема | Решение |
|---|---|
| Generate зависает | Проверьте логи `era-celery` worker на Render |
| CORS error | `CORS_ORIGINS` = точный URL Vercel (без `/`) |
| Redis SSL error | Используйте `rediss://` URL из Upstash |
| 502 на API | Cold start — подождите 60 с или upgrade plan |
| Картинки 404 | Worker должен писать `image_bytes` в DB (уже в коде) |

---

## Архитектура

```text
Vercel (frontend)
    │  VITE_API_URL
    ▼
Render era-api (FastAPI)
    │                    ┌── Neon PostgreSQL
    ├── Celery ──────────┤   (artifacts + image_bytes)
    │                    └── Upstash Redis
    └── Render era-celery (worker)
```
