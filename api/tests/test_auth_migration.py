"""Testes da primeira migration (FASE 8C) — PostgreSQL REAL (seção 20.1 MIGRATION).

Exercita ``alembic upgrade head`` / ``downgrade base`` via subprocess contra o
banco dedicado ``meu_bebe_test`` e inspeciona o schema resultante (colunas,
constraints, FK com CASCADE e índice). Pula se o PostgreSQL não estiver pronto.
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


def test_upgrade_creates_both_tables(migrated_db) -> None:
    assert {"users", "auth_refresh_sessions"} <= _names(migrated_db)


def test_users_schema(migrated_db) -> None:
    inspector = inspect(migrated_db)
    cols = {c["name"]: c for c in inspector.get_columns("users")}
    assert set(cols) == {"id", "email", "password_hash", "is_active", "created_at", "updated_at"}
    assert cols["id"]["nullable"] is False
    assert cols["email"]["nullable"] is False
    assert getattr(cols["email"]["type"], "length", None) == 320
    assert cols["is_active"]["nullable"] is False
    assert cols["created_at"]["nullable"] is False
    assert cols["updated_at"]["nullable"] is False
    assert inspector.get_pk_constraint("users")["constrained_columns"] == ["id"]
    assert any(
        u["column_names"] == ["email"] for u in inspector.get_unique_constraints("users")
    )


def test_auth_refresh_sessions_schema(migrated_db) -> None:
    inspector = inspect(migrated_db)
    cols = {c["name"]: c for c in inspector.get_columns("auth_refresh_sessions")}
    assert set(cols) == {"id", "user_id", "jti", "created_at", "expires_at", "revoked_at"}
    assert cols["expires_at"]["nullable"] is False
    assert cols["revoked_at"]["nullable"] is True
    fks = inspector.get_foreign_keys("auth_refresh_sessions")
    assert len(fks) == 1
    fk = fks[0]
    assert fk["referred_table"] == "users"
    assert fk["constrained_columns"] == ["user_id"]
    assert fk["options"].get("ondelete") == "CASCADE"
    assert any(
        u["column_names"] == ["jti"] for u in inspector.get_unique_constraints("auth_refresh_sessions")
    )
    idx_names = {i["name"] for i in inspector.get_indexes("auth_refresh_sessions")}
    assert "ix_auth_refresh_sessions_user_id" in idx_names


def test_downgrade_removes_then_upgrade_recreates(migrated_db) -> None:
    url = get_test_database_url()
    run_alembic("downgrade", "base", url)
    assert "users" not in _names(migrated_db)
    assert "auth_refresh_sessions" not in _names(migrated_db)
    run_alembic("upgrade", "head", url)
    assert {"users", "auth_refresh_sessions"} <= _names(migrated_db)
