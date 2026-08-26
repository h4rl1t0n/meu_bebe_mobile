"""Testes de configuração de persistência (FASE 8B / 8B-AUDIT-FIX).

Cobrem:
- a distinção congelada: validação de CONFIGURAÇÃO (fail-fast) ×
  indisponibilidade do PostgreSQL em runtime;
- a WHITELIST da stack congelada (somente ``postgresql+psycopg://``) — M-1;
- a privacidade: a URL (e qualquer senha nela) NUNCA é ecoada em
  ``ValidationError`` (``hide_input_in_errors`` + mensagens genéricas) — M-2.

Nenhum teste aqui abre conexão com banco algum — valida apenas ``Settings``.
"""

from __future__ import annotations

import pytest
from pydantic import ValidationError

from meu_bebe_api.config import Settings

PSYCOPG_URL = "postgresql+psycopg://usuario:senha@localhost:5432/meu_bebe"

# URLs que a stack congelada NÃO deve aceitar (fail-fast de configuração).
REJECTED_URLS = [
    "sqlite:///arquivo.db",
    "mysql://user:pass@localhost/database",
    "postgresql+asyncpg://user:pass@localhost/database",
    "postgresql+psycopg2://user:pass@localhost/database",
    "postgresql://user:pass@localhost/database",
]

# Credencial fictícia/obviamente não real (nunca usar a senha de api/.env).
SENTINEL = "SENHA_SENTINELA_NAO_REAL_8B"


def test_database_url_default_is_none() -> None:
    """Sem ``DATABASE_URL``, o subsistema persistente é INERTE (sem erro)."""
    assert Settings(_env_file=None).database_url is None


def test_database_url_empty_string_becomes_none() -> None:
    assert Settings(database_url="", _env_file=None).database_url is None


def test_test_database_url_default_is_none() -> None:
    """Sem ``TEST_DATABASE_URL``, os testes de integração são pulados."""
    assert Settings(_env_file=None).test_database_url is None


def test_test_database_url_empty_string_becomes_none() -> None:
    assert Settings(test_database_url="", _env_file=None).test_database_url is None


@pytest.mark.parametrize("field", ["database_url", "test_database_url"])
def test_psycopg_url_is_accepted(field: str) -> None:
    """Somente ``postgresql+psycopg://`` é aceita (stack congelada)."""
    settings = Settings(**{field: PSYCOPG_URL}, _env_file=None)
    assert getattr(settings, field) == PSYCOPG_URL


@pytest.mark.parametrize("field", ["database_url", "test_database_url"])
@pytest.mark.parametrize("bad_url", REJECTED_URLS)
def test_non_psycopg_url_is_rejected(field: str, bad_url: str) -> None:
    """M-1: qualquer outro dialeto/driver → erro de CONFIGURAÇÃO previsível."""
    with pytest.raises(ValidationError):
        Settings(**{field: bad_url}, _env_file=None)


@pytest.mark.parametrize("bad_url", ["not a url at all", "::::", "://", " "])
def test_database_url_syntactically_invalid_raises_config_error(bad_url: str) -> None:
    """URL malformada → erro de CONFIGURAÇÃO previsível (não conexão)."""
    with pytest.raises(ValidationError):
        Settings(database_url=bad_url, _env_file=None)


@pytest.mark.parametrize("field", ["database_url", "test_database_url"])
def test_error_message_is_generic_no_url_no_value(field: str) -> None:
    """M-2: a mensagem de erro é GENÉRICA — não interpola URL, campo nem valor."""
    bad = "mysql://usuario:senha@localhost/db"
    with pytest.raises(ValidationError) as exc:
        Settings(**{field: bad}, _env_file=None)
    msg = str(exc.value)
    assert "mysql://" not in msg
    assert "usuario" not in msg
    assert "senha" not in msg
    assert field.upper() not in msg


@pytest.mark.parametrize(
    "bad_url",
    [
        f"postgresql+psycopg://usuario:{SENTINEL}@localhost:badport/db",
        f"mysql://usuario:{SENTINEL}@localhost/db",
        f"not a url {SENTINEL} at all",
    ],
)
def test_sentinel_never_leaks_in_validation_error(bad_url: str) -> None:
    """M-2: a credencial sentinela NÃO aparece em str() nem repr() do erro."""
    with pytest.raises(ValidationError) as exc:
        Settings(database_url=bad_url, _env_file=None)
    assert SENTINEL not in str(exc.value)
    assert SENTINEL not in repr(exc.value)
