"""Repository de ``Gestacao`` (FASE 8D) — SEM ``commit``."""

from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models.gestacao import Gestacao


class GestacaoRepository:
    """Acesso a dados de ``gestacoes``. Nenhum método committa."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def find_active_by_gestante_id(self, gestante_id: uuid.UUID) -> Gestacao | None:
        """A gestação ativa (``ended_at IS NULL``) da gestante, ou ``None``."""
        return self._session.scalar(
            select(Gestacao).where(
                Gestacao.gestante_id == gestante_id,
                Gestacao.ended_at.is_(None),
            )
        )

    def list_by_gestante_id(self, gestante_id: uuid.UUID) -> list[Gestacao]:
        """Todas as gestações da gestante, em ordem de criação."""
        return list(
            self._session.scalars(
                select(Gestacao)
                .where(Gestacao.gestante_id == gestante_id)
                .order_by(Gestacao.created_at)
            )
        )

    def find_by_id_and_gestante(
        self, gestacao_id: uuid.UUID, gestante_id: uuid.UUID
    ) -> Gestacao | None:
        """Busca por id E gestante (ownership embutido na query)."""
        return self._session.scalar(
            select(Gestacao).where(
                Gestacao.id == gestacao_id,
                Gestacao.gestante_id == gestante_id,
            )
        )

    def add(self, gestacao: Gestacao) -> Gestacao:
        """Registra a ``Gestacao`` na sessão (pendente; sem flush/commit)."""
        self._session.add(gestacao)
        return gestacao

    def update(
        self,
        gestacao: Gestacao,
        *,
        data_ultima_menstruacao: date | None,
        local_pre_natal: str | None,
        profissional_pre_natal: str | None,
        contato_local_pre_natal: str | None,
        ended_at: datetime | None,
    ) -> Gestacao:
        """Aplica os campos editáveis (mutação in-place; sem flush/commit)."""
        gestacao.data_ultima_menstruacao = data_ultima_menstruacao
        gestacao.local_pre_natal = local_pre_natal
        gestacao.profissional_pre_natal = profissional_pre_natal
        gestacao.contato_local_pre_natal = contato_local_pre_natal
        gestacao.ended_at = ended_at
        return gestacao
