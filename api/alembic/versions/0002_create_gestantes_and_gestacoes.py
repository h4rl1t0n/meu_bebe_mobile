"""create gestantes and gestacoes

FASE 8D — segunda migration de domínio (seção 17 do plano).

Cria ``gestantes`` (perfil pessoal, USER 1—1) e ``gestacoes`` (episódio
gestacional, GESTANTE 1—N), na ordem que respeita as FKs. Defaults (UUID v4,
timestamps) são aplicados no ORM (Python), NÃO como ``server_default``.

- ``gestantes.user_id`` é UNIQUE + FK → ``users.id`` ON DELETE CASCADE (1—1).
- ``gestacoes.gestante_id`` é FK → ``gestantes.id`` ON DELETE CASCADE + index.
- Índice único PARCIAL ``uq_gestacoes_active_per_gestante`` (``gestante_id``
  WHERE ``ended_at IS NULL``): garante no máximo UMA gestação ativa por gestante.
- ``data_nascimento`` e ``data_ultima_menstruacao`` são ``DATE``; ``ended_at`` e
  timestamps são ``TIMESTAMPTZ`` (UTC).

Revision ID: 0002
Revises: 0001
Create Date: 2026-08-26
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "gestantes",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("nome", sa.String(length=255), nullable=False),
        sa.Column("nome_social", sa.String(length=255), nullable=True),
        sa.Column("data_nascimento", sa.Date(), nullable=False),
        sa.Column("cpf", sa.String(length=11), nullable=True),
        sa.Column("cns", sa.String(length=15), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_gestantes"),
        sa.UniqueConstraint("user_id", name="uq_gestantes_user_id"),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_gestantes_user_id_users",
            ondelete="CASCADE",
        ),
    )
    op.create_table(
        "gestacoes",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("gestante_id", sa.Uuid(), nullable=False),
        sa.Column("data_ultima_menstruacao", sa.Date(), nullable=True),
        sa.Column("local_pre_natal", sa.String(length=255), nullable=True),
        sa.Column("profissional_pre_natal", sa.String(length=255), nullable=True),
        sa.Column("contato_local_pre_natal", sa.String(length=64), nullable=True),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_gestacoes"),
        sa.ForeignKeyConstraint(
            ["gestante_id"],
            ["gestantes.id"],
            name="fk_gestacoes_gestante_id_gestantes",
            ondelete="CASCADE",
        ),
    )
    op.create_index(
        "ix_gestacoes_gestante_id",
        "gestacoes",
        ["gestante_id"],
        unique=False,
    )
    op.create_index(
        "uq_gestacoes_active_per_gestante",
        "gestacoes",
        ["gestante_id"],
        unique=True,
        postgresql_where=sa.text("ended_at IS NULL"),
    )


def downgrade() -> None:
    op.drop_index("uq_gestacoes_active_per_gestante", table_name="gestacoes")
    op.drop_index("ix_gestacoes_gestante_id", table_name="gestacoes")
    op.drop_table("gestacoes")
    op.drop_table("gestantes")
