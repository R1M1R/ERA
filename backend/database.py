"""SQLAlchemy database configuration with async (asyncpg) and sync engines."""

from __future__ import annotations

import os
from collections.abc import AsyncGenerator, Generator
from contextlib import asynccontextmanager, contextmanager

from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from backend.runtime import (
    has_external_database,
    is_standalone_mode,
    standalone_async_database_url,
    standalone_sync_database_url,
)

DEFAULT_ASYNC_DATABASE_URL = "postgresql+asyncpg://era:era_secret@localhost:5432/era_db"
DEFAULT_SYNC_DATABASE_URL = "postgresql+psycopg2://era:era_secret@localhost:5432/era_db"


def resolve_async_database_url() -> str:
    """Return the async SQLAlchemy URL used by FastAPI."""
    if is_standalone_mode():
        if has_external_database():
            url = os.getenv("DATABASE_URL", "").strip()
            if url.startswith("postgresql://"):
                return url.replace("postgresql://", "postgresql+asyncpg://", 1)
            if url.startswith("postgres://"):
                return url.replace("postgres://", "postgresql+asyncpg://", 1)
            return url
        return standalone_async_database_url()
    url = os.getenv("DATABASE_URL", DEFAULT_ASYNC_DATABASE_URL)
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+asyncpg://", 1)
    if url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql+asyncpg://", 1)
    return url


def resolve_sync_database_url() -> str:
    """Return the sync SQLAlchemy URL used by Celery workers."""
    if is_standalone_mode():
        if has_external_database():
            explicit = os.getenv("DATABASE_URL_SYNC", "").strip()
            if explicit:
                return explicit
            async_url = resolve_async_database_url()
            return async_url.replace("postgresql+asyncpg://", "postgresql+psycopg2://")
        return standalone_sync_database_url()
    explicit = os.getenv("DATABASE_URL_SYNC")
    if explicit:
        return explicit

    async_url = resolve_async_database_url()
    return async_url.replace("postgresql+asyncpg://", "postgresql+psycopg2://")


class Base(DeclarativeBase):
    """Declarative base for ORM models."""


async_engine: AsyncEngine = create_async_engine(
    resolve_async_database_url(),
    pool_pre_ping=not is_standalone_mode(),
    future=True,
)
AsyncSessionLocal = async_sessionmaker(
    bind=async_engine,
    class_=AsyncSession,
    autoflush=False,
    expire_on_commit=False,
)

sync_engine: Engine = create_engine(
    resolve_sync_database_url(),
    pool_pre_ping=not is_standalone_mode(),
    connect_args={"check_same_thread": False} if is_standalone_mode() else {},
    future=True,
)
SyncSessionLocal = sessionmaker(
    bind=sync_engine,
    autoflush=False,
    autocommit=False,
    expire_on_commit=False,
)


async def init_database() -> None:
    """Create database tables if they do not exist (async path for FastAPI)."""
    from backend.models import Artifact, ProLicense  # noqa: F401

    async with async_engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)


def init_database_sync() -> None:
    """Create database tables if they do not exist (sync path for Celery/scripts)."""
    from backend.models import Artifact, ProLicense  # noqa: F401

    Base.metadata.create_all(bind=sync_engine)


@asynccontextmanager
async def get_async_session() -> AsyncGenerator[AsyncSession, None]:
    """Provide a transactional async SQLAlchemy session scope."""
    session = AsyncSessionLocal()
    try:
        yield session
        await session.commit()
    except Exception:
        await session.rollback()
        raise
    finally:
        await session.close()


@contextmanager
def get_sync_session() -> Generator[Session, None, None]:
    """Provide a transactional sync SQLAlchemy session scope for Celery workers."""
    session = SyncSessionLocal()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
