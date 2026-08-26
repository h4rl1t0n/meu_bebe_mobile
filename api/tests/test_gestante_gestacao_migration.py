"""Testes da migration 0002 (FASE 8D) — PostgreSQL REAL.

Exercita ``alembic upgrade head`` / ``downgrade 0001`` via subprocess contra o
banco dedicado ``meu_bebe_test`` e inspeciona o schema resultante (colunas,
constraints, FK CASCADE, índice único parcial). Pula se o PostgreSQL não estiver
pronto. A migration 0001 (users/auth_refresh_sessions) NÃO é alterada: o
downgrade para 0001 deve preservá-las.
"""

from __future__ import annotations

import uuid

import pytest
from sqlalchemy import inspect, text
from sqlalchemy.exc import IntegrityError

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


def test_upgrade_creates_domain_and_keeps_auth_tables(migrated_db) -> None:
    names = _names(migrated_db)
    assert {"gestantes", "gestacoes", "users", "auth_refresh_sessions"} <= names


def test_gestantes_schema(migrated_db) -> None:
    inspector = inspect(migrated_db)
    cols = {c["name"]: c for c in inspector.get_columns("gestantes")}
    assert set(cols) == {
        "id",
        "user_id",
        "nome",
        "nome_social",
        "data_nascimento",
        "cpf",
        "cns",
        "created_at",
        "updated_at",
    }
    assert cols["user_id"]["nullable"] is False
    assert cols["nome"]["nullable"] is False
    assert cols["nome_social"]["nullable"] is True
    assert cols["data_nascimento"]["nullable"] is False
    assert cols["cpf"]["nullable"] is True
    assert cols["cns"]["nullable"] is True
    assert cols["created_at"]["nullable"] is False
    assert cols["updated_at"]["nullable"] is False

    assert inspector.get_pk_constraint("gestantes")["constrained_columns"] == ["id"]
    assert any(
        u["column_names"] == ["user_id"]
        for u in inspector.get_unique_constraints("gestantes")
    )
    fks = inspector.get_foreign_keys("gestantes")
    assert len(fks) == 1
    fk = fks[0]
    assert fk["referred_table"] == "users"
    assert fk["constrained_columns"] == ["user_id"]
    assert fk["options"].get("ondelete") == "CASCADE"


def test_gestacoes_schema(migrated_db) -> None:
    inspector = inspect(migrated_db)
    cols = {c["name"]: c for c in inspector.get_columns("gestacoes")}
    assert set(cols) == {
        "id",
        "gestante_id",
        "data_ultima_menstruacao",
        "local_pre_natal",
        "profissional_pre_natal",
        "contato_local_pre_natal",
        "ended_at",
        "created_at",
        "updated_at",
    }
    assert cols["gestante_id"]["nullable"] is False
    assert cols["data_ultima_menstruacao"]["nullable"] is True
    assert cols["ended_at"]["nullable"] is True
    assert cols["created_at"]["nullable"] is False
    assert cols["updated_at"]["nullable"] is False

    assert inspector.get_pk_constraint("gestacoes")["constrained_columns"] == ["id"]
    fks = inspector.get_foreign_keys("gestacoes")
    assert len(fks) == 1
    fk = fks[0]
    assert fk["referred_table"] == "gestantes"
    assert fk["constrained_columns"] == ["gestante_id"]
    assert fk["options"].get("ondelete") == "CASCADE"

    idx_names = {i["name"] for i in inspector.get_indexes("gestacoes")}
    assert "ix_gestacoes_gestante_id" in idx_names
    assert "uq_gestacoes_active_per_gestante" in idx_names


def test_partial_unique_index_enforces_single_active(migrated_db) -> None:
    """O índice único parcial (WHERE ended_at IS NULL) bloqueia a 2ª ativa no banco."""
    user_id = str(uuid.uuid4())
    gestante_id = str(uuid.uuid4())
    with migrated_db.begin() as conn:
        conn.execute(
            text(
                "INSERT INTO users (id, email, password_hash, is_active, created_at, updated_at) "
                "VALUES (:id, :e, 'x', true, now(), now())"
            ),
            {"id": user_id, "e": f"{uuid.uuid4().hex}@example.com"},
        )
        conn.execute(
            text(
                "INSERT INTO gestantes (id, user_id, nome, data_nascimento, created_at, updated_at) "
                "VALUES (:id, :u, 'Maria', '1990-01-01', now(), now())"
            ),
            {"id": gestante_id, "u": user_id},
        )
        # primeira ativa: OK
        conn.execute(
            text(
                "INSERT INTO gestacoes (id, gestante_id, created_at, updated_at) "
                "VALUES (:id, :g, now(), now())"
            ),
            {"id": str(uuid.uuid4()), "g": gestante_id},
        )
    # segunda ativa: deve violar o índice único parcial (transação isolada)
    with pytest.raises(IntegrityError):
        with migrated_db.begin() as conn:
            conn.execute(
                text(
                    "INSERT INTO gestacoes (id, gestante_id, created_at, updated_at) "
                    "VALUES (:id, :g, now(), now())"
                ),
                {"id": str(uuid.uuid4()), "g": gestante_id},
            )


def test_downgrade_0002_keeps_auth_tables(migrated_db) -> None:
    url = get_test_database_url()
    run_alembic("downgrade", "0001", url)
    names = _names(migrated_db)
    assert "gestantes" not in names
    assert "gestacoes" not in names
    assert {"users", "auth_refresh_sessions"} <= names
    run_alembic("upgrade", "head", url)
    assert {"gestantes", "gestacoes", "users", "auth_refresh_sessions"} <= _names(migrated_db)
