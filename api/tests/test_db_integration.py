"""Testes de integração com PostgreSQL REAL (FASE 8B).

Estratégia congelada (8B-PLAN §19): banco dedicado de testes (``meu_bebe_test``),
**nunca** SQLite em memória como substituto. Estes testes são condicionados à
disponibilidade de uma URL de teste real: só executam quando
``TEST_DATABASE_URL`` estiver definida e o PostgreSQL for alcançável; caso
contrário, são pulados (skip) de forma explícita — a ausência de PostgreSQL NÃO
substitui a validação real.

NÃO aponta para banco de produção; NÃO executa DROP indiscriminado; NÃO usa
dados reais.
"""

from __future__ import annotations

import pytest
from sqlalchemy import text
from sqlalchemy.engine import Engine

from meu_bebe_api.config import Settings
from meu_bebe_api.db.engine import build_engine
from meu_bebe_api.db.probe import probe_database
from meu_bebe_api.db.session import build_session_factory


def _test_database_url() -> str | None:
    """Lê ``TEST_DATABASE_URL`` via pydantic-settings (``api/.env``).

    Não usa ``os.environ``: as credenciais vivem em ``api/.env`` (não exportadas
    no shell), e apenas ``Settings`` as carrega. ``None``/vazio → sem banco de
    teste configurado (testes de integração pulados).
    """
    return Settings().test_database_url


def _test_engine() -> Engine:
    """Engine apontando para o banco de teste dedicado (``TEST_DATABASE_URL``)."""
    settings = Settings(database_url=_test_database_url(), _env_file=None)
    return build_engine(settings)


def _require_postgres() -> Engine:
    """Retorna o engine de teste ou faz skip se o PostgreSQL não estiver pronto."""
    url = _test_database_url()
    if not url:
        pytest.skip("TEST_DATABASE_URL não definida (PostgreSQL de teste indisponível)")
    engine = _test_engine()
    if not probe_database(engine):
        engine.dispose()
        pytest.skip("PostgreSQL de teste não alcançável (TEST_DATABASE_URL)")
    return engine


@pytest.fixture(scope="module")
def test_db_engine() -> Engine:
    engine = _require_postgres()
    yield engine
    engine.dispose()


def test_probe_returns_true_when_database_available(test_db_engine: Engine) -> None:
    assert probe_database(test_db_engine) is True


def test_session_executes_select_one(test_db_engine: Engine) -> None:
    factory = build_session_factory(test_db_engine)
    session = factory()
    try:
        result = session.execute(text("SELECT 1"))
        assert result.scalar() == 1
    finally:
        session.close()


def test_session_close_returns_connection_to_pool(test_db_engine: Engine) -> None:
    factory = build_session_factory(test_db_engine)
    session = factory()
    session.execute(text("SELECT 1"))
    session.close()
    # Após close, a conexão deve voltar ao pool (sem vazamento).
    assert test_db_engine.pool.checkedout() == 0


def test_transaction_rollback_isolates_state(test_db_engine: Engine) -> None:
    """Rollback desfaz uma escrita não committada (sem contaminar o banco).

    Usa uma TABELA TEMPORÁRIA (some ao fim da conexão) — não é tabela de
    domínio — para exercitar o comportamento transacional real do PostgreSQL.
    """
    with test_db_engine.connect() as conn:
        conn.execute(text("CREATE TEMPORARY TABLE _tmp_probe (id int)"))
        conn.commit()
        try:
            trans = conn.begin()
            conn.execute(text("INSERT INTO _tmp_probe VALUES (1)"))
            trans.rollback()
            count = conn.execute(text("SELECT count(*) FROM _tmp_probe")).scalar()
            assert count == 0
        finally:
            conn.execute(text("DROP TABLE _tmp_probe"))
            conn.commit()
