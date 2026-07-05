"""Structured logging configuration for ERA services."""

from __future__ import annotations

import logging
import os


def configure_logging() -> None:
    """Configure application-wide logging once at process startup."""
    level_name = os.getenv("ERA_LOG_LEVEL", "INFO").strip().upper()
    level = getattr(logging, level_name, logging.INFO)
    logging.basicConfig(
        level=level,
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )


configure_logging()
