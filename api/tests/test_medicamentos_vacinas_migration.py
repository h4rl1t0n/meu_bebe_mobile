"""Testes da migration 0005 (FASE 8G) — PostgreSQL REAL.

Exercita ``alembic upgrade head`` / ``downgrade 0004`` / ``upgrade head`` via
subprocess contra o banco dedicado ``meu_bebe_test`` e inspeciona o schema
resultante (colunas, constraints, FK CASCADE, índice). Pula se o PostgreSQL não
estiver pronto. As migrations 0001–0004 NÃO são alteradas: o downgrade para 0004
deve remover medicamentos/vacinas SEM tocar em
users/gestantes/gestacoes/historicos_obstetricos/consultas/exames.
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


def test_upgrade_creates_medicamentos_and_vacinas(migrated_db) -> None:
    names = _names(migrated_db)
    assert {
        "medicamentos",
        "vacinas",
        "users",
        "auth_refresh_sessions",
        "gestantes",
        "gestacoes",
        "historicos_obstetricos",
        "consultas",
        "exames",
    } <= names


def test_medicamentos_schema(migrated_db) -> None:
    inspector = inspect(migrated_db)
    cols = {c["name"]: c for c in inspector.get_columns("medicamentos")}
    assert set(cols) == {
        "id",
        "gestacao_id",
        "nome",
        "dose",
        "frequencia",
        "created_at",
        "updated_at",
    }
    assert cols["gestacao_id"]["nullable"] is False
    assert cols["nome"]["nullable"] is False
    assert cols["dose"]["nullable"] is False
    assert cols["frequencia"]["nullable"] is False
    assert cols["created_at"]["nullable"] is False
    assert cols["updated_at"]["nullable"] is False

    assert inspector.get_pk_constraint("medicamentos")["constrained_columns"] == ["id"]
    fks = inspector.get_foreign_keys("medicamentos")
    assert len(fks) == 1
    assert fks[0]["referred_table"] == "gestacoes"
    assert fks[0]["constrained_columns"] == ["gestacao_id"]
    assert fks[0]["options"].get("ondelete") == "CASCADE"

    idx = {i["name"]: i for i in inspector.get_indexes("medicamentos")}
    assert "ix_medicamentos_gestacao_id" in idx


def test_vacinas_schema(migrated_db) -> None:
    inspector = inspect(migrated_db)
    cols = {c["name"]: c for c in inspector.get_columns("vacinas")}
    assert set(cols) == {
        "id",
        "gestacao_id",
        "nome",
        "aplicada",
        "created_at",
        "updated_at",
    }
    assert cols["gestacao_id"]["nullable"] is False
    assert cols["nome"]["nullable"] is False
    assert cols["aplicada"]["nullable"] is False
    assert cols["created_at"]["nullable"] is False
    assert cols["updated_at"]["nullable"] is False

    assert inspector.get_pk_constraint("vacinas")["constrained_columns"] == ["id"]
    fks = inspector.get_foreign_keys("vacinas")
    assert len(fks) == 1
    assert fks[0]["referred_table"] == "gestacoes"
    assert fks[0]["constrained_columns"] == ["gestacao_id"]
    assert fks[0]["options"].get("ondelete") == "CASCADE"

    idx = {i["name"]: i for i in inspector.get_indexes("vacinas")}
    assert "ix_vacinas_gestacao_id" in idx


def test_downgrade_0005_keeps_prior_tables(migrated_db) -> None:
    url = get_test_database_url()
    run_alembic("downgrade", "0004", url)
    names = _names(migrated_db)
    assert "medicamentos" not in names
    assert "vacinas" not in names
    assert {
        "users",
        "auth_refresh_sessions",
        "gestantes",
        "gestacoes",
        "historicos_obstetricos",
        "consultas",
        "exames",
    } <= names
    run_alembic("upgrade", "head", url)
    assert {"medicamentos", "vacinas"} <= _names(migrated_db)
