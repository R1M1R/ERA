# ERA — Быстрый старт

## Локальная разработка (Windows)

### 1. Требования

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Python 3.12 (venv в `backend/venv`)
- Node.js 22+ (`frontend/node_modules`)

### 2. Запуск одной командой

```powershell
.\scripts\ensure-docker.ps1          # если Docker не запущен
.\scripts\start-era-local.ps1 -All # Docker + API + Frontend
.\scripts\smoke-test.ps1           # проверка
```

- **Frontend:** http://localhost:5173  
- **API:** http://127.0.0.1:8000/health  

В шапке сайта индикатор: зелёный = API online, красный = API offline.

### 3. Настройка `.env`

```powershell
copy .env.example .env
```

Для локальной разработки в `.env` используйте **localhost** (не `postgres`/`redis`):

```env
DATABASE_URL=postgresql+asyncpg://era:era_secret@localhost:5432/era_db
REDIS_URL=redis://localhost:6379/0
OPENAI_API_KEY=sk-ваш-ключ
ERA_SERVER_SALT=любой-длинный-секрет
```

---

## Production — Oracle Cloud (бесплатно)

Полный гайд: [deploy/oracle-cloud/README.md](deploy/oracle-cloud/README.md)  
Чеклист: [deploy/oracle-cloud/CHECKLIST.md](deploy/oracle-cloud/CHECKLIST.md)

```powershell
.\scripts\deploy-all-oci.ps1 -ServerIp ВАШ_IP -IpOnly -OpenAiKey sk-...
```

---

## Полезные скрипты

| Скрипт | Назначение |
|---|---|
| `start-era-local.ps1 -All` | Локальный запуск |
| `smoke-test.ps1` | Проверка API и frontend |
| `deploy-all-oci.ps1` | Полный деплой на Oracle |
| `setup-github-actions.ps1` | Секреты для CI/CD |
| `verify-deployment.ps1` | Проверка production |

---

## Частые проблемы

| Проблема | Решение |
|---|---|
| Docker pipe error | `.\scripts\ensure-docker.ps1` |
| API offline (красный) | Запустите API: `uvicorn` в `backend/` |
| Generate не работает | Celery в Docker + `OPENAI_API_KEY` в `.env` |
| CORS ошибка | Добавьте origin фронтенда в `CORS_ORIGINS` |
