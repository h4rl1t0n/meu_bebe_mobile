"""Repository de ``PlanoParto`` (FASE 8H) — SEM ``commit``.

Singleton por gestação: ``find_by_gestacao_id`` é a chave do 1—0..1 (a rota já
valida ownership via ``get_owned_gestacao``). Não há ``delete``: o plano é
editado (nunca removido) pelo app — só GET + PUT (upsert).
"""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models.plano_parto import PlanoParto


class PlanoPartoRepository:
    """Acesso a dados de ``planos_de_parto``. Nenhum método committa."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def find_by_gestacao_id(self, gestacao_id: uuid.UUID) -> PlanoParto | None:
        """O plano da gestação (chave do 1—0..1 com ``GESTAÇÃO``)."""
        return self._session.scalar(
            select(PlanoParto).where(PlanoParto.gestacao_id == gestacao_id)
        )

    def add(self, plano: PlanoParto) -> PlanoParto:
        """Registra o plano na sessão (pendente; sem flush/commit)."""
        self._session.add(plano)
        return plano

    def update(self, plano: PlanoParto, **fields) -> PlanoParto:
        """Aplica os campos editáveis (mutação in-place; sem flush/commit).

        Aceita ``**fields`` (todos mapeados 1:1 ao contrato) para não repetir 28
        argumentos explícitos; o service é o único chamador e passa exatamente os
        campos validados do payload.
        """
        for name, value in fields.items():
            setattr(plano, name, value)
        return plano
