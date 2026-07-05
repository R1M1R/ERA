"""Pydantic schemas for the ERA public API."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class GenerateResponse(BaseModel):
    """Response returned immediately after a generation job is queued."""

    task_id: str = Field(..., description="Celery task identifier for polling.")
    status: Literal["queued"] = "queued"
    tier: Literal["demo", "pro"] = Field(
        default="demo",
        description="Riddle source tier for this job.",
    )
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
    message_key: str | None = None
    verified: bool
    text: str | None = None
    authenticity_hash: str | None = None
    detail: str | None = None


class ProActivateRequest(BaseModel):
    """Request body for claiming a Pro API key by checkout email."""

    email: str = Field(..., min_length=3, max_length=320)

    @field_validator("email")
    @classmethod
    def validate_email(cls, value: str) -> str:
        from email_utils import normalize_email

        return normalize_email(value)


class ProActivateResponse(BaseModel):
    """Pro API key returned after email verification."""

    api_key: str
    status: str
    renews_at: str | None = None


class ProStatusResponse(BaseModel):
    """Current Pro subscription status for the provided API key."""

    active: bool
    tier: Literal["free", "pro"] = "free"
    email: str | None = None
    status: str | None = None
    renews_at: str | None = None
    openai_for_pro: bool = False
