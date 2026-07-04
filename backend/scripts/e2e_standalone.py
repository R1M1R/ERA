"""End-to-end test for ERA standalone mode (SQLite + in-process Celery)."""

from __future__ import annotations

import argparse
import os
import sys
import time
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

os.environ["ERA_STANDALONE"] = "true"
os.environ["ERA_DEMO_MODE"] = "true"
os.environ.setdefault("ERA_SERVER_SALT", "e2e-standalone-salt")
for key in ("CELERY_BROKER_URL", "CELERY_RESULT_BACKEND", "REDIS_URL"):
    os.environ.pop(key, None)


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
            response = _request(client, "GET", "/health", base_url, timeout=5)
            if response.status_code == 200:
                payload = response.json()
                if payload.get("status") == "ok":
                    return payload
        except Exception as exc:  # noqa: BLE001
            last_error = exc
        time.sleep(1)
    raise RuntimeError(f"API health check failed: {last_error}")


def run_e2e(client, *, base_url: str = "") -> None:
    health = _wait_for_health(client, base_url, timeout_sec=30)
    assert health.get("standalone_mode") is True, health
    assert health.get("demo_mode") is True, health
    print("  health ... OK")

    generate_response = _request(client, "POST", "/generate", base_url, timeout=120)
    assert generate_response.status_code == 202, generate_response.text
    task_id = generate_response.json()["task_id"]
    print(f"  generate ... OK (task_id={task_id})")

    status_payload = None
    deadline = time.time() + 90
    while time.time() < deadline:
        status_response = _request(client, "GET", f"/status/{task_id}", base_url, timeout=30)
        assert status_response.status_code == 200, status_response.text
        status_payload = status_response.json()
        if status_payload["status"] in {"completed", "failed"}:
            break
        time.sleep(1)

    assert status_payload is not None
    assert status_payload["status"] == "completed", status_payload.get("error")
    print("  pipeline ... OK")

    gallery_response = _request(client, "GET", "/artifacts?page=1&page_size=1", base_url, timeout=30)
    assert gallery_response.status_code == 200, gallery_response.text
    gallery = gallery_response.json()

    assert gallery["total"] >= 1, gallery
    public_hash = gallery["items"][0]["public_hash"]
    print(f"  gallery ... OK (total={gallery['total']})")

    image_response = _request(client, "GET", f"/artifacts/{public_hash}/image", base_url, timeout=30)
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
    print("  verify ... OK")

    print("")
    print("[ERA] E2E standalone test PASSED - product is fully working.")


def main() -> None:
    parser = argparse.ArgumentParser(description="ERA standalone end-to-end test")
    parser.add_argument(
        "--api-url",
        default="",
        help="Optional running API base URL. If omitted, uses in-process TestClient.",
    )
    args = parser.parse_args()

    print("[ERA] E2E standalone test")
    if args.api_url:
        import httpx

        with httpx.Client() as client:
            run_e2e(client, base_url=args.api_url.rstrip("/"))
    else:
        from starlette.testclient import TestClient

        backend_dir = PROJECT_ROOT / "backend"
        if str(backend_dir) not in sys.path:
            sys.path.insert(0, str(backend_dir))
        os.chdir(backend_dir)
        from main import app  # noqa: E402

        with TestClient(app) as client:
            run_e2e(client)


if __name__ == "__main__":
    main()
