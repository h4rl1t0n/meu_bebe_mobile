"""Ambiente Alembic da API Meu Bebê (FASE 8B).

Lê ``DATABASE_URL`` de ``meu_bebe_api.config`` (Settings) e usa
``meu_bebe_api.db.base.Base.metadata`` como ``target_metadata`` — a ÚNICA
metadata declarativa do projeto (sem duplicar Base, sem segunda metadata).

Nenhuma senha é hardcoded: a URL vem do ambiente/``.env`` (fora do git).
"""

from __future__ import annotations

from logging.config import fileConfig

from alembic import context
from sqlalchemy import create_engine, pool

from meu_bebe_api.config import get_settings
from meu_bebe_api.db.base import Base

# FASE 8C — importa os models para registrar as tabelas em ``Base.metadata``
# (``target_metadata``). Sem este import, o autogenerate enxergaria metadata
# vazia.
import meu_bebe_api.models  # noqa: E402,F401

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def _get_url() -> str:
    """Resolve a URL da aplicação (a mesma ``DATABASE_URL``, sem duplicação)."""
    url = get_settings().database_url
    if not url:
        raise RuntimeError(
            "DATABASE_URL não configurada — defina a variável de ambiente antes "
            "de executar migrations (o subsistema persistente está inerte)."
        )
    return url


def run_migrations_offline() -> None:
    """Modo 'offline': gera o SQL sem conectar ao banco."""
    context.configure(
        url=_get_url(),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Modo 'online': conecta ao PostgreSQL e aplica as migrations."""
    connectable = create_engine(_get_url(), poolclass=pool.NullPool)

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
