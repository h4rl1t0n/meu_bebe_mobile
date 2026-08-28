"""create consultas and exames

FASE 8F — quarta migration de domínio.

Cria ``consultas`` e ``exames`` (recursos de lista, GESTAÇÃO 1—N) numa única
migration porque fazem parte da MESMA fase funcional. Ambas têm ``gestacao_id``
FK → ``gestacoes.id`` ON DELETE CASCADE + índice. ``data_consulta`` e
``data_exame`` são ``DATE`` (data civil); ``descricao`` é ``TEXT``; ``exames``
carrega ``categoria`` (``VARCHAR(64) NULL``) para o mapeamento legado da 1ª
ultrassonografia. Defaults (UUID v4, timestamps) são aplicados no ORM (Python),
NÃO como ``server_default``.

Revision ID: 0004
Revises: 0003
Create Date: 2026-08-27
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0004"
down_revision: str | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "consultas",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("gestacao_id", sa.Uuid(), nullable=False),
        sa.Column("titulo", sa.String(length=255), nullable=False),
        sa.Column("data_consulta", sa.Date(), nullable=False),
        sa.Column("descricao", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_consultas"),
        sa.ForeignKeyConstraint(
            ["gestacao_id"],
            ["gestacoes.id"],
            name="fk_consultas_gestacao_id_gestacoes",
            ondelete="CASCADE",
        ),
    )
    op.create_index(
        "ix_consultas_gestacao_id",
        "consultas",
        ["gestacao_id"],
        unique=False,
    )
    op.create_table(
        "exames",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("gestacao_id", sa.Uuid(), nullable=False),
        sa.Column("titulo", sa.String(length=255), nullable=False),
        sa.Column("data_exame", sa.Date(), nullable=False),
        sa.Column("descricao", sa.Text(), nullable=False),
        sa.Column("categoria", sa.String(length=64), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_exames"),
        sa.ForeignKeyConstraint(
            ["gestacao_id"],
            ["gestacoes.id"],
            name="fk_exames_gestacao_id_gestacoes",
            ondelete="CASCADE",
        ),
    )
    op.create_index(
        "ix_exames_gestacao_id",
        "exames",
        ["gestacao_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_exames_gestacao_id", table_name="exames")
    op.drop_table("exames")
    op.drop_index("ix_consultas_gestacao_id", table_name="consultas")
    op.drop_table("consultas")
