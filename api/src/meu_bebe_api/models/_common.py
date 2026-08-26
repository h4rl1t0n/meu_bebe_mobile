"""Helpers compartilhados dos models ORM (FASE 8C)."""

from __future__ import annotations

from datetime import datetime, timezone


def utc_now() -> datetime:
    """Agora em UTC (timezone-aware), default dos timestamps persistentes."""
    return datetime.now(timezone.utc)
