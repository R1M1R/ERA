"""Smoke test for the generation pipeline in demo mode."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

os.environ.setdefault("ERA_DEMO_MODE", "true")
os.environ.setdefault("ERA_SERVER_SALT", "pipeline-test-salt")

from backend.llm_service import HistoryRiddle  # noqa: E402
from worker.tasks import build_pipeline_result, encode_riddle_into_artifact, generate_riddle_payload  # noqa: E402


def main() -> None:
    riddle = generate_riddle_payload()
    assert isinstance(riddle, HistoryRiddle)

    artifact = encode_riddle_into_artifact(riddle, "pipeline-test")
    image_bytes = Path(artifact["image_path"]).read_bytes()

    result = build_pipeline_result(
        artifact_id="pipeline-test",
        riddle=riddle,
        artifact=artifact,
        db_record={"public_hash": "test", "image_url": "/artifacts/test/image"},
    )
    json.dumps(result)
    assert "image_bytes" not in result
    assert result["image_base64"]
    assert len(image_bytes) > 0
    print("pipeline demo smoke ok")


if __name__ == "__main__":
    main()
