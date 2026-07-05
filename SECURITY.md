# Security

ERA follows common SaaS security practices for a public API with optional paid subscriptions.

## Secrets and configuration

| Variable | Purpose |
|----------|---------|
| `ERA_SERVER_SALT` | Pepper for authenticity hashes and Pro API key hashing (**required in production**) |
| `LEMONSQUEEZY_WEBHOOK_SECRET` | HMAC verification for billing webhooks |
| `OPENAI_API_KEY` | Optional; enables real GPT riddles for active Pro users |
| `DATABASE_URL` | PostgreSQL (e.g. Neon) for persistent Pro licenses on serverless |

Never commit `.env`, `.secrets.local`, or production keys to git.

## Pro API keys

- Keys are issued only after email activation against an active Lemon Squeezy subscription.
- Only a **SHA-256 hash** (peppered with `ERA_SERVER_SALT`) is stored in the database — never the plaintext key.
- Re-activation **rotates** the key; previous keys stop working immediately.
- Keys must match the `era_pro_` prefix and are rejected before any database lookup when malformed.

## API hardening

- Rate limits on `/generate`, `/verify`, and `/pro/activate`
- 10 MB cap on `/verify` uploads
- Generic activation errors to prevent email enumeration
- Public `/status` responses omit `authenticity_hash`, `image_path`, and `image_base64`
- Lemon Squeezy webhooks require a valid `X-Signature` HMAC
- CORS runs with `allow_credentials: false`
- Every API response includes an `X-Request-ID` header for tracing
- Security headers via `vercel.json` (`X-Content-Type-Options`, `Referrer-Policy`, `X-Frame-Options`, `Permissions-Policy`, `HSTS`)

## Reporting issues

For security concerns related to this repository, open a private issue or contact the repository owner via GitHub.

## Dependency updates

Dependabot is enabled for npm and pip. CI runs `pytest`, lint, build, and live health checks on each push to `main`.
