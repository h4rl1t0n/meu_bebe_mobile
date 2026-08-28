"""Repository de ``Medicamento`` (FASE 8G) — SEM ``commit``."""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models.medicamento import Medicamento


class MedicamentoRepository:
    """Acesso a dados de ``medicamentos``. Nenhum método committa."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def list_by_gestacao_id(self, gestacao_id: uuid.UUID) -> list[Medicamento]:
        """Medicamentos da gestação, por nome (espelha a ordenação do Flutter)."""
        return list(
            self._session.scalars(
                select(Medicamento)
                .where(Medicamento.gestacao_id == gestacao_id)
                .order_by(Medicamento.nome, Medicamento.created_at)
            )
        )

    def find_by_id_and_gestacao(
        self, medicamento_id: uuid.UUID, gestacao_id: uuid.UUID
    ) -> Medicamento | None:
        """Busca por ``id + gestacao_id`` (ownership embutido na query)."""
        return self._session.scalar(
            select(Medicamento).where(
                Medicamento.id == medicamento_id,
                Medicamento.gestacao_id == gestacao_id,
            )
        )

    def add(self, medicamento: Medicamento) -> Medicamento:
        """Registra o ``Medicamento`` na sessão (pendente; sem flush/commit)."""
        self._session.add(medicamento)
        return medicamento

    def update(
        self,
        medicamento: Medicamento,
        *,
        nome: str,
        dose: str,
        frequencia: str,
    ) -> Medicamento:
        """Aplica os campos editáveis (mutação in-place; sem flush/commit)."""
        medicamento.nome = nome
        medicamento.dose = dose
        medicamento.frequencia = frequencia
        return medicamento

    def delete(self, medicamento: Medicamento) -> None:
        """Marca o ``Medicamento`` para remoção (DELETE físico; sem commit)."""
        self._session.delete(medicamento)
