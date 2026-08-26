"""Testes de configuração de auth (FASE 8C) — sem banco (seção 20.1 CONFIG)."""

from __future__ import annotations

from pathlib import Path

import pytest
from pydantic import ValidationError

from meu_bebe_api.config import Settings

API_DIR = Path(__file__).resolve().parents[1]


def test_default_jwt_settings() -> None:
    s = Settings(_env_file=None)
    assert s.jwt_secret is None
    assert s.jwt_algorithm == "HS256"
    assert s.access_token_ttl_seconds == 900
    assert s.refresh_token_ttl_seconds == 2592000


def test_custom_ttls_are_read() -> None:
    s = Settings(access_token_ttl_seconds=60, refresh_token_ttl_seconds=120, _env_file=None)
    assert s.access_token_ttl_seconds == 60
    assert s.refresh_token_ttl_seconds == 120


def test_jwt_algorithm_rejects_non_hs256() -> None:
    with pytest.raises(ValidationError):
        Settings(jwt_algorithm="RS256", _env_file=None)


def test_jwt_secret_not_echoed_on_config_error() -> None:
    """O segredo nunca é ecoado num erro de validação de configuração."""
    with pytest.raises(ValidationError) as exc_info:
        Settings(jwt_secret="super-secret-xyz", jwt_algorithm="none", _env_file=None)
    assert "super-secret-xyz" not in str(exc_info.value)


def test_env_example_has_jwt_placeholder() -> None:
    content = (API_DIR / ".env.example").read_text(encoding="utf-8")
    assert "\nJWT_SECRET=\n" in content
    assert "JWT_ALGORITHM=HS256" in content
    assert "ACCESS_TOKEN_TTL_SECONDS=900" in content
    assert "REFRESH_TOKEN_TTL_SECONDS=2592000" in content
