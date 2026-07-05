"""Vercel serverless entrypoint for ERA FastAPI (standalone demo mode)."""

from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BACKEND = ROOT / "backend"
for path in (ROOT, BACKEND):
    path_str = str(path)
    if path_str not in sys.path:
        sys.path.insert(0, path_str)

os.environ.setdefault("VERCEL", "1")
os.environ.setdefault("ERA_STANDALONE", "true")
os.environ.setdefault("ERA_DEMO_MODE", "true")
os.environ.setdefault("ERA_SERVER_SALT", "era-vercel-cloud-salt-v1")

from mangum import Mangum  # noqa: E402

from main import app  # noqa: E402

handler = Mangum(app, lifespan="auto")
