"""create medicamentos and vacinas

FASE 8G — quinta migration de domínio.

Cria ``medicamentos`` e ``vacinas`` (recursos de lista, GESTAÇÃO 1—N) numa única
migration porque fazem parte da MESMA fase funcional. Ambas têm ``gestacao_id``
FK → ``gestacoes.id`` ON DELETE CASCADE + índice. ``medicamentos`` carrega
``nome``/``dose``/``frequencia`` (VARCHAR(255) NOT NULL); ``vacinas`` carrega
``nome`` (VARCHAR(255) NOT NULL) e ``aplicada`` (BOOLEAN NOT NULL — o ``used``
do Flutter). Defaults (UUID v4, timestamps, aplicada=false) são aplicados no ORM
(Python), NÃO como ``server_default``.

Revision ID: 0005
Revises: 0004
Create Date: 2026-08-27
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0005"
down_revision: str | None = "0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "medicamentos",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("gestacao_id", sa.Uuid(), nullable=False),
        sa.Column("nome", sa.String(length=255), nullable=False),
        sa.Column("dose", sa.String(length=255), nullable=False),
        sa.Column("frequencia", sa.String(length=255), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_medicamentos"),
        sa.ForeignKeyConstraint(
            ["gestacao_id"],
            ["gestacoes.id"],
            name="fk_medicamentos_gestacao_id_gestacoes",
            ondelete="CASCADE",
        ),
    )
    op.create_index(
        "ix_medicamentos_gestacao_id",
        "medicamentos",
        ["gestacao_id"],
        unique=False,
    )
    op.create_table(
        "vacinas",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("gestacao_id", sa.Uuid(), nullable=False),
        sa.Column("nome", sa.String(length=255), nullable=False),
        sa.Column("aplicada", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_vacinas"),
        sa.ForeignKeyConstraint(
            ["gestacao_id"],
            ["gestacoes.id"],
            name="fk_vacinas_gestacao_id_gestacoes",
            ondelete="CASCADE",
        ),
    )
    op.create_index(
        "ix_vacinas_gestacao_id",
        "vacinas",
        ["gestacao_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_vacinas_gestacao_id", table_name="vacinas")
    op.drop_table("vacinas")
    op.drop_index("ix_medicamentos_gestacao_id", table_name="medicamentos")
    op.drop_table("medicamentos")
