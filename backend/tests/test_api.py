"""HTTP integration tests for the ERA public API."""

from __future__ import annotations

import hashlib
import hmac
import json
import time

from backend.pro_service import ACTIVATION_PENDING_MESSAGE
from backend.verify_messages import VERIFY_AUTHENTIC


def test_health_exposes_operational_flags(api_client) -> None:
    response = api_client.get("/health")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert payload["standalone_mode"] is True
    assert "openai_for_pro" in payload
    assert "billing_configured" in payload
    assert "database_persistent" in payload


def test_openapi_documents_core_routes(api_client) -> None:
    response = api_client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    for route in ("/health", "/generate", "/verify", "/pro/status", "/pro/activate", "/webhooks/lemonsqueezy"):
        assert route in paths, f"missing {route}"


def test_pro_status_without_key_is_free_tier(api_client) -> None:
    response = api_client.get("/pro/status")
    assert response.status_code == 200
    payload = response.json()
    assert payload["active"] is False
    assert payload["tier"] == "free"


def test_pro_activate_unknown_email_uses_generic_message(api_client) -> None:
    response = api_client.post("/pro/activate", json={"email": "nobody@example.com"})
    assert response.status_code == 404
    assert response.json()["detail"] == ACTIVATION_PENDING_MESSAGE


def test_pro_activate_rejects_invalid_email(api_client) -> None:
    response = api_client.post("/pro/activate", json={"email": "not-an-email"})
    assert response.status_code == 422


def test_webhook_rejects_invalid_signature(api_client) -> None:
    response = api_client.post(
        "/webhooks/lemonsqueezy",
        content=b"{}",
        headers={"X-Signature": "invalid"},
    )
    assert response.status_code == 401


def test_webhook_accepts_signed_subscription_created(api_client, monkeypatch) -> None:
    secret = "pytest-webhook-secret"
    monkeypatch.setenv("LEMONSQUEEZY_WEBHOOK_SECRET", secret)
    payload = {
        "meta": {"event_name": "subscription_created"},
        "data": {
            "type": "subscriptions",
            "id": "sub-api-test-1",
            "attributes": {
                "user_email": "api-buyer@example.com",
                "status": "active",
                "renews_at": "2026-09-01T00:00:00Z",
            },
        },
    }
    body = json.dumps(payload).encode("utf-8")
    signature = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    response = api_client.post(
        "/webhooks/lemonsqueezy",
        content=body,
        headers={"X-Signature": signature, "Content-Type": "application/json"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

    activate = api_client.post("/pro/activate", json={"email": "api-buyer@example.com"})
    assert activate.status_code == 200
    api_key = activate.json()["api_key"]
    assert api_key.startswith("era_pro_")

    status = api_client.get("/pro/status", headers={"X-ERA-Pro-Key": api_key})
    assert status.status_code == 200
    assert status.json()["active"] is True
    assert status.json()["tier"] == "pro"


def test_pro_status_with_invalid_key_format_is_free_tier(api_client) -> None:
    response = api_client.get("/pro/status", headers={"X-ERA-Pro-Key": "not-a-valid-key"})
    assert response.status_code == 200
    payload = response.json()
    assert payload["active"] is False
    assert payload["tier"] == "free"


def test_pro_activation_rotates_api_key(api_client, monkeypatch) -> None:
    secret = "pytest-rotation-secret"
    monkeypatch.setenv("LEMONSQUEEZY_WEBHOOK_SECRET", secret)
    payload = {
        "meta": {"event_name": "subscription_created"},
        "data": {
            "type": "subscriptions",
            "id": "sub-rotation-test",
            "attributes": {
                "user_email": "rotate@example.com",
                "status": "active",
                "renews_at": "2026-09-01T00:00:00Z",
            },
        },
    }
    body = json.dumps(payload).encode("utf-8")
    signature = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    webhook = api_client.post(
        "/webhooks/lemonsqueezy",
        content=body,
        headers={"X-Signature": signature, "Content-Type": "application/json"},
    )
    assert webhook.status_code == 200

    first = api_client.post("/pro/activate", json={"email": "rotate@example.com"})
    second = api_client.post("/pro/activate", json={"email": "rotate@example.com"})
    assert first.status_code == 200
    assert second.status_code == 200

    first_key = first.json()["api_key"]
    second_key = second.json()["api_key"]
    assert first_key != second_key

    stale = api_client.get("/pro/status", headers={"X-ERA-Pro-Key": first_key})
    fresh = api_client.get("/pro/status", headers={"X-ERA-Pro-Key": second_key})
    assert stale.json()["active"] is False
    assert fresh.json()["active"] is True


def test_generate_returns_sanitized_completed_result(api_client) -> None:
    queued = api_client.post("/generate")
    assert queued.status_code == 202
    assert queued.json()["tier"] == "demo"
    task_id = queued.json()["task_id"]

    deadline = time.time() + 90
    result_payload = None
    while time.time() < deadline:
        status = api_client.get(f"/status/{task_id}")
        assert status.status_code == 200
        payload = status.json()
        if payload["status"] == "completed":
            result_payload = payload["result"]
            break
        if payload["status"] == "failed":
            raise AssertionError(payload.get("error"))
        time.sleep(0.5)

    assert result_payload is not None
    assert "riddle" in result_payload
    assert "image_url" in result_payload
    assert "authenticity_hash" not in result_payload
    assert "image_path" not in result_payload
    assert "image_base64" not in result_payload


def test_verify_authentic_png_returns_message_key(api_client) -> None:
    queued = api_client.post("/generate")
    task_id = queued.json()["task_id"]

    deadline = time.time() + 90
    image_url = None
    while time.time() < deadline:
        status = api_client.get(f"/status/{task_id}").json()
        if status["status"] == "completed":
            image_url = status["result"]["image_url"]
            break
        time.sleep(0.5)

    assert image_url is not None
    image = api_client.get(image_url)
    assert image.status_code == 200

    verified = api_client.post(
        "/verify",
        files={"file": ("artifact.png", image.content, "image/png")},
    )
    assert verified.status_code == 200
    payload = verified.json()
    assert payload["verified"] is True
    assert payload["message_key"] == VERIFY_AUTHENTIC
