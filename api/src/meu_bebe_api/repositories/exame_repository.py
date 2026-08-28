"""Repository de ``Exame`` (FASE 8F) — SEM ``commit``."""

from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models.exame import Exame


class ExameRepository:
    """Acesso a dados de ``exames``. Nenhum método committa."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def list_by_gestacao_id(self, gestacao_id: uuid.UUID) -> list[Exame]:
        """Exames da gestação, por data (espelha a ordenação do Flutter)."""
        return list(
            self._session.scalars(
                select(Exame)
                .where(Exame.gestacao_id == gestacao_id)
                .order_by(Exame.data_exame, Exame.created_at)
            )
        )

    def find_by_id_and_gestacao(
        self, exame_id: uuid.UUID, gestacao_id: uuid.UUID
    ) -> Exame | None:
        """Busca por ``id + gestacao_id`` (ownership embutido na query)."""
        return self._session.scalar(
            select(Exame).where(
                Exame.id == exame_id,
                Exame.gestacao_id == gestacao_id,
            )
        )

    def add(self, exame: Exame) -> Exame:
        """Registra o ``Exame`` na sessão (pendente; sem flush/commit)."""
        self._session.add(exame)
        return exame

    def update(
        self,
        exame: Exame,
        *,
        titulo: str,
        data_exame: date,
        descricao: str,
        categoria: str | None,
    ) -> Exame:
        """Aplica os campos editáveis (mutação in-place; sem flush/commit)."""
        exame.titulo = titulo
        exame.data_exame = data_exame
        exame.descricao = descricao
        exame.categoria = categoria
        return exame

    def delete(self, exame: Exame) -> None:
        """Marca o ``Exame`` para remoção (DELETE físico; sem commit)."""
        self._session.delete(exame)
