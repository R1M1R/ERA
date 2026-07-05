"""Tests for in-memory rate limiting."""

from __future__ import annotations

from backend.rate_limit import allow_request


def test_rate_limit_blocks_after_threshold() -> None:
    key = "pytest-rate-limit"
    assert allow_request(key, max_calls=2, window_seconds=60) is True
    assert allow_request(key, max_calls=2, window_seconds=60) is True
    assert allow_request(key, max_calls=2, window_seconds=60) is False
