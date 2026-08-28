"""Testes da migration 0007 (FASE 8I) — PostgreSQL REAL.

Exercita ``alembic upgrade head`` / ``downgrade 0006`` / ``upgrade head`` via
subprocess contra o banco dedicado ``meu_bebe_test`` e inspeciona o schema
resultante (colunas, índice, FK CASCADE, JSONB). Pula se o PostgreSQL não
estiver pronto. As migrations 0001–0006 NÃO são alteradas: o downgrade para
0006 deve remover ``avaliacoes_dss`` SEM tocar nas dez tabelas anteriores.
"""

from __future__ import annotations

import pytest
from sqlalchemy import inspect

from tests._auth_test_support import (
    build_test_engine,
    get_test_database_url,
    postgres_ready,
    reset_schema,
    run_alembic,
)


def _require_postgres() -> str:
    if not postgres_ready():
        pytest.skip("TEST_DATABASE_URL não definida / PostgreSQL indisponível")
    return get_test_database_url()


@pytest.fixture(scope="module")
def migrated_db():
    url = _require_postgres()
    engine = build_test_engine()
    reset_schema(engine)
    run_alembic("upgrade", "head", url)
    yield engine
    run_alembic("downgrade", "base", url)
    reset_schema(engine)
    engine.dispose()


def _names(engine) -> set[str]:
    return set(inspect(engine).get_table_names())


_AVALIACAO_COLUMNS = {
    "id",
    "gestacao_id",
    "schema_version",
    "respostas",
    "created_at",
}

# As dez tabelas criadas pelas migrations 0001–0006 (9 de domínio + plano de parto).
_PRIOR_TABLES = {
    "users",
    "auth_refresh_sessions",
    "gestantes",
    "gestacoes",
    "historicos_obstetricos",
    "consultas",
    "exames",
    "medicamentos",
    "vacinas",
    "planos_de_parto",
}


def test_upgrade_creates_avaliacoes_dss(migrated_db) -> None:
    names = _names(migrated_db)
    assert _PRIOR_TABLES <= names
    assert "avaliacoes_dss" in names


def test_avaliacoes_dss_schema(migrated_db) -> None:
    inspector = inspect(migrated_db)
    cols = {c["name"]: c for c in inspector.get_columns("avaliacoes_dss")}
    assert set(cols) == _AVALIACAO_COLUMNS

    # Obrigatórias (imutável: sem updated_at).
    assert cols["gestacao_id"]["nullable"] is False
    assert cols["schema_version"]["nullable"] is False
    assert cols["respostas"]["nullable"] is False
    assert cols["created_at"]["nullable"] is False
    # TIMESTAMPTZ (created_at timezone-aware).
    assert cols["created_at"]["type"].timezone is True
    # respostas é JSONB nativo do PostgreSQL.
    assert type(cols["respostas"]["type"]).__name__ == "JSONB"

    # PK id.
    assert inspector.get_pk_constraint("avaliacoes_dss")["constrained_columns"] == ["id"]

    # Índice (não único) em gestacao_id → lista 1—N, não singleton.
    indexes = {i["name"]: i for i in inspector.get_indexes("avaliacoes_dss")}
    assert "ix_avaliacoes_dss_gestacao_id" in indexes
    assert indexes["ix_avaliacoes_dss_gestacao_id"]["column_names"] == ["gestacao_id"]
    assert indexes["ix_avaliacoes_dss_gestacao_id"]["unique"] is False

    # FK gestacao_id → gestacoes.id ON DELETE CASCADE.
    fks = inspector.get_foreign_keys("avaliacoes_dss")
    assert len(fks) == 1
    assert fks[0]["referred_table"] == "gestacoes"
    assert fks[0]["constrained_columns"] == ["gestacao_id"]
    assert fks[0]["options"].get("ondelete") == "CASCADE"


def test_downgrade_0007_keeps_prior_tables(migrated_db) -> None:
    url = get_test_database_url()
    run_alembic("downgrade", "0006", url)
    names = _names(migrated_db)
    assert "avaliacoes_dss" not in names
    assert _PRIOR_TABLES <= names
    run_alembic("upgrade", "head", url)
    assert "avaliacoes_dss" in _names(migrated_db)
