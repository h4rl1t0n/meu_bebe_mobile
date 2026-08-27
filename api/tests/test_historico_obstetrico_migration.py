"""Testes da migration 0003 (FASE 8E) — PostgreSQL REAL.

Exercita ``alembic upgrade head`` / ``downgrade 0002`` via subprocess contra o
banco dedicado ``meu_bebe_test`` e inspeciona o schema resultante (colunas,
constraints, FK CASCADE, UNIQUE 1—1). Pula se o PostgreSQL não estiver pronto.
As migrations 0001/0002 NÃO são alteradas: o downgrade para 0002 deve preservá-las.
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


def test_upgrade_creates_historicos_and_keeps_prior_tables(migrated_db) -> None:
    names = _names(migrated_db)
    assert {"historicos_obstetricos", "gestantes", "gestacoes", "users", "auth_refresh_sessions"} <= names


def test_historicos_obstetricos_schema(migrated_db) -> None:
    inspector = inspect(migrated_db)
    cols = {c["name"]: c for c in inspector.get_columns("historicos_obstetricos")}
    assert set(cols) == {
        "id",
        "gestante_id",
        "pregnancy_number",
        "given_birth_number",
        "abortions_number",
        "created_at",
        "updated_at",
    }
    assert cols["gestante_id"]["nullable"] is False
    assert cols["pregnancy_number"]["nullable"] is True
    assert cols["given_birth_number"]["nullable"] is True
    assert cols["abortions_number"]["nullable"] is True
    assert cols["created_at"]["nullable"] is False
    assert cols["updated_at"]["nullable"] is False

    assert inspector.get_pk_constraint("historicos_obstetricos")["constrained_columns"] == ["id"]
    assert any(
        u["column_names"] == ["gestante_id"]
        for u in inspector.get_unique_constraints("historicos_obstetricos")
    )
    fks = inspector.get_foreign_keys("historicos_obstetricos")
    assert len(fks) == 1
    fk = fks[0]
    assert fk["referred_table"] == "gestantes"
    assert fk["constrained_columns"] == ["gestante_id"]
    assert fk["options"].get("ondelete") == "CASCADE"


def test_unique_gestante_id_enforces_single_history(migrated_db) -> None:
    """A UNIQUE em ``gestante_id`` bloqueia um 2º histórico para a mesma gestante."""
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
        conn.execute(
            text(
                "INSERT INTO historicos_obstetricos "
                "(id, gestante_id, pregnancy_number, given_birth_number, abortions_number, created_at, updated_at) "
                "VALUES (:id, :g, 2, 1, 0, now(), now())"
            ),
            {"id": str(uuid.uuid4()), "g": gestante_id},
        )
    # segundo histórico para a MESMA gestante: viola a UNIQUE (transação isolada).
    with pytest.raises(IntegrityError):
        with migrated_db.begin() as conn:
            conn.execute(
                text(
                    "INSERT INTO historicos_obstetricos "
                    "(id, gestante_id, pregnancy_number, given_birth_number, abortions_number, created_at, updated_at) "
                    "VALUES (:id, :g, 3, 2, 1, now(), now())"
                ),
                {"id": str(uuid.uuid4()), "g": gestante_id},
            )


def test_downgrade_0003_keeps_prior_tables(migrated_db) -> None:
    url = get_test_database_url()
    run_alembic("downgrade", "0002", url)
    names = _names(migrated_db)
    assert "historicos_obstetricos" not in names
    assert {"gestantes", "gestacoes", "users", "auth_refresh_sessions"} <= names
    run_alembic("upgrade", "head", url)
    assert {"historicos_obstetricos", "gestantes", "gestacoes", "users", "auth_refresh_sessions"} <= _names(migrated_db)
