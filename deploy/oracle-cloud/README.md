# ERA на Oracle Cloud Always Free

Пошаговый деплой backend + frontend на **бесплатный** VPS Oracle Cloud (Ampere A1 ARM).

| Параметр | Рекомендация |
|---|---|
| Shape | **VM.Standard.A1.Flex** (не E2.1.Micro — 1 GB мало) |
| CPU / RAM | **2 OCPU / 8–12 GB** (из лимита 4 OCPU / 24 GB) |
| OS | Ubuntu 22.04 **aarch64** |
| Стоимость | $0 / месяц (Always Free, не trial) |

Стек ERA (PostgreSQL + Redis + FastAPI + Celery) укладывается в 2–3 GB RAM. Остальное — запас под пики и Nginx.

---

## Быстрый старт с Windows

Если вы работаете с Windows (рекомендуется):

```powershell
# 1. Подготовка: SSH-ключ, .env, инструкции для OCI Console
.\scripts\oracle-cloud-prep.ps1

# 2. После создания VM и получения Public IP — загрузка и деплой одной командой:
.\scripts\upload-to-oci.ps1 -ServerIp ВАШ_IP -RunBootstrap

# Без домена (тест по IP):
.\scripts\oracle-cloud-prep.ps1 -UseIpOnly -ServerIp ВАШ_IP
.\scripts\upload-to-oci.ps1 -ServerIp ВАШ_IP -RunBootstrap
```

С доменом и HTTPS (после DNS):

```powershell
.\scripts\upload-to-oci.ps1 -ServerIp ВАШ_IP -RunBootstrap -WithNginx `
  -ApiDomain api.ваш-домен.com -FrontendDomain ваш-домен.com -Email ваш@email.com
```

---

## Часть 1. Создать аккаунт и VM в OCI

### 1.1 Регистрация

1. Откройте [cloud.oracle.com](https://cloud.oracle.com)
2. **Sign Up** — нужна карта для верификации, Always Free **не списывает** деньги при соблюдении лимитов
3. Выберите **Home Region** (сменить потом нельзя) — предпочтительно ближайший к вам

### 1.2 Создать инстанс

**Compute → Instances → Create instance**

| Поле | Значение |
|---|---|
| Name | `era-prod` |
| Image | **Ubuntu 22.04** (aarch64 / ARM) |
| Shape | **Change shape → Ampere → VM.Standard.A1.Flex** |
| OCPU | `2` |
| Memory (GB) | `8` или `12` |
| Networking | Public subnet, **Assign public IPv4** ✓ |
| SSH keys | Вставьте ваш **публичный** ключ (`~/.ssh/id_rsa.pub`) |

Нажмите **Create**. Дождитесь состояния **Running**. Запишите **Public IP**.

> **Нет доступных A1?** В некоторых регионах ARM-инстансы в дефиците. Попробуйте другой Availability Domain или повторите позже. E2.1.Micro (AMD, 1 GB) для ERA **не подходит**.

### 1.3 Security List — открыть порты

**Networking → Virtual Cloud Networks → ваша VCN → Security Lists → Default Security List**

Добавьте **Ingress Rules**:

| Source CIDR | Protocol | Dest Port | Описание |
|---|---|---|---|
| `0.0.0.0/0` | TCP | 22 | SSH |
| `0.0.0.0/0` | TCP | 80 | HTTP |
| `0.0.0.0/0` | TCP | 443 | HTTPS |

Без этого Nginx и Certbot снаружи не заработают.

### 1.4 Подключиться по SSH

```bash
ssh ubuntu@ВАШ_PUBLIC_IP
```

Пользователь по умолчанию на Ubuntu в OCI — `ubuntu`.

---

## Часть 2. Подготовить `.env` на Windows

На локальной машине (в папке ERA):

```powershell
.\scripts\generate-prod-env.ps1 `
  -ApiDomain api.ваш-домен.com `
  -FrontendDomain ваш-домен.com `
  -OpenAiKey sk-ВАШ_OPENAI_KEY
```

Скопируйте файл на сервер:

```powershell
scp .env.production.generated ubuntu@ВАШ_PUBLIC_IP:~/ERA.env
```

На сервере:

```bash
mkdir -p ~/ERA
mv ~/ERA.env ~/ERA/.env
chmod 600 ~/ERA/.env
```

