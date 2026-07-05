"""Tests for runtime configuration helpers."""

from __future__ import annotations

import os

from backend.config import get_cors_origins


def test_cors_includes_vercel_urls(monkeypatch) -> None:
    monkeypatch.setenv("VERCEL_URL", "frontend-example.vercel.app")
    monkeypatch.setenv("VERCEL_BRANCH_URL", "frontend-git-main-example.vercel.app")
    monkeypatch.delenv("CORS_ORIGINS", raising=False)
    origins = get_cors_origins()
    assert "https://frontend-example.vercel.app" in origins
    assert "https://frontend-git-main-example.vercel.app" in origins


def test_cors_prefers_explicit_origins(monkeypatch) -> None:
    monkeypatch.setenv("CORS_ORIGINS", "https://custom.example.com")
    monkeypatch.setenv("VERCEL_URL", "frontend-example.vercel.app")
    origins = get_cors_origins()
    assert origins == ["https://custom.example.com", "https://frontend-example.vercel.app"]
