"""Proof-of-authenticity verification service."""

from __future__ import annotations

from io import BytesIO

from PIL import Image

from backend.presentation import presentation_riddle
from backend.repository import get_artifact_by_authenticity_hash
from backend.steganography import (
    SteganographyError,
    SteganographyGenerator,
    compute_authenticity_hash,
)
from backend.verify_messages import (
    VERIFY_AUTHENTIC,
    VERIFY_FAKE_CORRUPTED,
    VERIFY_FAKE_HASH_MISMATCH,
    VERIFY_FAKE_NOT_IN_ARCHIVE,
)


def _fake_response(
    *,
    message_key: str,
    detail: str,
    text: str | None = None,
    authenticity_hash: str | None = None,
) -> dict[str, str | bool | None]:
    return {
        "status": "fake",
        "message_key": message_key,
        "message": message_key,
        "text": text,
        "authenticity_hash": authenticity_hash,
        "verified": False,
        "detail": detail,
    }


async def verify_artifact_image(image_bytes: bytes) -> dict[str, str | bool | None]:
    """Verify an uploaded artifact against server-side authenticity rules."""
    generator = SteganographyGenerator()

    try:
        image = Image.open(BytesIO(image_bytes)).convert("RGB")
        payload = generator.decode_authenticated_payload_from_image(image)
    except SteganographyError as exc:
        return _fake_response(
            message_key=VERIFY_FAKE_CORRUPTED,
            detail=str(exc),
        )

    try:
        expected_hash = compute_authenticity_hash(payload.text)
    except SteganographyError as exc:
        return _fake_response(
            message_key=VERIFY_FAKE_CORRUPTED,
            detail=str(exc),
            authenticity_hash=payload.authenticity_hash,
        )

    display_text = presentation_riddle(payload.text)

    if payload.authenticity_hash != expected_hash:
        return _fake_response(
            message_key=VERIFY_FAKE_HASH_MISMATCH,
            detail="Embedded authenticity hash does not match server recomputation.",
            text=display_text,
            authenticity_hash=payload.authenticity_hash,
        )

    db_record = await get_artifact_by_authenticity_hash(payload.authenticity_hash)
    if db_record is None:
        return _fake_response(
            message_key=VERIFY_FAKE_NOT_IN_ARCHIVE,
            detail="Authenticity hash was not found in the ERA archive.",
            text=display_text,
            authenticity_hash=payload.authenticity_hash,
        )

    return {
        "status": "authentic",
        "message_key": VERIFY_AUTHENTIC,
        "message": VERIFY_AUTHENTIC,
        "text": display_text,
        "authenticity_hash": payload.authenticity_hash,
        "verified": True,
        "detail": None,
    }
