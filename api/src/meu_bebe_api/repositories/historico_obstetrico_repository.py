"""Repository de ``HistoricoObstetrico`` (FASE 8E) — SEM ``commit``."""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models.historico_obstetrico import HistoricoObstetrico


class HistoricoObstetricoRepository:
    """Acesso a dados de ``historicos_obstetricos``. Nenhum método committa."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def find_by_gestante_id(
        self, gestante_id: uuid.UUID
    ) -> HistoricoObstetrico | None:
        """Busca o histórico da gestante (chave do 1—1 com ``GESTANTE``)."""
        return self._session.scalar(
            select(HistoricoObstetrico).where(
                HistoricoObstetrico.gestante_id == gestante_id
            )
        )

    def add(self, historico: HistoricoObstetrico) -> HistoricoObstetrico:
        """Registra o histórico na sessão (pendente; sem flush/commit)."""
        self._session.add(historico)
        return historico

    def update(
        self,
        historico: HistoricoObstetrico,
        *,
        pregnancy_number: int | None,
        given_birth_number: int | None,
        abortions_number: int | None,
    ) -> HistoricoObstetrico:
        """Aplica os campos editáveis (mutação in-place; sem flush/commit)."""
        historico.pregnancy_number = pregnancy_number
        historico.given_birth_number = given_birth_number
        historico.abortions_number = abortions_number
        return historico
