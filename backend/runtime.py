"""Runtime mode detection for local standalone vs Docker/production."""

from __future__ import annotations

import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent


def is_vercel_runtime() -> bool:
    return bool(os.getenv("VERCEL"))


def standalone_db_path() -> Path:
    override = os.getenv("ERA_STANDALONE_DB_PATH", "").strip()
    if override:
        return Path(override)
    if is_vercel_runtime():
        return Path("/tmp/era_standalone.db")
    return PROJECT_ROOT / "backend" / "era_standalone.db"


def artifacts_dir() -> Path:
    if is_vercel_runtime():
        return Path("/tmp/era-artifacts")
    return PROJECT_ROOT / "backend" / "artifacts"


def is_standalone_mode() -> bool:
    """True when ERA runs without Docker (SQLite + in-process Celery)."""
    if is_vercel_runtime():
        return True
    return os.getenv("ERA_STANDALONE", "").strip().lower() in {"1", "true", "yes", "on"}


def has_external_database() -> bool:
    """True when DATABASE_URL points to a hosted database (e.g. Neon on Vercel)."""
    url = os.getenv("DATABASE_URL", "").strip()
    return bool(url) and not url.startswith("sqlite")


def standalone_async_database_url() -> str:
    return f"sqlite+aiosqlite:///{standalone_db_path().as_posix()}"


def standalone_sync_database_url() -> str:
    return f"sqlite:///{standalone_db_path().as_posix()}"
