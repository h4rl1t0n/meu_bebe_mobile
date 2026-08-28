"""Repository de ``AvaliacaoDss`` (FASE 8I) — SEM ``commit``.

Snapshot imutável: apenas ``list_by_gestacao_id``, ``find_by_id_and_gestacao`` e
``add``. Não há ``update`` nem ``delete`` — a avaliação enviada é histórica e
append-only. A ordenação da lista é determinística (mais recente primeiro).
"""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models.avaliacao_dss import AvaliacaoDss


class AvaliacaoDssRepository:
    """Acesso a dados de ``avaliacoes_dss``. Nenhum método committa."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def list_by_gestacao_id(self, gestacao_id: uuid.UUID) -> list[AvaliacaoDss]:
        """Avaliações da gestação, da mais recente para a mais antiga.

        ``created_at DESC`` (preferência de UX: avaliação mais recente primeiro);
        ``id DESC`` como critério determinístico de desempate.
        """
        return list(
            self._session.scalars(
                select(AvaliacaoDss)
                .where(AvaliacaoDss.gestacao_id == gestacao_id)
                .order_by(AvaliacaoDss.created_at.desc(), AvaliacaoDss.id.desc())
            )
        )

    def find_by_id_and_gestacao(
        self, avaliacao_id: uuid.UUID, gestacao_id: uuid.UUID
    ) -> AvaliacaoDss | None:
        """Busca por ``id + gestacao_id`` (ownership embutido na query)."""
        return self._session.scalar(
            select(AvaliacaoDss).where(
                AvaliacaoDss.id == avaliacao_id,
                AvaliacaoDss.gestacao_id == gestacao_id,
            )
        )

    def add(self, avaliacao: AvaliacaoDss) -> AvaliacaoDss:
        """Registra a avaliação na sessão (pendente; sem flush/commit)."""
        self._session.add(avaliacao)
        return avaliacao
