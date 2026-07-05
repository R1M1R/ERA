"""Sanitize internal Celery payloads before returning them to API clients."""

from __future__ import annotations

from typing import Any


def sanitize_task_result(result: dict[str, Any] | None) -> dict[str, Any] | None:
    """Strip sensitive or redundant fields from a completed generation result."""
    if not result:
        return None

    db_record = result.get("database_record")
    public_record: dict[str, Any] | None = None
    if isinstance(db_record, dict):
        public_record = {
            "public_hash": db_record.get("public_hash"),
            "image_url": db_record.get("image_url"),
        }

    return {
        "task_id": result.get("task_id"),
        "status": result.get("status", "completed"),
        "riddle": result.get("riddle"),
        "answer": result.get("answer"),
        "image_url": public_record.get("image_url") if public_record else None,
        "public_hash": public_record.get("public_hash") if public_record else None,
        "database_record": public_record,
    }
