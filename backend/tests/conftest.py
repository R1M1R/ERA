"""Pytest configuration for ERA backend."""

from __future__ import annotations

import os

os.environ.setdefault("ERA_STANDALONE", "true")
os.environ.setdefault("ERA_DEMO_MODE", "true")
os.environ.setdefault("ERA_SERVER_SALT", "pytest-era-salt")
