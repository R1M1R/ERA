"""Unit tests for Pro license and Lemon Squeezy webhook helpers."""

from __future__ import annotations

import hashlib
import hmac
import os
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

os.environ.setdefault("ERA_STANDALONE", "true")
os.environ.setdefault("ERA_DEMO_MODE", "true")
os.environ.setdefault("ERA_SERVER_SALT", "pro-service-test-salt")

from backend.email_utils import normalize_email  # noqa: E402
from backend.pro_service import (  # noqa: E402
    ACTIVE_STATUSES,
    generate_api_key,
    handle_lemon_webhook_event,
    upsert_subscription_from_webhook,
    verify_lemon_signature,
)


def test_generate_api_key_format() -> None:
    key = generate_api_key()
    assert key.startswith("era_pro_")
    assert len(key) > 20


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
    assert verify_lemon_signature(body, None) is False


def test_paused_subscription_is_not_active() -> None:
    assert "paused" not in ACTIVE_STATUSES


def test_subscription_webhook_roundtrip() -> None:
    payload = {
        "meta": {"event_name": "subscription_created"},
        "data": {
            "type": "subscriptions",
            "id": "sub-test-001",
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
    assert created.status == "active"
    first_key = created.api_key

    updated = upsert_subscription_from_webhook(payload)
    assert updated is not None
    assert updated.api_key == first_key

    paused_payload = {
        "meta": {"event_name": "subscription_paused"},
        "data": {
            "type": "subscriptions",
            "id": "sub-test-001",
            "attributes": {"status": "paused"},
        },
    }
    handle_lemon_webhook_event("subscription_paused", paused_payload)
    paused = upsert_subscription_from_webhook(paused_payload)
    assert paused is not None
    assert paused.status == "paused"

    result = handle_lemon_webhook_event("subscription_cancelled", payload)
    assert result["status"] == "ok"


def main() -> None:
    test_generate_api_key_format()
    test_normalize_email()
    test_verify_lemon_signature()
    test_paused_subscription_is_not_active()
    test_subscription_webhook_roundtrip()
    print("pro_service tests ok")


if __name__ == "__main__":
    main()
