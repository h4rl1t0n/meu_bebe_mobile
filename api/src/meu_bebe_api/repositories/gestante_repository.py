"""Repository de ``Gestante`` (FASE 8D) — SEM ``commit``."""

from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models.gestante import Gestante


class GestanteRepository:
    """Acesso a dados de ``gestantes``. Nenhum método committa."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def find_by_user_id(self, user_id: uuid.UUID) -> Gestante | None:
        """Busca o perfil do usuário (chave do 1—1 com ``USER``)."""
        return self._session.scalar(
            select(Gestante).where(Gestante.user_id == user_id)
        )

    def add(self, gestante: Gestante) -> Gestante:
        """Registra a ``Gestante`` na sessão (pendente; sem flush/commit)."""
        self._session.add(gestante)
        return gestante

    def update(
        self,
        gestante: Gestante,
        *,
        nome: str,
        nome_social: str | None,
        data_nascimento: date,
        cpf: str | None,
        cns: str | None,
    ) -> Gestante:
        """Aplica os campos editáveis (mutação in-place; sem flush/commit)."""
        gestante.nome = nome
        gestante.nome_social = nome_social
        gestante.data_nascimento = data_nascimento
        gestante.cpf = cpf
        gestante.cns = cns
        return gestante
