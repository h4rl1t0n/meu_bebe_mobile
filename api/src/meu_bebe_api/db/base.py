"""Base declarativa única (SQLAlchemy 2.x) para os futuros models ORM.

Esta é a ÚNICA ``DeclarativeBase`` do projeto. O Alembic usa
``Base.metadata`` como ``target_metadata`` (ver ``api/alembic/env.py``) — não
deve existir uma segunda metadata nem uma segunda base declarativa.

O ``naming_convention`` dá nomes estáveis e determinísticos às constraints,
condição para o ``autogenerate`` do Alembic produzir diffs limpos e reversíveis.

Nesta fase (infraestrutural) a Base permanece SEM models de domínio: nenhuma
tabela artificial é criada.
"""

from __future__ import annotations

from sqlalchemy import MetaData
from sqlalchemy.orm import DeclarativeBase

# Convenção de nomes de constraints (estável p/ Alembic autogenerate).
NAMING_CONVENTION: dict[str, str] = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


class Base(DeclarativeBase):
    """Base declarativa oficial de todos os models persistentes futuros."""

    metadata = MetaData(naming_convention=NAMING_CONVENTION)
