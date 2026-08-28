"""Repository de ``Consulta`` (FASE 8F) — SEM ``commit``."""

from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models.consulta import Consulta


class ConsultaRepository:
    """Acesso a dados de ``consultas``. Nenhum método committa."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def list_by_gestacao_id(self, gestacao_id: uuid.UUID) -> list[Consulta]:
        """Consultas da gestação, por data (espelha a ordenação do Flutter)."""
        return list(
            self._session.scalars(
                select(Consulta)
                .where(Consulta.gestacao_id == gestacao_id)
                .order_by(Consulta.data_consulta, Consulta.created_at)
            )
        )

    def find_by_id_and_gestacao(
        self, consulta_id: uuid.UUID, gestacao_id: uuid.UUID
    ) -> Consulta | None:
        """Busca por ``id + gestacao_id`` (ownership embutido na query)."""
        return self._session.scalar(
            select(Consulta).where(
                Consulta.id == consulta_id,
                Consulta.gestacao_id == gestacao_id,
            )
        )

    def add(self, consulta: Consulta) -> Consulta:
        """Registra a ``Consulta`` na sessão (pendente; sem flush/commit)."""
        self._session.add(consulta)
        return consulta

    def update(
        self,
        consulta: Consulta,
        *,
        titulo: str,
        data_consulta: date,
        descricao: str,
    ) -> Consulta:
        """Aplica os campos editáveis (mutação in-place; sem flush/commit)."""
        consulta.titulo = titulo
        consulta.data_consulta = data_consulta
        consulta.descricao = descricao
        return consulta

    def delete(self, consulta: Consulta) -> None:
        """Marca a ``Consulta`` para remoção (DELETE físico; sem commit)."""
        self._session.delete(consulta)
