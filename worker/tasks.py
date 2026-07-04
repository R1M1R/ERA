"""Celery task pipeline for historical artifact generation."""

from __future__ import annotations

import asyncio
import base64
import logging
import sys
import uuid
from pathlib import Path
from typing import Any

from backend.celery_client import celery_app

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from backend.llm_service import HistoryRiddle, HistoryRiddleGenerator  # noqa: E402
from backend.repository import save_artifact  # noqa: E402
from backend.steganography import SteganographyGenerator  # noqa: E402

logger = logging.getLogger(__name__)

ARTIFACTS_DIR = PROJECT_ROOT / "backend" / "artifacts"


def generate_riddle_payload() -> HistoryRiddle:
    """Call the LLM riddle generator from synchronous Celery worker code."""
    generator = HistoryRiddleGenerator()
    return asyncio.run(generator.generate_riddle())


def encode_riddle_into_artifact(riddle: HistoryRiddle, artifact_id: str) -> dict[str, Any]:
    """Hide the generated riddle text inside a procedural PNG artifact."""
    ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)
    output_path = ARTIFACTS_DIR / f"{artifact_id}.png"

    generator = SteganographyGenerator()
    image_path, authenticity_hash = generator.encode_authenticated_text_to_image(
        riddle.embedding_text(),
        output_path,
        seed=riddle.riddle,
    )

    image_bytes = image_path.read_bytes()
    return {
        "artifact_id": artifact_id,
        "image_path": str(image_path),
        "authenticity_hash": authenticity_hash,
        "image_bytes": image_bytes,
        "image_base64": base64.b64encode(image_bytes).decode("ascii"),
    }


@celery_app.task(name="era.pipeline.generate_riddle")
def task_generate_riddle() -> dict[str, str]:
    """Celery wrapper for stage 1 — LLM riddle generation."""
    riddle = generate_riddle_payload()
    return {"riddle": riddle.riddle, "answer": riddle.answer}


@celery_app.task(name="era.pipeline.encode_artifact")
def task_encode_artifact(riddle_data: dict[str, str], artifact_id: str) -> dict[str, Any]:
    """Celery wrapper for stage 2 — steganographic artifact encoding."""
    riddle = HistoryRiddle(
        riddle=riddle_data["riddle"],
        answer=riddle_data["answer"],
    )
    return encode_riddle_into_artifact(riddle, artifact_id)


@celery_app.task(bind=True, name="era.pipeline.run")
def run_generation_pipeline(self) -> dict[str, Any]:
    """Orchestrate LLM riddle generation, steganographic encoding, and persistence.

    Pipeline:
        1. ``HistoryRiddleGenerator.generate_riddle()``
        2. ``SteganographyGenerator.encode_text_to_image()`` with the riddle text
        3. Persist riddle, answer, and image path in PostgreSQL
    """
    artifact_id = self.request.id or str(uuid.uuid4())
    logger.info("Pipeline[%s] started", artifact_id)

    self.update_state(
        state="PROGRESS",
        meta={"step": "generate_riddle", "task_id": artifact_id},
    )
    riddle = generate_riddle_payload()

    self.update_state(
        state="PROGRESS",
        meta={"step": "encode_artifact", "task_id": artifact_id},
    )
    artifact = encode_riddle_into_artifact(riddle, artifact_id)

    self.update_state(
        state="PROGRESS",
        meta={"step": "persist_metadata", "task_id": artifact_id},
    )
    db_record = save_artifact(
        image_path=artifact["image_path"],
        authenticity_hash=artifact["authenticity_hash"],
        image_bytes=artifact.get("image_bytes"),
    )

    result = {
        "task_id": artifact_id,
        "riddle": riddle.riddle,
        "answer": riddle.answer,
        "embedded_text": riddle.embedding_text(),
        "status": "completed",
        "database_record": db_record,
        **artifact,
    }
    logger.info("Pipeline[%s] completed", artifact_id)
    return result


def enqueue_generation_pipeline() -> str:
    """Enqueue the orchestrator task and return its Celery task id."""
    async_result = run_generation_pipeline.delay()
    return async_result.id
