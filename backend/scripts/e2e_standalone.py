"""End-to-end API test for ERA (standalone or production PaaS)."""

from __future__ import annotations

import argparse
import os
import sys
import time
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from backend.verify_messages import VERIFY_AUTHENTIC


def configure_standalone_env() -> None:
    os.environ["ERA_STANDALONE"] = "true"
    os.environ["ERA_DEMO_MODE"] = "true"
    os.environ.setdefault("ERA_SERVER_SALT", "e2e-standalone-salt")
    for key in (
        "VERCEL",
        "VERCEL_ENV",
        "DATABASE_URL",
        "DATABASE_URL_SYNC",
        "CELERY_BROKER_URL",
        "CELERY_RESULT_BACKEND",
        "REDIS_URL",
    ):
        os.environ.pop(key, None)
    db_path = PROJECT_ROOT / "backend" / ".e2e_standalone.db"
    os.environ["ERA_STANDALONE_DB_PATH"] = str(db_path)
    if db_path.exists():
        db_path.unlink()


def _url(base_url: str, path: str) -> str:
    return path if not base_url else f"{base_url}{path}"


def _request(client, method: str, path: str, base_url: str, **kwargs):
    request_kwargs = dict(kwargs)
    if not base_url:
        request_kwargs.pop("timeout", None)
    return client.request(method, _url(base_url, path), **request_kwargs)


def _wait_for_health(client, base_url: str, timeout_sec: int) -> dict:
    deadline = time.time() + timeout_sec
    last_error: Exception | None = None
    while time.time() < deadline:
        try:
            response = _request(client, "GET", "/health", base_url, timeout=15)
            if response.status_code == 200:
                payload = response.json()
                if payload.get("status") == "ok":
                    return payload
        except Exception as exc:  # noqa: BLE001
            last_error = exc
        time.sleep(2)
    raise RuntimeError(f"API health check failed: {last_error}")


def run_e2e(client, *, base_url: str = "", production: bool = False) -> None:
    health_timeout = 120 if production else 30
    health = _wait_for_health(client, base_url, timeout_sec=health_timeout)

    if production:
        assert health.get("status") == "ok", health
        print(
            f"  health ... OK (demo={health.get('demo_mode')}, "
            f"db={health.get('checks', {}).get('database')}, "
            f"redis={health.get('checks', {}).get('redis')})"
        )
    else:
        assert health.get("standalone_mode") is True, health
        assert health.get("demo_mode") is True, health
        print("  health ... OK")

    generate_timeout = 180 if production else 120
    generate_response = _request(client, "POST", "/generate", base_url, timeout=generate_timeout)
    assert generate_response.status_code == 202, generate_response.text
    task_id = generate_response.json()["task_id"]
    print(f"  generate ... OK (task_id={task_id})")

    status_payload = None
    poll_deadline = time.time() + (180 if production else 90)
    while time.time() < poll_deadline:
        status_response = _request(client, "GET", f"/status/{task_id}", base_url, timeout=30)
        assert status_response.status_code == 200, status_response.text
        status_payload = status_response.json()
        if status_payload["status"] in {"completed", "failed"}:
            break
        time.sleep(2)

    assert status_payload is not None
    assert status_payload["status"] == "completed", status_payload.get("error")
    print("  pipeline ... OK")

    gallery_response = _request(client, "GET", "/artifacts?page=1&page_size=1", base_url, timeout=30)
    assert gallery_response.status_code == 200, gallery_response.text
    gallery = gallery_response.json()

    assert gallery["total"] >= 1, gallery
    public_hash = gallery["items"][0]["public_hash"]
    print(f"  gallery ... OK (total={gallery['total']})")

    image_response = _request(client, "GET", f"/artifacts/{public_hash}/image", base_url, timeout=60)
    assert image_response.status_code == 200, image_response.text
    image_bytes = image_response.content

    assert len(image_bytes) > 1000, len(image_bytes)
    print(f"  image ... OK ({len(image_bytes)} bytes)")

    verify_response = _request(
        client,
        "POST",
        "/verify",
        base_url,
        files={"file": ("artifact.png", image_bytes, "image/png")},
        timeout=30,
    )
    assert verify_response.status_code == 200, verify_response.text
    verify = verify_response.json()

    assert verify.get("verified") is True, verify
    assert verify.get("message_key") == VERIFY_AUTHENTIC
    print("  verify ... OK")

    pro_status = _request(client, "GET", "/pro/status", base_url, timeout=15)
    assert pro_status.status_code == 200, pro_status.text
    assert pro_status.json().get("tier") == "free"
    print("  pro/status ... OK")

    activate = _request(
        client,
        "POST",
        "/pro/activate",
        base_url,
        json={"email": "missing@example.com"},
        timeout=15,
    )
    assert activate.status_code == 404, activate.text
    print("  pro/activate ... OK")

    if status_payload.get("result"):
        result = status_payload["result"]
        assert "authenticity_hash" not in result, result
        assert "image_path" not in result, result
        print("  sanitized status ... OK")

    label = "production" if production else "standalone"
    print("")
    print(f"[ERA] E2E {label} test PASSED - product is fully working.")


def main() -> None:
    parser = argparse.ArgumentParser(description="ERA end-to-end API test")
    parser.add_argument(
        "--api-url",
        default="",
        help="Running API base URL. If omitted, uses in-process TestClient (standalone).",
    )
    parser.add_argument(
        "--production",
        action="store_true",
        help="Production/PaaS mode: longer timeouts, no standalone assertions.",
    )
    args = parser.parse_args()

    label = "production" if args.production else "standalone"
    print(f"[ERA] E2E {label} test")

    if args.api_url:
        import httpx

        with httpx.Client() as client:
            run_e2e(client, base_url=args.api_url.rstrip("/"), production=args.production)
    else:
        if args.production:
            raise SystemExit("--production requires --api-url")

        configure_standalone_env()
        from starlette.testclient import TestClient

        backend_dir = PROJECT_ROOT / "backend"
        if str(backend_dir) not in sys.path:
            sys.path.insert(0, str(backend_dir))
        os.chdir(backend_dir)
        from main import app  # noqa: E402

        with TestClient(app) as client:
            run_e2e(client, production=False)


if __name__ == "__main__":
    main()
