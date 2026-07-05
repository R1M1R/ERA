import os


def get_cors_origins() -> list[str]:
    """Load allowed CORS origins from the environment."""
    raw = os.getenv("CORS_ORIGINS", "").strip()
    origins: list[str] = []
    if raw:
        origins.extend(origin.strip() for origin in raw.split(",") if origin.strip())

    vercel_url = os.getenv("VERCEL_URL", "").strip()
    if vercel_url:
        origins.append(f"https://{vercel_url}")

    branch_url = os.getenv("VERCEL_BRANCH_URL", "").strip()
    if branch_url:
        origins.append(f"https://{branch_url}")

    if origins:
        return list(dict.fromkeys(origins))

    return [
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:4173",
        "http://127.0.0.1:4173",
    ]
