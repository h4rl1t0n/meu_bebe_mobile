"""Testes da Base declarativa única (FASE 8B).

Garantem que ``Base.metadata`` é a metadata oficial (usada pelo Alembic) e que
a ``naming_convention`` de constraints está aplicada. A FASE 8C adiciona as duas
primeiras entidades de domínio (``users`` e ``auth_refresh_sessions``).
"""

from __future__ import annotations

from sqlalchemy import MetaData

from meu_bebe_api.db.base import Base, NAMING_CONVENTION


def test_base_metadata_is_sqlalchemy_metadata() -> None:
    assert isinstance(Base.metadata, MetaData)


def test_base_metadata_contains_only_auth_domain_tables() -> None:
    """As ÚNICAS tabelas de domínio são as duas da FASE 8C (identidade/auth)."""
    assert set(Base.metadata.tables) == {"users", "auth_refresh_sessions"}


def test_naming_convention_is_applied() -> None:
    convention = Base.metadata.naming_convention
    assert convention is not None
    assert convention["pk"] == "pk_%(table_name)s"
    assert convention["fk"].startswith("fk_")
    assert convention["uq"].startswith("uq_")
    assert convention["ix"].startswith("ix_")


def test_naming_convention_constant_matches_metadata() -> None:
    assert Base.metadata.naming_convention == NAMING_CONVENTION
