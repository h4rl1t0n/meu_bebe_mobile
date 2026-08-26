"""Testes de configuração de persistência (FASE 8B).

Cobrem a distinção congelada na 8B-PLAN §12: validação de FORMATO da
``DATABASE_URL`` (fail-fast de configuração) × indisponibilidade do PostgreSQL
em runtime. Aqui só se testa a configuração (sem abrir conexão).
"""

from __future__ import annotations

import pytest

from meu_bebe_api.config import Settings


def test_database_url_default_is_none() -> None:
    """Sem ``DATABASE_URL``, o subsistema persistente é INERTE (sem erro)."""
    settings = Settings(_env_file=None)
    assert settings.database_url is None


def test_database_url_empty_string_becomes_none() -> None:
    settings = Settings(database_url="", _env_file=None)
    assert settings.database_url is None


def test_database_url_valid_psycopg_is_kept() -> None:
    url = "postgresql+psycopg://usuario:senha@localhost:5432/meu_bebe"
    settings = Settings(database_url=url, _env_file=None)
    assert settings.database_url == url


@pytest.mark.parametrize(
    "bad_url",
    [
        "not a url at all",
        "::::",
        "://",
        " ",
    ],
)
def test_database_url_syntactically_invalid_raises_config_error(bad_url: str) -> None:
    """URL malformada → erro de CONFIGURAÇÃO previsível (não conexão)."""
    with pytest.raises(ValueError):
        Settings(database_url=bad_url, _env_file=None)


def test_invalid_url_error_mentions_database_url() -> None:
    """A mensagem de erro de configuração referencia ``DATABASE_URL``."""
    with pytest.raises(ValueError, match="DATABASE_URL"):
        Settings(database_url="::::", _env_file=None)


def test_test_database_url_default_is_none() -> None:
    """Sem ``TEST_DATABASE_URL``, os testes de integração são pulados."""
    settings = Settings(_env_file=None)
    assert settings.test_database_url is None


def test_test_database_url_empty_string_becomes_none() -> None:
    settings = Settings(test_database_url="", _env_file=None)
    assert settings.test_database_url is None


def test_test_database_url_valid_psycopg_is_kept() -> None:
    url = "postgresql+psycopg://usuario:senha@localhost:5432/meu_bebe_test"
    settings = Settings(test_database_url=url, _env_file=None)
    assert settings.test_database_url == url


def test_test_database_url_invalid_raises_config_error() -> None:
    """``TEST_DATABASE_URL`` malformada → mesmo erro de configuração (campo certo)."""
    with pytest.raises(ValueError, match="TEST_DATABASE_URL"):
        Settings(test_database_url="::::", _env_file=None)
