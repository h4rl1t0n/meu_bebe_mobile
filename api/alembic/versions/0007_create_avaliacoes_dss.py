"""create avaliacoes dss

FASE 8I — sétima migration de domínio.

Cria ``avaliacoes_dss`` (snapshot imutável do questionário DSS, GESTAÇÃO 1—N).
Cada envio operacional é um snapshot HISTÓRICO append-only: ``gestacao_id`` FK →
``gestacoes.id`` ON DELETE CASCADE + índice (lista, não-singleton). As 48
respostas são persistidas como JSONB (``respostas``), com ``schema_version`` em
coluna própria e ``created_at`` TIMESTAMPTZ registrado pelo servidor.

NÃO há ``updated_at`` (recurso imutável). NÃO há target (``descontinuou_pre_natal``),
probabilidade do RF, IV-DSS, threshold ou classe de risco — a persistência
operacional é separada da IA experimental. Defaults (UUID v4, timestamps) são
aplicados no ORM (Python), NÃO como ``server_default``.

Revision ID: 0007
Revises: 0006
Create Date: 2026-08-27
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0007"
down_revision: str | None = "0006"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "avaliacoes_dss",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("gestacao_id", sa.Uuid(), nullable=False),
        sa.Column("schema_version", sa.String(length=16), nullable=False),
        sa.Column("respostas", postgresql.JSONB(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_avaliacoes_dss"),
        sa.ForeignKeyConstraint(
            ["gestacao_id"],
            ["gestacoes.id"],
            name="fk_avaliacoes_dss_gestacao_id_gestacoes",
            ondelete="CASCADE",
        ),
    )
    op.create_index(
        "ix_avaliacoes_dss_gestacao_id",
        "avaliacoes_dss",
        ["gestacao_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_avaliacoes_dss_gestacao_id", table_name="avaliacoes_dss")
    op.drop_table("avaliacoes_dss")
