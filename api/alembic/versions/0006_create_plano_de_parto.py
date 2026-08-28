"""create plano de parto

FASE 8H — sexta migration de domínio.

Cria ``planos_de_parto`` (plano de parto, GESTAÇÃO 1—0..1, SINGLETON). Consolida
os CINCO singletons locais do Flutter (``expectation``, ``birth_moment``,
``birth``, ``pain_relief``, ``observations``) numa ÚNICA tabela: todos os campos
pertencem ao mesmo plano, então não há tabela-filha 1—N.

``gestacao_id`` é UNIQUE + FK → ``gestacoes.id`` ON DELETE CASCADE (1—0..1). Os
enums viram STRINGS ESTÁVEIS (``VARCHAR``), os booleanos viram ``BOOLEAN``, e as
observações viram ``TEXT``. Defaults (UUID v4, timestamps, bools=false,
observacoes="") são aplicados no ORM (Python), NÃO como ``server_default``.

Revision ID: 0006
Revises: 0005
Create Date: 2026-08-27
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0006"
down_revision: str | None = "0005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "planos_de_parto",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("gestacao_id", sa.Uuid(), nullable=False),
        # Expectativas
        sa.Column("acompanhante", sa.String(length=16), nullable=False),
        sa.Column("raspar_pelos_intimos", sa.String(length=16), nullable=False),
        sa.Column("lavagem_intestinal", sa.String(length=16), nullable=False),
        sa.Column("ambiente_pouca_luz", sa.String(length=16), nullable=False),
        sa.Column("ouvir_musica", sa.String(length=16), nullable=False),
        sa.Column("beber_liquidos", sa.String(length=16), nullable=False),
        sa.Column("registrar_fotos_videos", sa.String(length=16), nullable=False),
        # Momento do parto
        sa.Column("via_parto", sa.String(length=16), nullable=False),
        sa.Column("anestesia", sa.String(length=16), nullable=False),
        sa.Column("corte_vaginal", sa.String(length=16), nullable=False),
        sa.Column("posicao_preferida", sa.String(length=32), nullable=True),
        sa.Column("outra_posicao", sa.String(length=255), nullable=True),
        # Nascimento
        sa.Column("quem_corta_cordao", sa.String(length=16), nullable=False),
        sa.Column("coleta_celulas_tronco", sa.Boolean(), nullable=False),
        sa.Column("contato_pele_a_pele", sa.String(length=16), nullable=False),
        sa.Column("amamentar_primeira_hora", sa.String(length=16), nullable=False),
        sa.Column("restricoes_amamentacao", sa.Boolean(), nullable=False),
        sa.Column("primeiro_banho", sa.String(length=16), nullable=False),
        # Alívio da dor
        sa.Column("quer_alivio_dor", sa.String(length=16), nullable=False),
        sa.Column("massagem", sa.Boolean(), nullable=False),
        sa.Column("exercicios_bola", sa.Boolean(), nullable=False),
        sa.Column("exercicios_respiracao", sa.Boolean(), nullable=False),
        sa.Column("banho_chuveiro", sa.Boolean(), nullable=False),
        sa.Column("banho_banheira", sa.Boolean(), nullable=False),
        sa.Column("acupuntura", sa.Boolean(), nullable=False),
        sa.Column("acupressao", sa.Boolean(), nullable=False),
        sa.Column("outro_metodo", sa.Boolean(), nullable=False),
        # Observações
        sa.Column("observacoes", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_planos_de_parto"),
        sa.UniqueConstraint(
            "gestacao_id", name="uq_planos_de_parto_gestacao_id"
        ),
        sa.ForeignKeyConstraint(
            ["gestacao_id"],
            ["gestacoes.id"],
            name="fk_planos_de_parto_gestacao_id_gestacoes",
            ondelete="CASCADE",
        ),
    )


def downgrade() -> None:
    op.drop_table("planos_de_parto")
