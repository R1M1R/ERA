"""Pydantic schemas for the ERA public API."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field


class GenerateResponse(BaseModel):
    """Response returned immediately after a generation job is queued."""

    task_id: str = Field(..., description="Celery task identifier for polling.")
    status: Literal["queued"] = "queued"
    mode: Literal["autonomous"] = Field(
        default="autonomous",
        description="Generation mode — riddles are produced by the LLM orchestrator.",
    )


class TaskStatusResponse(BaseModel):
    """Normalized task status payload for clients."""

    task_id: str
    status: Literal["queued", "running", "completed", "failed"]
    step: str | None = None
    result: dict[str, Any] | None = None
    error: str | None = None


class ArtifactItem(BaseModel):
    """Public artifact representation for gallery views."""

    id: int
    public_hash: str
    image_url: str
    created_at: str
    is_solved: bool


class ArtifactListResponse(BaseModel):
    """Paginated artifact list returned by ``GET /artifacts``."""

    items: list[ArtifactItem]
    total: int
    page: int
    page_size: int
    pages: int


class VerifyResponse(BaseModel):
    """Result of proof-of-authenticity verification."""

    status: Literal["authentic", "fake"]
    message: str
    verified: bool
    text: str | None = None
    authenticity_hash: str | None = None
    detail: str | None = None
