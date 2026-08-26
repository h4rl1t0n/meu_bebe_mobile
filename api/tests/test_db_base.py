"""Testes da Base declarativa única (FASE 8B).

Garantem que ``Base.metadata`` é a metadata oficial (usada pelo Alembic) e que
a ``naming_convention`` de constraints está aplicada. Nenhuma entidade de
domínio nem tabela artificial existe nesta fase.
"""

from __future__ import annotations

from sqlalchemy import MetaData

from meu_bebe_api.db.base import Base, NAMING_CONVENTION


def test_base_metadata_is_sqlalchemy_metadata() -> None:
    assert isinstance(Base.metadata, MetaData)


def test_base_metadata_is_empty_no_domain_tables() -> None:
    """Nenhuma tabela de domínio/placeholder deve existir ainda (8B é infra)."""
    assert list(Base.metadata.tables) == []


def test_naming_convention_is_applied() -> None:
    convention = Base.metadata.naming_convention
    assert convention is not None
    assert convention["pk"] == "pk_%(table_name)s"
    assert convention["fk"].startswith("fk_")
    assert convention["uq"].startswith("uq_")
    assert convention["ix"].startswith("ix_")


def test_naming_convention_constant_matches_metadata() -> None:
    assert Base.metadata.naming_convention == NAMING_CONVENTION
