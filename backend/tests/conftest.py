"""Shared pytest fixtures for ERA API integration tests."""

from __future__ import annotations

import asyncio
import os
import sys
from collections.abc import Iterator
from pathlib import Path

import pytest
from starlette.testclient import TestClient

PROJECT_ROOT = Path(__file__).resolve().parents[2]
BACKEND_DIR = PROJECT_ROOT / "backend"

for path in (str(PROJECT_ROOT), str(BACKEND_DIR)):
    if path not in sys.path:
        sys.path.insert(0, path)

os.environ.setdefault("ERA_STANDALONE", "true")
os.environ.setdefault("ERA_DEMO_MODE", "true")
os.environ.setdefault("ERA_SERVER_SALT", "pytest-era-salt")
for key in (
    "VERCEL",
    "VERCEL_ENV",
    "DATABASE_URL",
    "DATABASE_URL_SYNC",
    "CELERY_BROKER_URL",
    "CELERY_RESULT_BACKEND",
    "REDIS_URL",
):
    os.environ.pop(key, None)

TEST_DB_PATH = BACKEND_DIR / ".pytest_era.db"
os.environ["ERA_STANDALONE_DB_PATH"] = str(TEST_DB_PATH)


def _dispose_database_engines() -> None:
    from backend.database import async_engine, sync_engine  # noqa: E402

    sync_engine.dispose()
    asyncio.run(async_engine.dispose())


@pytest.fixture(scope="session", autouse=True)
def standalone_test_database() -> Iterator[None]:
    """Create an isolated SQLite schema once per pytest session."""
    if TEST_DB_PATH.exists():
        TEST_DB_PATH.unlink(missing_ok=True)
    from backend.database import init_database_sync  # noqa: E402

    init_database_sync()
    yield
    _dispose_database_engines()
    try:
        if TEST_DB_PATH.exists():
            TEST_DB_PATH.unlink()
    except OSError:
        pass


@pytest.fixture
def api_client() -> Iterator[TestClient]:
    """In-process FastAPI client running ERA in standalone demo mode."""
    os.chdir(BACKEND_DIR)
    from main import app  # noqa: E402

    with TestClient(app) as client:
        yield client
