"""Testes do engine SQLAlchemy 2.x síncrono (FASE 8B).

Regra central: **CRIAR ENGINE != ABRIR CONEXÃO**. O engine é preguiçoso; a
criação não exige PostgreSQL online.
"""

from __future__ import annotations

from sqlalchemy.engine import Engine

from meu_bebe_api.config import Settings
from meu_bebe_api.db.engine import build_engine
from tests.conftest import UNREACHABLE_DATABASE_URL


def _settings(url: str | None, log_level: str = "INFO") -> Settings:
    return Settings(database_url=url, app_log_level=log_level, _env_file=None)


def test_build_engine_none_when_no_url() -> None:
    assert build_engine(_settings(None)) is None


def test_build_engine_none_when_empty_url() -> None:
    assert build_engine(_settings("")) is None


def test_build_engine_returns_engine_for_valid_url() -> None:
    engine = build_engine(_settings(UNREACHABLE_DATABASE_URL))
    assert isinstance(engine, Engine)
    assert engine.dialect.name == "postgresql"
    engine.dispose()


def test_engine_creation_is_lazy_no_connection_required() -> None:
    """Apontando para porta fechada, o engine é criado SEM conectar/levantar."""
    engine = build_engine(_settings(UNREACHABLE_DATABASE_URL))
    # A simples criação NÃO tenta conexão: se tentasse, levantaria aqui.
    assert engine is not None
    engine.dispose()


def test_engine_echo_off_by_default() -> None:
    engine = build_engine(_settings(UNREACHABLE_DATABASE_URL, log_level="INFO"))
    assert engine.echo is False
    engine.dispose()


def test_engine_echo_stays_false_even_on_debug() -> None:
    """SQL echo NÃO é habilitado automaticamente por ``DEBUG`` (privacidade)."""
    engine = build_engine(_settings(UNREACHABLE_DATABASE_URL, log_level="DEBUG"))
    assert engine.echo is False
    engine.dispose()


def test_engine_pool_pre_ping_enabled() -> None:
    """``pool_pre_ping`` recupera conexões mortas do pool (congelado na 8B)."""
    engine = build_engine(_settings(UNREACHABLE_DATABASE_URL))
    assert getattr(engine.pool, "_pre_ping", False) is True
    engine.dispose()
