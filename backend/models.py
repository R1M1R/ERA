"""ORM models for persisted ERA artifacts."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import Boolean, DateTime, LargeBinary, String
from sqlalchemy.orm import Mapped, mapped_column

from backend.database import Base


class Artifact(Base):
    """Public artifact record stored after steganographic image generation."""

    __tablename__ = "artifacts"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    public_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    authenticity_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    image_path: Mapped[str] = mapped_column(String(512), nullable=False)
    image_bytes: Mapped[bytes | None] = mapped_column(LargeBinary, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )
    is_solved: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    def to_dict(self, *, image_url: str) -> dict[str, str | int | bool]:
        """Serialize the artifact for API responses."""
        return {
            "id": self.id,
            "public_hash": self.public_hash,
            "authenticity_hash": self.authenticity_hash,
            "image_path": self.image_path,
            "image_url": image_url,
            "created_at": self.created_at.isoformat(),
            "is_solved": self.is_solved,
        }
