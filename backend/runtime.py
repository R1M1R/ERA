"""Runtime mode detection for local standalone vs Docker/production."""

from __future__ import annotations

import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
STANDALONE_DB_PATH = PROJECT_ROOT / "backend" / "era_standalone.db"


def is_standalone_mode() -> bool:
    """True when ERA runs without Docker (SQLite + in-process Celery)."""
    return os.getenv("ERA_STANDALONE", "").strip().lower() in {"1", "true", "yes", "on"}


def standalone_async_database_url() -> str:
    return f"sqlite+aiosqlite:///{STANDALONE_DB_PATH.as_posix()}"


def standalone_sync_database_url() -> str:
    return f"sqlite:///{STANDALONE_DB_PATH.as_posix()}"
