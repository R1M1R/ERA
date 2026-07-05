"""Pro license management and Lemon Squeezy webhook handling."""

from __future__ import annotations

import hashlib
import hmac
import logging
import os
import re
import secrets
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import select

from backend.database import get_async_session, get_sync_session, init_database_sync
from backend.llm_service import is_openai_configured
from backend.models import ProLicense

logger = logging.getLogger(__name__)

EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
ACTIVE_STATUSES = frozenset({"active", "on_trial", "paused"})


def _ensure_tables() -> None:
    from backend.models import Artifact, ProLicense  # noqa: F401

    init_database_sync()


def generate_api_key() -> str:
    return f"era_pro_{secrets.token_urlsafe(24)}"


def normalize_email(email: str) -> str:
    """Normalize and validate a checkout email address."""
    normalized = email.strip().lower()
    if not normalized or not EMAIL_PATTERN.fullmatch(normalized):
        raise ValueError("A valid email address is required.")
    return normalized


def _parse_datetime(value: str | None) -> datetime | None:
    if not value:
        return None
    normalized = value.replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(normalized)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=UTC)
    return parsed.astimezone(UTC)


def _mask_email(email: str) -> str:
    local, _, domain = email.partition("@")
    if not domain:
        return "***"
    if len(local) <= 2:
        return f"{local[0]}***@{domain}"
    return f"{local[0]}***{local[-1]}@{domain}"


def _license_is_active(license_row: ProLicense) -> bool:
    if license_row.status not in ACTIVE_STATUSES:
        return False
    if license_row.renews_at:
        renews_at = license_row.renews_at
        if renews_at.tzinfo is None:
            renews_at = renews_at.replace(tzinfo=UTC)
        if renews_at < datetime.now(UTC):
            return False
    return True


async def get_license_by_api_key(api_key: str) -> ProLicense | None:
    _ensure_tables()
    normalized = api_key.strip()
    if not normalized:
        return None

    async with get_async_session() as session:
        result = await session.execute(select(ProLicense).where(ProLicense.api_key == normalized))
        return result.scalar_one_or_none()


async def is_pro_license_active(api_key: str) -> bool:
    """Return True when the API key belongs to an active Pro subscription."""
    license_row = await get_license_by_api_key(api_key)
    if license_row is None:
        return False
    return _license_is_active(license_row)


async def should_use_pro_llm(api_key: str | None) -> bool:
    """Return True when generation should call OpenAI for a paying subscriber."""
    if not api_key or not is_openai_configured():
        return False
    return await is_pro_license_active(api_key)


async def get_pro_status(api_key: str | None) -> dict[str, Any]:
    openai_for_pro = is_openai_configured()
    if not api_key:
        return {"active": False, "tier": "free", "openai_for_pro": openai_for_pro}

    license_row = await get_license_by_api_key(api_key)
    if license_row is None or not _license_is_active(license_row):
        return {"active": False, "tier": "free", "openai_for_pro": openai_for_pro}

    return {
        "active": True,
        "tier": "pro",
        "email": _mask_email(license_row.email),
        "status": license_row.status,
        "renews_at": license_row.renews_at.isoformat() if license_row.renews_at else None,
        "openai_for_pro": openai_for_pro,
    }


async def activate_pro_by_email(email: str) -> dict[str, Any]:
    _ensure_tables()
    normalized = normalize_email(email)

    async with get_async_session() as session:
        result = await session.execute(
            select(ProLicense)
            .where(ProLicense.email == normalized)
            .order_by(ProLicense.updated_at.desc(), ProLicense.id.desc())
        )
        license_row = result.scalars().first()

    if license_row is None:
        raise LookupError("No Pro subscription found for this email yet. Wait a minute after checkout.")

    if not _license_is_active(license_row):
        raise PermissionError("Pro subscription is not active. Renew or contact support.")

    return {
        "api_key": license_row.api_key,
        "status": license_row.status,
        "renews_at": license_row.renews_at.isoformat() if license_row.renews_at else None,
    }


def verify_lemon_signature(body: bytes, signature: str | None) -> bool:
    secret = os.getenv("LEMONSQUEEZY_WEBHOOK_SECRET", "").strip()
    if not secret or not signature:
        return False
    digest = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(digest, signature)


def upsert_subscription_from_webhook(payload: dict[str, Any]) -> ProLicense | None:
    """Create or update a Pro license from a Lemon Squeezy subscription payload."""
    _ensure_tables()

    data = payload.get("data") or {}
    if data.get("type") != "subscriptions":
        return None

    attributes = data.get("attributes") or {}
    subscription_id = str(data.get("id") or "").strip()
    email = str(attributes.get("user_email") or "").strip().lower()
    status = str(attributes.get("status") or "active").strip().lower()
    renews_at = _parse_datetime(attributes.get("renews_at"))

    if not subscription_id or not email:
        logger.warning("Lemon Squeezy webhook missing subscription id or email")
        return None

    with get_sync_session() as session:
        result = session.execute(
            select(ProLicense).where(ProLicense.lemon_subscription_id == subscription_id)
        )
        license_row = result.scalar_one_or_none()

        if license_row is None:
            license_row = ProLicense(
                email=email,
                api_key=generate_api_key(),
                lemon_subscription_id=subscription_id,
                status=status,
                renews_at=renews_at,
            )
            session.add(license_row)
            logger.info("Created Pro license for %s (subscription %s)", _mask_email(email), subscription_id)
        else:
            license_row.email = email
            license_row.status = status
            license_row.renews_at = renews_at
            license_row.updated_at = datetime.now(UTC)
            logger.info("Updated Pro license for %s (status=%s)", _mask_email(email), status)

        session.flush()
        session.refresh(license_row)
        return license_row


def handle_lemon_webhook_event(event_name: str, payload: dict[str, Any]) -> dict[str, str]:
    """Dispatch Lemon Squeezy webhook events."""
    if event_name in {
        "subscription_created",
        "subscription_updated",
        "subscription_resumed",
        "subscription_payment_success",
    }:
        license_row = upsert_subscription_from_webhook(payload)
        if license_row is None:
            return {"status": "ignored"}
        return {"status": "ok"}

    if event_name in {"subscription_cancelled", "subscription_expired", "subscription_paused"}:
        data = payload.get("data") or {}
        subscription_id = str(data.get("id") or "").strip()
        attributes = data.get("attributes") or {}
        status = str(attributes.get("status") or "cancelled").strip().lower()

        if not subscription_id:
            return {"status": "ignored"}

        with get_sync_session() as session:
            result = session.execute(
                select(ProLicense).where(ProLicense.lemon_subscription_id == subscription_id)
            )
            license_row = result.scalar_one_or_none()
            if license_row is None:
                return {"status": "ignored"}
            license_row.status = status
            license_row.updated_at = datetime.now(UTC)
            logger.info("Deactivated Pro license subscription=%s status=%s", subscription_id, status)

        return {"status": "ok"}

    return {"status": "ignored", "event": event_name}
