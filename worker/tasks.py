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

from backend.llm_service import (  # noqa: E402
    HistoryRiddle,
    HistoryRiddleGenerator,
    generate_demo_riddle,
    is_demo_mode,
    is_openai_configured,
)
from backend.repository import save_artifact  # noqa: E402
from backend.runtime import artifacts_dir  # noqa: E402
from backend.steganography import SteganographyGenerator  # noqa: E402

logger = logging.getLogger(__name__)


def generate_riddle_payload(*, pro_tier: bool = False) -> HistoryRiddle:
    """Call the LLM riddle generator from synchronous Celery worker code."""
    if pro_tier and is_openai_configured():
        logger.info("ERA pro tier: using OpenAI historical riddle")
        generator = HistoryRiddleGenerator()
        return asyncio.run(generator.generate_riddle())
    if is_demo_mode():
        logger.info("ERA demo mode: using built-in historical riddle")
        return generate_demo_riddle()
    generator = HistoryRiddleGenerator()
    return asyncio.run(generator.generate_riddle())


def encode_riddle_into_artifact(riddle: HistoryRiddle, artifact_id: str) -> dict[str, Any]:
    """Hide the generated riddle text inside a procedural PNG artifact."""
    output_dir = artifacts_dir()
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{artifact_id}.png"

    generator = SteganographyGenerator()
    image_path, authenticity_hash = generator.encode_authenticated_text_to_image(
        riddle.embedding_text(artifact_id=artifact_id),
        output_path,
        seed=f"{riddle.riddle}:{artifact_id}",
    )

    image_bytes = image_path.read_bytes()
    return {
        "artifact_id": artifact_id,
        "image_path": str(image_path),
        "authenticity_hash": authenticity_hash,
        "image_base64": base64.b64encode(image_bytes).decode("ascii"),
    }


def build_pipeline_result(
    *,
    artifact_id: str,
    riddle: HistoryRiddle,
    artifact: dict[str, Any],
    db_record: dict[str, Any],
) -> dict[str, Any]:
    """Build a JSON-serializable Celery result payload (no raw bytes)."""
    return {
        "task_id": artifact_id,
        "riddle": riddle.riddle,
        "answer": riddle.answer,
        "embedded_text": riddle.embedding_text(artifact_id=artifact_id),
        "status": "completed",
        "database_record": db_record,
        "artifact_id": artifact["artifact_id"],
        "image_path": artifact["image_path"],
        "authenticity_hash": artifact["authenticity_hash"],
        "image_base64": artifact["image_base64"],
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
def run_generation_pipeline(self, pro_tier: bool = False) -> dict[str, Any]:
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
    riddle = generate_riddle_payload(pro_tier=pro_tier)

    self.update_state(
        state="PROGRESS",
        meta={"step": "encode_artifact", "task_id": artifact_id},
    )
    encoded = encode_riddle_into_artifact(riddle, artifact_id)
    image_bytes = Path(encoded["image_path"]).read_bytes()

    self.update_state(
        state="PROGRESS",
        meta={"step": "persist_metadata", "task_id": artifact_id},
    )
    db_record = save_artifact(
        image_path=encoded["image_path"],
        authenticity_hash=encoded["authenticity_hash"],
        image_bytes=image_bytes,
    )

    result = build_pipeline_result(
        artifact_id=artifact_id,
        riddle=riddle,
        artifact=encoded,
        db_record=db_record,
    )
    logger.info("Pipeline[%s] completed", artifact_id)
    return result


def enqueue_generation_pipeline(*, pro_tier: bool = False) -> str:
    """Enqueue the orchestrator task and return its Celery task id."""
    async_result = run_generation_pipeline.delay(pro_tier=pro_tier)
    return async_result.id
