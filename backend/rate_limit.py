"""Simple in-memory rate limiting for API abuse protection."""

from __future__ import annotations

import time
from collections import defaultdict
from threading import Lock

_lock = Lock()
_hits: dict[str, list[float]] = defaultdict(list)


def allow_request(key: str, *, max_calls: int, window_seconds: int) -> bool:
    """Return True when the caller is within the configured rate limit."""
    now = time.monotonic()
    with _lock:
        recent = [stamp for stamp in _hits[key] if now - stamp < window_seconds]
        if len(recent) >= max_calls:
            _hits[key] = recent
            return False
        recent.append(now)
        _hits[key] = recent
        return True
