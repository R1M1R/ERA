"""Simple in-memory rate limiting for API abuse protection."""

from __future__ import annotations

import time
from collections import defaultdict
from threading import Lock

_lock = Lock()
_hits: dict[str, list[float]] = defaultdict(list)
_MAX_TRACKED_KEYS = 10_000


def _prune_stale_keys(now: float, window_seconds: int) -> None:
    """Drop expired entries so the limiter cannot grow without bound."""
    stale_keys = [
        key
        for key, stamps in _hits.items()
        if not stamps or now - stamps[-1] >= window_seconds
    ]
    for key in stale_keys:
        del _hits[key]

    overflow = len(_hits) - _MAX_TRACKED_KEYS
    if overflow > 0:
        for key in sorted(_hits, key=lambda item: _hits[item][-1])[:overflow]:
            del _hits[key]


def allow_request(key: str, *, max_calls: int, window_seconds: int) -> bool:
    """Return True when the caller is within the configured rate limit."""
    now = time.monotonic()
    with _lock:
        _prune_stale_keys(now, window_seconds)
        recent = [stamp for stamp in _hits[key] if now - stamp < window_seconds]
        if len(recent) >= max_calls:
            _hits[key] = recent
            return False
        recent.append(now)
        _hits[key] = recent
        return True
