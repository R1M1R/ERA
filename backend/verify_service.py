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


async def verify_artifact_image(image_bytes: bytes) -> dict[str, str | bool | None]:
    """Verify an uploaded artifact against server-side authenticity rules."""
    generator = SteganographyGenerator()

    try:
        image = Image.open(BytesIO(image_bytes)).convert("RGB")
        payload = generator.decode_authenticated_payload_from_image(image)
    except SteganographyError as exc:
        return {
            "status": "fake",
            "message": "Fake / Corrupted Data",
            "text": None,
            "authenticity_hash": None,
            "verified": False,
            "detail": str(exc),
        }

    try:
        expected_hash = compute_authenticity_hash(payload.text)
    except SteganographyError as exc:
        return {
            "status": "fake",
            "message": "Fake / Corrupted Data",
            "text": None,
            "authenticity_hash": payload.authenticity_hash,
            "verified": False,
            "detail": str(exc),
        }

    display_text = presentation_riddle(payload.text)

    if payload.authenticity_hash != expected_hash:
        return {
            "status": "fake",
            "message": "Fake / Corrupted Data",
            "text": display_text,
            "authenticity_hash": payload.authenticity_hash,
            "verified": False,
            "detail": "Embedded authenticity hash does not match server recomputation.",
        }

    db_record = await get_artifact_by_authenticity_hash(payload.authenticity_hash)
    if db_record is None:
        return {
            "status": "fake",
            "message": "Fake / Corrupted Data",
            "text": display_text,
            "authenticity_hash": payload.authenticity_hash,
            "verified": False,
            "detail": "Authenticity hash was not found in the ERA archive.",
        }

    return {
        "status": "authentic",
        "message": "Подлинный артефакт",
        "text": display_text,
        "authenticity_hash": payload.authenticity_hash,
        "verified": True,
        "detail": None,
    }