> **Без домена?** Можно начать с IP: `CORS_ORIGINS=http://ВАШ_IP` и позже добавить домен. Для HTTPS всё равно понадобится домен (Let's Encrypt не выдаёт сертификаты на голый IP).

---

## Часть 3. Bootstrap на сервере (одна команда)

```bash
git clone https://github.com/R1M1R/ERA.git ~/ERA
cd ~/ERA
# если .env ещё не на месте — скопируйте с локальной машины (см. выше)

bash scripts/oracle-cloud-bootstrap.sh
```

Скрипт автоматически:
- откроет **iptables** (специфика OCI — без этого 80/443 блокируются на самой VM)
- добавит **2 GB swap**
- установит **Docker**
- запустит backend с **OCI-профилем** (2 Gunicorn worker, Celery concurrency 1)
- дождётся `/health`

Проверка:

```bash
curl http://127.0.0.1:8000/health
```

---

## Часть 4. Домен и HTTPS (Nginx + Let's Encrypt)

### 4.1 DNS

У регистратора домена создайте A-записи на **Public IP** инстанса:

| Запись | Тип | Значение |
|---|---|---|
| `api.ваш-домен.com` | A | `ВАШ_PUBLIC_IP` |
| `ваш-домен.com` | A | `ВАШ_PUBLIC_IP` |
| `www.ваш-домен.com` | A | `ВАШ_PUBLIC_IP` |

Подождите 5–30 минут распространения DNS.

### 4.2 Nginx + TLS

```bash
cd ~/ERA
sudo bash scripts/setup-nginx.sh \
  --api-domain api.ваш-домен.com \
  --frontend-domain ваш-домен.com \
  --email ваш@email.com
```

Обновите `CORS_ORIGINS` в `~/ERA/.env` и перезапустите API:

```bash
nano ~/ERA/.env
# CORS_ORIGINS=https://ваш-домен.com,https://www.ваш-домен.com

docker compose --env-file .env \
  -f backend/production.docker-compose.yml \
  -f deploy/oracle-cloud/compose.override.yml \
  up -d api
```

### 4.3 Frontend

**Вариант A — GitHub Actions** (рекомендуется)

В [GitHub Secrets](https://github.com/R1M1R/ERA/settings/secrets/actions): `SSH_HOST`, `SSH_USER`, `SSH_PRIVATE_KEY`

**Actions → Deploy Frontend** → `VITE_API_URL=https://api.ваш-домен.com`

**Вариант B — Vercel (бесплатно)**

1. Импортируйте репозиторий в [vercel.com](https://vercel.com)
2. Root Directory: `frontend`
3. Env: `VITE_API_URL=https://api.ваш-домен.com`
4. Обновите `CORS_ORIGINS` на URL Vercel (`https://ваш-проект.vercel.app`)

**Вариант C — тот же OCI сервер**

```bash
cd ~/ERA/frontend
npm ci
VITE_API_URL=https://api.ваш-домен.com npm run build
sudo rsync -av dist/ /var/www/era-frontend/
```

---

## Часть 5. Авто-деплой backend

После первичной настройки — обновления через GitHub:

**Actions → Deploy Backend → Run workflow**

Workflow выполнит `git pull` и `docker compose up -d --build` на `~/ERA`.

Для OCI-профиля вручную используйте:

```bash
docker compose --env-file .env \
  -f backend/production.docker-compose.yml \
  -f deploy/oracle-cloud/compose.override.yml \
  up -d --build
```

---

## Часть 6. Полезные команды

```bash
# Статус контейнеров
docker compose --env-file ~/ERA/.env \
  -f ~/ERA/backend/production.docker-compose.yml \
  -f ~/ERA/deploy/oracle-cloud/compose.override.yml ps

# Логи API
docker compose --env-file ~/ERA/.env \
  -f ~/ERA/backend/production.docker-compose.yml logs -f api

# Логи Celery (генерация артефактов)
docker compose --env-file ~/ERA/.env \
  -f ~/ERA/backend/production.docker-compose.yml logs -f celery-worker

# Перезапуск после сбоя
docker compose --env-file ~/ERA/.env \
  -f ~/ERA/backend/production.docker-compose.yml \
  -f ~/ERA/deploy/oracle-cloud/compose.override.yml restart
```

---

## Troubleshooting (OCI)

### Сайт не открывается снаружи, но `curl localhost` работает

1. Проверьте **Security List** (порты 80/443)
2. Переоткройте iptables:

```bash
sudo bash ~/ERA/scripts/oci-open-firewall.sh
```

### `docker: permission denied`

```bash
sudo usermod -aG docker $USER
# выйти из SSH и зайти снова
```

### ARM / образы Docker

Все образы ERA (`python:3.12-slim`, `postgres:16-alpine`, `redis:7-alpine`) поддерживают **linux/arm64**. Сборка на Ampere A1 проходит нативно.

### Не хватает RAM

- Увеличьте shape до 12 GB (в пределах Always Free)
- Убедитесь, что swap создан (`swapon --show`)
- Используйте `deploy/oracle-cloud/compose.override.yml`

### Certbot не выдаёт сертификат

- DNS A-записи должны указывать на Public IP
- Порт 80 должен быть доступен с интернета
- Проверьте: `curl -I http://api.ваш-домен.com/health`

---

## Архитектура на OCI

```text
Internet
   │
   ├─ ваш-домен.com ──► Nginx :443 ──► /var/www/era-frontend (React SPA)
   │
   └─ api.ваш-домен.com ──► Nginx :443 ──► era-api (127.0.0.1:8000)
                                          │
                                          ├── postgres
                                          ├── redis
                                          └── celery-worker
```

**Always Free лимиты (напоминание):**
- До 4 OCPU + 24 GB RAM (A1 Flex, суммарно по инстансам)
- 200 GB block storage
- 10 TB исходящего трафика / месяц

Для ERA одного инстанса 2 OCPU / 8 GB более чем достаточно.
