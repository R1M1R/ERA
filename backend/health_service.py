"""Runtime health probes for API dependencies."""

from __future__ import annotations

import os
from typing import Any

from sqlalchemy import text

from backend.database import async_engine


async def collect_health_status() -> dict[str, Any]:
    """Check API, database, Redis, and demo-mode availability."""
    checks: dict[str, str] = {
        "api": "ok",
        "database": "unknown",
        "redis": "unknown",
    }

    try:
        async with async_engine.connect() as connection:
            await connection.execute(text("SELECT 1"))
        checks["database"] = "ok"
    except Exception:
        checks["database"] = "error"

    try:
        import redis

        redis_url = os.getenv("CELERY_BROKER_URL") or os.getenv("REDIS_URL", "redis://localhost:6379/0")
        client = redis.from_url(redis_url, socket_connect_timeout=3)
        client.ping()
        checks["redis"] = "ok"
    except Exception:
        checks["redis"] = "error"

    from backend.llm_service import is_demo_mode

    demo_mode = is_demo_mode()
    overall = "ok" if all(value == "ok" for value in checks.values()) else "degraded"

    return {
        "status": overall,
        "service": "era-api",
        "version": "0.4.0",
        "checks": checks,
        "demo_mode": demo_mode,
        "openai_configured": not demo_mode,
    }
