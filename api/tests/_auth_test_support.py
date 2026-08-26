"""Helpers dos testes de autenticação (FASE 8C).

Fornecem acesso ao PostgreSQL REAL dedicado (``meu_bebe_test``) e à execução da
migration via CLI do Alembic (subprocess). Os testes dependentes de banco pulam
explicitamente quando ``TEST_DATABASE_URL`` está ausente ou o PostgreSQL não é
alcançável — nunca substituem por SQLite (política 8B-PLAN §19).
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

from sqlalchemy import text

import meu_bebe_api.models  # noqa: F401 — registra as tabelas em Base.metadata
from meu_bebe_api.config import Settings
from meu_bebe_api.db.base import Base
from meu_bebe_api.db.engine import build_engine
from meu_bebe_api.db.probe import probe_database

# Segredo de teste (>= 32 bytes), apenas para a suíte — nunca produção.
TEST_JWT_SECRET = "teste-jwt-segredo-0123456789abcdef0123456789abcdef"

API_DIR = Path(__file__).resolve().parents[1]


def get_test_database_url() -> str | None:
    """Lê ``TEST_DATABASE_URL`` via pydantic-settings (``api/.env``)."""
    return Settings().test_database_url


def build_test_engine():
    """Engine apontando para o banco de teste dedicado (``TEST_DATABASE_URL``)."""
    return build_engine(Settings(database_url=get_test_database_url(), _env_file=None))


def postgres_ready() -> bool:
    """True se o PostgreSQL de teste está configurado e alcançável."""
    url = get_test_database_url()
    if not url:
        return False
    engine = build_engine(Settings(database_url=url, _env_file=None))
    ok = probe_database(engine)
    engine.dispose()
    return ok


def reset_schema(engine) -> None:
    """Remove as tabelas de domínio e o ``alembic_version`` (estado limpo)."""
    Base.metadata.drop_all(engine)
    with engine.begin() as conn:
        conn.execute(text("DROP TABLE IF EXISTS alembic_version"))


def run_alembic(action: str, revision: str, url: str) -> None:
    """Executa ``alembic <action> <revision>`` contra ``url`` (subprocess, banco real)."""
    env = {**os.environ, "DATABASE_URL": url}
    result = subprocess.run(
        [sys.executable, "-m", "alembic", action, revision],
        cwd=str(API_DIR),
        env=env,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, f"alembic {action} {revision} falhou:\n{result.stderr}"
