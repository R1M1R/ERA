"""Tests for public API response sanitization."""

from __future__ import annotations

import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from backend.public_result import sanitize_task_result  # noqa: E402


def test_sanitize_task_result_strips_internal_fields() -> None:
    raw = {
        "task_id": "abc",
        "riddle": "Who built the lighthouse?",
        "answer": "Sostratus",
        "embedded_text": "hidden",
        "image_path": "/tmp/secret.png",
        "authenticity_hash": "deadbeef",
        "image_base64": "aGVsbG8=",
        "database_record": {
            "public_hash": "abc123",
            "image_url": "/artifacts/abc123/image",
            "authenticity_hash": "deadbeef",
            "image_path": "/tmp/secret.png",
        },
    }

    sanitized = sanitize_task_result(raw)
    assert sanitized is not None
    assert sanitized["riddle"] == "Who built the lighthouse?"
    assert sanitized["answer"] == "Sostratus"
    assert sanitized["image_url"] == "/artifacts/abc123/image"
    assert "image_base64" not in sanitized
    assert "authenticity_hash" not in sanitized
    assert "image_path" not in sanitized
    assert "embedded_text" not in sanitized
    assert sanitized["database_record"] == {
        "public_hash": "abc123",
        "image_url": "/artifacts/abc123/image",
    }


def main() -> None:
    test_sanitize_task_result_strips_internal_fields()
    print("public_result tests ok")


if __name__ == "__main__":
    main()
