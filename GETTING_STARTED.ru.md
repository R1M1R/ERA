# ERA — Быстрый старт

# Локальная разработка (Windows)

## Вариант A — без Docker (рекомендуется)

Работает сразу: SQLite + demo-загадки + Celery in-process. Docker не нужен.

```powershell
.\scripts\start-standalone.ps1
```

E2E тест (API должен быть запущен):

```powershell
.\scripts\e2e-standalone.ps1
```

- **Frontend:** http://localhost:5173  
- **API:** http://127.0.0.1:8000/health  

## Вариант B — с Docker

### 1. Требования

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Python 3.12 (venv в `backend/venv`)
- Node.js 22+ (`frontend/node_modules`)

### 2. Запуск одной командой

```powershell
copy .env.local.example .env   # если .env ещё нет
.\scripts\ensure-docker.ps1    # запуск Docker Desktop (до 3 мин)
.\scripts\start-era-local.ps1 -All
.\scripts\smoke-test.ps1
```

- **Frontend:** http://localhost:5173  
- **API:** http://127.0.0.1:8000/health  

В шапке сайта индикатор: зелёный = API online, красный = API offline.

### 3. Настройка `.env`

```powershell
copy .env.local.example .env
```

Файл `.env.local.example` уже содержит **localhost** URLs для Docker Compose:

```env
DATABASE_URL=postgresql+asyncpg://era:era_secret@localhost:5432/era_db
REDIS_URL=redis://localhost:6379/0
OPENAI_API_KEY=sk-ваш-ключ
ERA_SERVER_SALT=любой-длинный-секрет
```

---

## Production — бесплатный PaaS (рекомендуется)

**[deploy/paas/README.md](deploy/paas/README.md)** — Render + Neon + Upstash + Vercel.

```text
Vercel → Render API → Neon Postgres + Upstash Redis + Render Celery worker
```

Шаблон env: `.env.paas.example`

```powershell
.\scripts\paas-prep.ps1
.\scripts\verify-paas.ps1 -ApiUrl https://era-api.onrender.com
```

Чеклист: [deploy/paas/CHECKLIST.md](deploy/paas/CHECKLIST.md)

---

## Production — Oracle Cloud (VPS)

Полный гайд: [deploy/oracle-cloud/README.md](deploy/oracle-cloud/README.md)  
Чеклист: [deploy/oracle-cloud/CHECKLIST.md](deploy/oracle-cloud/CHECKLIST.md)

```powershell
.\scripts\deploy-all-oci.ps1 -ServerIp ВАШ_IP -IpOnly -OpenAiKey sk-...
```

---

## Полезные скрипты

| Скрипт | Назначение |
|---|---|
| `verify-product.ps1` | Полная проверка (E2E + build) |
| `run-product.ps1` | Запуск + E2E (полный продукт без Docker) |
| `start-standalone.ps1` | Запуск без Docker (SQLite) |
| `e2e-standalone.ps1` | Полный E2E тест standalone |
| `start-era-local.ps1 -All` | Локальный запуск с Docker |
| `smoke-test.ps1` | Проверка API и frontend |
| `deploy-all-oci.ps1` | Полный деплой на Oracle |
| `setup-github-actions.ps1` | Секреты для CI/CD |
| `verify-deployment.ps1` | Проверка production |

---

## Частые проблемы

| Проблема | Решение |
|---|---|
| Docker pipe error | `.\scripts\ensure-docker.ps1` или используйте `.\scripts\start-standalone.ps1` |
| API offline (красный) | Запустите `.\scripts\start-standalone.ps1` или `.\scripts\start-era-local.ps1 -All` |
| API degraded (жёлтый) | Postgres/Redis не запущены — `docker compose up -d postgres redis celery-worker` |
| Generate не работает | Celery в Docker + `ERA_DEMO_MODE=true` или реальный `OPENAI_API_KEY` |
| CORS ошибка | Добавьте origin фронтенда в `CORS_ORIGINS` |
