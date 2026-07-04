"""Initialize or migrate the ERA database schema via SQLAlchemy metadata."""

from __future__ import annotations

import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from sqlalchemy import inspect, text

from backend.database import Base, init_database_sync, sync_engine
from backend.models import Artifact
from backend.runtime import is_standalone_mode


def migrate_schema() -> None:
    """Create the current schema and apply additive migrations."""
    inspector = inspect(sync_engine)
    if inspector.has_table("artifacts"):
        existing_columns = {column["name"] for column in inspector.get_columns("artifacts")}
        legacy_columns = {"id", "public_hash", "authenticity_hash", "image_path", "created_at", "is_solved"}
        if existing_columns == legacy_columns:
            print("Adding image_bytes column for PaaS artifact storage...")
            column_type = "BLOB" if is_standalone_mode() else "BYTEA"
            with sync_engine.begin() as connection:
                connection.execute(text(f"ALTER TABLE artifacts ADD COLUMN image_bytes {column_type}"))
        elif "image_bytes" not in existing_columns and existing_columns != legacy_columns | {"image_bytes"}:
            print("Legacy artifacts table detected — recreating schema...")
            Artifact.__table__.drop(sync_engine, checkfirst=True)

    init_database_sync()
    print("Database schema is ready.")


if __name__ == "__main__":
    migrate_schema()
