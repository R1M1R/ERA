"""User-facing text helpers."""

from __future__ import annotations


def presentation_riddle(text: str) -> str:
    """Strip internal ERA artifact nonce suffix from embedded chronicle text."""
    marker = "\n#era:"
    if marker in text:
        return text.split(marker, 1)[0]
    return text
