# ERA — Steganographic Historical Artifacts

[![CI](https://github.com/R1M1R/ERA/actions/workflows/ci.yml/badge.svg)](https://github.com/R1M1R/ERA/actions/workflows/ci.yml)
[![Cloud health](https://github.com/R1M1R/ERA/actions/workflows/cloud-health.yml/badge.svg)](https://github.com/R1M1R/ERA/actions/workflows/cloud-health.yml)

International SaaS: AI historical riddles sealed in procedural PNG artifacts via LSB steganography — generate, browse the gallery, verify authenticity on the server.

## Links

| | |
|---|---|
| **Live app** | **https://frontend-flax-two-11q4abvz2o.vercel.app** |
| **Source code** | **https://github.com/R1M1R/ERA** |

## Features

- **Generate** — AI crafts a historical riddle and hides it inside a PNG
- **Gallery** — public archive of artifacts with download and preview
- **Verify** — server-side authenticity check (SHA seal + LSB decode)
- **Languages** — English and Russian (auto-detected)

## Plans

| Tier | Price | Includes |
|------|-------|----------|
| **Free** | $0 | Demo AI riddles, gallery, verify |
| **Pro** | $12/mo | Real GPT riddles, commercial license, priority queue |
| **Enterprise** | Custom | API access, white-label, SLA |

Open the live app → section **Pricing** → **Upgrade to Pro** → activate in **Pro** with your checkout email.

## API

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/generate` | Start artifact generation (`X-ERA-Pro-Key` for Pro tier) |
| `GET` | `/status/{id}` | Poll task status |
| `GET` | `/artifacts` | Paginated gallery |
| `POST` | `/verify` | Verify uploaded PNG |
| `GET` | `/health` | Health probe |
| `GET` | `/pro/status` | Check Pro API key |
| `POST` | `/pro/activate` | Claim Pro key by checkout email |
| `POST` | `/webhooks/lemonsqueezy` | Lemon Squeezy subscription webhook |

## Stack

React · Vite · TypeScript · FastAPI · Celery · SQLite / PostgreSQL · OpenAI (optional)

## Development

```bash
# Full quality gate (pytest + lint + build)
make test

# Local standalone API + frontend
make dev-api      # terminal 1
make dev-frontend # terminal 2
```

OpenAPI schema: `GET /openapi.json` on the running API.

## Security

See [SECURITY.md](SECURITY.md) for secrets, Pro key handling, rate limits, and webhook verification.

## License

Private project — all rights reserved.
