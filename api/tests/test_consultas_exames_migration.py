"""Testes da migration 0004 (FASE 8F) — PostgreSQL REAL.

Exercita ``alembic upgrade head`` / ``downgrade 0003`` / ``upgrade head`` via
subprocess contra o banco dedicado ``meu_bebe_test`` e inspeciona o schema
resultante (colunas, constraints, FK CASCADE, índice). Pula se o PostgreSQL não
estiver pronto. As migrations 0001–0003 NÃO são alteradas: o downgrade para 0003
deve removê-las SEM tocar em users/gestantes/gestacoes/historicos_obstetricos.
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


def test_upgrade_creates_consultas_and_exames(migrated_db) -> None:
    names = _names(migrated_db)
    assert {
        "consultas",
        "exames",
        "users",
        "auth_refresh_sessions",
        "gestantes",
        "gestacoes",
        "historicos_obstetricos",
    } <= names


def test_consultas_schema(migrated_db) -> None:
    inspector = inspect(migrated_db)
    cols = {c["name"]: c for c in inspector.get_columns("consultas")}
    assert set(cols) == {
        "id",
        "gestacao_id",
        "titulo",
        "data_consulta",
        "descricao",
        "created_at",
        "updated_at",
    }
    assert cols["gestacao_id"]["nullable"] is False
    assert cols["titulo"]["nullable"] is False
    assert cols["data_consulta"]["nullable"] is False
    assert cols["descricao"]["nullable"] is False
    assert cols["created_at"]["nullable"] is False
    assert cols["updated_at"]["nullable"] is False

    assert inspector.get_pk_constraint("consultas")["constrained_columns"] == ["id"]
    fks = inspector.get_foreign_keys("consultas")
    assert len(fks) == 1
    assert fks[0]["referred_table"] == "gestacoes"
    assert fks[0]["constrained_columns"] == ["gestacao_id"]
    assert fks[0]["options"].get("ondelete") == "CASCADE"

    idx = {i["name"]: i for i in inspector.get_indexes("consultas")}
    assert "ix_consultas_gestacao_id" in idx


def test_exames_schema(migrated_db) -> None:
    inspector = inspect(migrated_db)
    cols = {c["name"]: c for c in inspector.get_columns("exames")}
    assert set(cols) == {
        "id",
        "gestacao_id",
        "titulo",
        "data_exame",
        "descricao",
        "categoria",
        "created_at",
        "updated_at",
    }
    assert cols["gestacao_id"]["nullable"] is False
    assert cols["titulo"]["nullable"] is False
    assert cols["data_exame"]["nullable"] is False
    assert cols["descricao"]["nullable"] is False
    assert cols["categoria"]["nullable"] is True
    assert cols["created_at"]["nullable"] is False
    assert cols["updated_at"]["nullable"] is False

    assert inspector.get_pk_constraint("exames")["constrained_columns"] == ["id"]
    fks = inspector.get_foreign_keys("exames")
    assert len(fks) == 1
    assert fks[0]["referred_table"] == "gestacoes"
    assert fks[0]["constrained_columns"] == ["gestacao_id"]
    assert fks[0]["options"].get("ondelete") == "CASCADE"

    idx = {i["name"]: i for i in inspector.get_indexes("exames")}
    assert "ix_exames_gestacao_id" in idx


def test_downgrade_0004_keeps_prior_tables(migrated_db) -> None:
    url = get_test_database_url()
    run_alembic("downgrade", "0003", url)
    names = _names(migrated_db)
    assert "consultas" not in names
    assert "exames" not in names
    assert {
        "users",
        "auth_refresh_sessions",
        "gestantes",
        "gestacoes",
        "historicos_obstetricos",
    } <= names
    run_alembic("upgrade", "head", url)
    assert {"consultas", "exames"} <= _names(migrated_db)
