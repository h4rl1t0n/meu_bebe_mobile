"""Testes da migration 0006 (FASE 8H) — PostgreSQL REAL.

Exercita ``alembic upgrade head`` / ``downgrade 0005`` / ``upgrade head`` via
subprocess contra o banco dedicado ``meu_bebe_test`` e inspeciona o schema
resultante (colunas, UNIQUE, FK CASCADE). Pula se o PostgreSQL não estiver
pronto. As migrations 0001–0005 NÃO são alteradas: o downgrade para 0005 deve
remover ``planos_de_parto`` SEM tocar nas nove tabelas anteriores.
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


_PLANO_COLUMNS = {
    "id",
    "gestacao_id",
    "acompanhante",
    "raspar_pelos_intimos",
    "lavagem_intestinal",
    "ambiente_pouca_luz",
    "ouvir_musica",
    "beber_liquidos",
    "registrar_fotos_videos",
    "via_parto",
    "anestesia",
    "corte_vaginal",
    "posicao_preferida",
    "outra_posicao",
    "quem_corta_cordao",
    "coleta_celulas_tronco",
    "contato_pele_a_pele",
    "amamentar_primeira_hora",
    "restricoes_amamentacao",
    "primeiro_banho",
    "quer_alivio_dor",
    "massagem",
    "exercicios_bola",
    "exercicios_respiracao",
    "banho_chuveiro",
    "banho_banheira",
    "acupuntura",
    "acupressao",
    "outro_metodo",
    "observacoes",
    "created_at",
    "updated_at",
}

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
}


def test_upgrade_creates_plano_de_parto(migrated_db) -> None:
    names = _names(migrated_db)
    assert _PRIOR_TABLES <= names
    assert "planos_de_parto" in names


def test_plano_de_parto_schema(migrated_db) -> None:
    inspector = inspect(migrated_db)
    cols = {c["name"]: c for c in inspector.get_columns("planos_de_parto")}
    assert set(cols) == _PLANO_COLUMNS
    # Obrigatórias
    assert cols["gestacao_id"]["nullable"] is False
    assert cols["acompanhante"]["nullable"] is False
    assert cols["via_parto"]["nullable"] is False
    assert cols["coleta_celulas_tronco"]["nullable"] is False
    assert cols["observacoes"]["nullable"] is False
    assert cols["created_at"]["nullable"] is False
    assert cols["updated_at"]["nullable"] is False
    # Opcionais
    assert cols["posicao_preferida"]["nullable"] is True
    assert cols["outra_posicao"]["nullable"] is True

    assert inspector.get_pk_constraint("planos_de_parto")["constrained_columns"] == ["id"]

    # UNIQUE(gestacao_id) → singleton 1—0..1 por gestação.
    uniques = {u["name"]: u for u in inspector.get_unique_constraints("planos_de_parto")}
    assert "uq_planos_de_parto_gestacao_id" in uniques
    assert uniques["uq_planos_de_parto_gestacao_id"]["column_names"] == ["gestacao_id"]

    fks = inspector.get_foreign_keys("planos_de_parto")
    assert len(fks) == 1
    assert fks[0]["referred_table"] == "gestacoes"
    assert fks[0]["constrained_columns"] == ["gestacao_id"]
    assert fks[0]["options"].get("ondelete") == "CASCADE"


def test_downgrade_0006_keeps_prior_tables(migrated_db) -> None:
    url = get_test_database_url()
    run_alembic("downgrade", "0005", url)
    names = _names(migrated_db)
    assert "planos_de_parto" not in names
    assert _PRIOR_TABLES <= names
    run_alembic("upgrade", "head", url)
    assert "planos_de_parto" in _names(migrated_db)
