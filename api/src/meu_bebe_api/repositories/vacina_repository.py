"""Repository de ``Vacina`` (FASE 8G) — SEM ``commit``.

Não há ``delete``: o Flutter NÃO permite remover vacina (o ``deleteVaccine`` do
repositório Flutter é código morto — o checklist só alterna o estado
``aplicada``). Por isso o backend não inventa DELETE por simetria.
"""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models.vacina import Vacina


class VacinaRepository:
    """Acesso a dados de ``vacinas``. Nenhum método committa."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def list_by_gestacao_id(self, gestacao_id: uuid.UUID) -> list[Vacina]:
        """Vacinas da gestação, por ordem de criação (ordem de checklist)."""
        return list(
            self._session.scalars(
                select(Vacina)
                .where(Vacina.gestacao_id == gestacao_id)
                .order_by(Vacina.created_at, Vacina.id)
            )
        )

    def find_by_id_and_gestacao(
        self, vacina_id: uuid.UUID, gestacao_id: uuid.UUID
    ) -> Vacina | None:
        """Busca por ``id + gestacao_id`` (ownership embutido na query)."""
        return self._session.scalar(
            select(Vacina).where(
                Vacina.id == vacina_id,
                Vacina.gestacao_id == gestacao_id,
            )
        )

    def add(self, vacina: Vacina) -> Vacina:
        """Registra a ``Vacina`` na sessão (pendente; sem flush/commit)."""
        self._session.add(vacina)
        return vacina

    def update(
        self,
        vacina: Vacina,
        *,
        nome: str,
        aplicada: bool,
    ) -> Vacina:
        """Aplica os campos editáveis (mutação in-place; sem flush/commit)."""
        vacina.nome = nome
        vacina.aplicada = aplicada
        return vacina
