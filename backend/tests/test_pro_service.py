"""Tests for Pro license and Lemon Squeezy webhook helpers."""

from __future__ import annotations

import hashlib
import hmac
import os

from backend.email_utils import normalize_email
from backend.pro_service import (
    ACTIVE_STATUSES,
    PRO_KEY_PREFIX,
    generate_api_key,
    hash_api_key,
    parse_pro_api_key,
    handle_lemon_webhook_event,
    upsert_subscription_from_webhook,
    verify_lemon_signature,
)


def test_generate_api_key_format() -> None:
    key = generate_api_key()
    assert key.startswith(PRO_KEY_PREFIX)
    assert len(key) > 20


def test_parse_pro_api_key_rejects_invalid_values() -> None:
    assert parse_pro_api_key(None) is None
    assert parse_pro_api_key("   ") is None
    assert parse_pro_api_key("sk-not-era") is None
    assert parse_pro_api_key("era_pro_" + "x" * 200) is None
    valid = generate_api_key()
    assert parse_pro_api_key(f"  {valid}  ") == valid


def test_hash_api_key_is_stable_and_peppered() -> None:
    os.environ["ERA_SERVER_SALT"] = "pytest-pepper"
    key = generate_api_key()
    assert hash_api_key(key) == hash_api_key(key)
    assert hash_api_key(key) != hash_api_key(f"{key}x")


def test_normalize_email() -> None:
    assert normalize_email("  User@Example.COM ") == "user@example.com"
    try:
        normalize_email("not-an-email")
        raise AssertionError("expected ValueError")
    except ValueError:
        pass


def test_verify_lemon_signature() -> None:
    secret = "test-signing-secret"
    os.environ["LEMONSQUEEZY_WEBHOOK_SECRET"] = secret
    body = b'{"meta":{"event_name":"subscription_created"}}'
    signature = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()

    assert verify_lemon_signature(body, signature) is True
    assert verify_lemon_signature(body, "invalid") is False


def test_paused_subscription_is_not_active() -> None:
    assert "paused" not in ACTIVE_STATUSES


def test_subscription_webhook_roundtrip() -> None:
    payload = {
        "meta": {"event_name": "subscription_created"},
        "data": {
            "type": "subscriptions",
            "id": "sub-pytest-001",
            "attributes": {
                "user_email": "buyer@example.com",
                "status": "active",
                "renews_at": "2026-08-01T00:00:00Z",
            },
        },
    }

    created = upsert_subscription_from_webhook(payload)
    assert created is not None
    assert created.email == "buyer@example.com"
    assert created.api_key_hash is None

    updated = upsert_subscription_from_webhook(payload)
    assert updated is not None
    assert updated.api_key_hash is None

    handle_lemon_webhook_event("subscription_cancelled", payload)
    cancelled = upsert_subscription_from_webhook(
        {
            **payload,
            "data": {
                **payload["data"],
                "attributes": {"status": "cancelled", "user_email": "buyer@example.com"},
            },
        }
    )
    assert cancelled is not None
    assert cancelled.status == "cancelled"
