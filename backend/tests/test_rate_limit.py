"""Tests for in-memory rate limiting."""

from __future__ import annotations

import time

from backend.rate_limit import allow_request


def test_rate_limit_blocks_after_threshold() -> None:
    key = "pytest-rate-limit"
    assert allow_request(key, max_calls=2, window_seconds=60) is True
    assert allow_request(key, max_calls=2, window_seconds=60) is True
    assert allow_request(key, max_calls=2, window_seconds=60) is False


def test_rate_limit_prunes_stale_keys() -> None:
    assert allow_request("pytest-prune-a", max_calls=1, window_seconds=1) is True
    assert allow_request("pytest-prune-b", max_calls=1, window_seconds=1) is True
    time.sleep(1.1)
    assert allow_request("pytest-prune-c", max_calls=1, window_seconds=1) is True
