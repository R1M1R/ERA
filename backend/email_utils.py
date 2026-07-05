"""Shared email validation helpers."""

from __future__ import annotations

import re

EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def normalize_email(email: str) -> str:
    """Normalize and validate a checkout email address."""
    normalized = email.strip().lower()
    if not normalized or not EMAIL_PATTERN.fullmatch(normalized):
        raise ValueError("A valid email address is required.")
    return normalized
