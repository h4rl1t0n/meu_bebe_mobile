"""create historicos_obstetricos

FASE 8E — terceira migration de domínio.

Cria ``historicos_obstetricos`` (histórico obstétrico, GESTANTE 1—1). Três
contagens opcionais (``pregnancy_number``, ``given_birth_number``,
``abortions_number``), todas ``INTEGER NULL``. ``gestante_id`` é UNIQUE + FK →
``gestantes.id`` ON DELETE CASCADE (1—1). Defaults (UUID v4, timestamps) são
aplicados no ORM (Python), NÃO como ``server_default``.

Revision ID: 0003
Revises: 0002
Create Date: 2026-08-27
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0003"
down_revision: str | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "historicos_obstetricos",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("gestante_id", sa.Uuid(), nullable=False),
        sa.Column("pregnancy_number", sa.Integer(), nullable=True),
        sa.Column("given_birth_number", sa.Integer(), nullable=True),
        sa.Column("abortions_number", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_historicos_obstetricos"),
        sa.UniqueConstraint(
            "gestante_id", name="uq_historicos_obstetricos_gestante_id"
        ),
        sa.ForeignKeyConstraint(
            ["gestante_id"],
            ["gestantes.id"],
            name="fk_historicos_obstetricos_gestante_id_gestantes",
            ondelete="CASCADE",
        ),
    )


def downgrade() -> None:
    op.drop_table("historicos_obstetricos")
