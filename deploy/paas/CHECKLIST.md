# ERA PaaS Deploy Checklist

## 1. Neon (PostgreSQL)

- [ ] Account: [neon.tech](https://neon.tech)
- [ ] Project `era` created
- [ ] Connection string copied (pooled)
- [ ] `DATABASE_URL` = Neon URL
- [ ] `DATABASE_URL_SYNC` = same Neon URL

## 2. Upstash (Redis)

- [ ] Account: [upstash.com](https://upstash.com)
- [ ] Redis database created (Global region)
- [ ] TLS URL copied (`rediss://...`)
- [ ] `REDIS_URL` = Upstash TLS URL
- [ ] `CELERY_BROKER_URL` = same
- [ ] `CELERY_RESULT_BACKEND` = same

## 3. Render (Backend)

- [ ] Account: [render.com](https://render.com)
- [ ] **New → Blueprint** → connect `R1M1R/ERA`
- [ ] Fill env vars from `.env.paas.example`
- [ ] `OPENAI_API_KEY` set on **both** `era-api` and `era-celery`
- [ ] Deploy succeeded
- [ ] API URL: `https://era-api.onrender.com` (or your name)
- [ ] Health: `curl https://YOUR-API.onrender.com/health`

## 4. Vercel (Frontend)

- [ ] Account: [vercel.com](https://vercel.com)
- [ ] Import `R1M1R/ERA`, root directory: `frontend`
- [ ] Env: `VITE_API_URL=https://YOUR-API.onrender.com`
- [ ] Deploy succeeded
- [ ] Frontend URL: `https://your-project.vercel.app`

## 5. CORS (final step)

- [ ] Render `era-api` → `CORS_ORIGINS=https://your-project.vercel.app`
- [ ] Redeploy `era-api`

## 6. Smoke test

- [ ] Frontend shows **API online** (green dot)
- [ ] Click **Generate** → task completes
- [ ] Gallery shows new artifact
- [ ] Upload image in Decoder → verify works

```powershell
.\scripts\verify-paas.ps1 -ApiUrl https://YOUR-API.onrender.com
```

## Troubleshooting

| Issue | Fix |
|---|---|
| Cold start 30-60s | Normal on Render free tier |
| Generate stuck | Check `era-celery` logs on Render |
| CORS error | Exact Vercel URL in `CORS_ORIGINS` |
| Redis SSL | Use `rediss://` from Upstash |
