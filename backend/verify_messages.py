"""Stable verification message keys returned by the API (localized on the client)."""

from __future__ import annotations

from typing import Final, Literal

VerifyMessageKey = Literal[
    "verify_authentic",
    "verify_fake_corrupted",
    "verify_fake_hash_mismatch",
    "verify_fake_not_in_archive",
]

VERIFY_AUTHENTIC: Final[VerifyMessageKey] = "verify_authentic"
VERIFY_FAKE_CORRUPTED: Final[VerifyMessageKey] = "verify_fake_corrupted"
VERIFY_FAKE_HASH_MISMATCH: Final[VerifyMessageKey] = "verify_fake_hash_mismatch"
VERIFY_FAKE_NOT_IN_ARCHIVE: Final[VerifyMessageKey] = "verify_fake_not_in_archive"
