"""Persistence helpers for artifact records."""

from __future__ import annotations

import logging
import math
import secrets
from pathlib import Path
from typing import Any

from sqlalchemy import func, select

from backend.database import get_async_session, get_sync_session, init_database_sync
from backend.models import Artifact

logger = logging.getLogger(__name__)


def _build_image_url(public_hash: str) -> str:
    return f"/artifacts/{public_hash}/image"


def ensure_database_ready() -> None:
    """Initialize database schema if required tables are missing."""
    init_database_sync()


def save_artifact(*, image_path: str, authenticity_hash: str) -> dict[str, Any]:
    """Persist a generated artifact after image encoding completes."""
    ensure_database_ready()
    public_hash = secrets.token_hex(16)

    with get_sync_session() as session:
        record = Artifact(
            public_hash=public_hash,
            authenticity_hash=authenticity_hash,
            image_path=str(Path(image_path).resolve()),
            is_solved=False,
        )
        session.add(record)
        session.flush()
        logger.info(
            "Saved artifact id=%s public_hash=%s authenticity_hash=%s",
            record.id,
            record.public_hash,
            record.authenticity_hash,
        )
        return record.to_dict(image_url=_build_image_url(record.public_hash))


async def list_artifacts(*, page: int, page_size: int) -> dict[str, Any]:
    """Return a paginated list of the most recent artifacts."""
    page = max(page, 1)
    page_size = min(max(page_size, 1), 100)
    offset = (page - 1) * page_size

    async with get_async_session() as session:
        total = await session.scalar(select(func.count()).select_from(Artifact)) or 0
        result = await session.execute(
            select(Artifact)
            .order_by(Artifact.created_at.desc(), Artifact.id.desc())
            .offset(offset)
            .limit(page_size)
        )
        items = [
            artifact.to_dict(image_url=_build_image_url(artifact.public_hash))
            for artifact in result.scalars().all()
        ]

    pages = math.ceil(total / page_size) if total else 0
    return {
        "items": items,
        "total": total,
        "page": page,
        "page_size": page_size,
        "pages": pages,
    }


async def get_artifact_by_public_hash(public_hash: str) -> Artifact | None:
    """Fetch a single artifact by its public hash."""
    async with get_async_session() as session:
        result = await session.execute(
            select(Artifact).where(Artifact.public_hash == public_hash)
        )
        return result.scalar_one_or_none()


async def get_artifact_by_authenticity_hash(authenticity_hash: str) -> Artifact | None:
    """Fetch a single artifact by its proof-of-authenticity hash."""
    async with get_async_session() as session:
        result = await session.execute(
            select(Artifact).where(Artifact.authenticity_hash == authenticity_hash.lower())
        )
        return result.scalar_one_or_none()
