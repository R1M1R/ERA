# ERA → Oracle Cloud: чеклист деплоя

Отмечайте по порядку. Время: ~30–60 минут (первый раз).

---

## A. Oracle Cloud (в браузере)

- [ ] Аккаунт на [cloud.oracle.com](https://cloud.oracle.com)
- [ ] **Compute → Instances → Create**
  - [ ] Shape: **VM.Standard.A1.Flex** → 2 OCPU / 8 GB
  - [ ] Image: **Ubuntu 22.04** (aarch64)
  - [ ] Public IPv4: **включён**
  - [ ] SSH key: вставить из `.\scripts\oracle-cloud-prep.ps1`
- [ ] **Security List** → Ingress: TCP **22, 80, 443** (0.0.0.0/0)
- [ ] Записать **Public IP**: `________________`

---

## B. Windows (PowerShell, папка ERA)

- [ ] Локально протестировано:

```powershell
.\scripts\start-era-local.ps1 -All
.\scripts\smoke-test.ps1
```

- [ ] OpenAI API key готов
- [ ] Полный деплой:

```powershell
.\scripts\deploy-all-oci.ps1 -ServerIp ВАШ_IP -IpOnly -OpenAiKey sk-...
```

- [ ] Браузер: `http://ВАШ_IP/` открывается
- [ ] Генерация артефакта работает (кнопка Generate)

---

## C. GitHub Actions (опционально, для обновлений)

- [ ] **Settings → Secrets → Actions**:
  - [ ] `SSH_HOST` = Public IP
  - [ ] `SSH_USER` = `ubuntu`
  - [ ] `SSH_PRIVATE_KEY` = содержимое `~\.ssh\id_ed25519`
- [ ] Запустить: **Actions → Deploy Backend**
- [ ] Запустить: **Actions → Deploy Frontend** (`VITE_API_URL=http://ВАШ_IP`)

Подсказка:

```powershell
.\scripts\setup-github-actions.ps1 -ServerIp ВАШ_IP
```

---

## D. Домен + HTTPS (когда будет домен)

- [ ] DNS A-записи → Public IP
- [ ] Передеплой:

```powershell
.\scripts\deploy-all-oci.ps1 -ServerIp ВАШ_IP `
  -ApiDomain api.домен.com -FrontendDomain домен.com `
  -Email ваш@email.com -OpenAiKey sk-...
```

---

## Если что-то сломалось

| Симптом | Решение |
|---|---|
| SSH не подключается | Security List порт 22, правильный ключ |
| Сайт не открывается снаружи | Security List 80/443 + `sudo bash scripts/oci-open-firewall.sh` |
| API 502 | `docker compose ... logs api` на сервере |
| Generate зависает | `docker compose ... logs celery-worker` |
| CORS ошибка | `CORS_ORIGINS` в `~/ERA/.env` = URL фронтенда |

Проверка:

```powershell
.\scripts\verify-deployment.ps1 -ServerIp ВАШ_IP -IpOnly
```
