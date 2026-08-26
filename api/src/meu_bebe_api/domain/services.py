"""Services do domínio GESTANTE/GESTAÇÃO (FASE 8D).

O service é o ÚNICO dono de ``commit``/``rollback`` (arquitetura 8B): uma escrita
= uma unidade de trabalho atômica. Os repositories NÃO committam.

Regras de negócio concentradas aqui:
- GESTANTE 1—1 USER (criação idempotente controlada → 409 se já existe).
- GESTANTE 1—N GESTAÇÃO, com UMA única ativa (``ended_at IS NULL``), garantida
  pelo service + índice único parcial.
- Transição ``ended_at``: ATIVA→ENCERRADA permitida via PUT; reabertura
  (ENCERRADA→ATIVA, ``timestamp → NULL``) PROIBIDA.
- Ownership: a gestação é sempre buscada por ``id + gestante_id``.
"""

from __future__ import annotations

import uuid

from sqlalchemy.exc import IntegrityError, OperationalError
from sqlalchemy.orm import Session

from ..contracts.gestacao import GestacaoWrite
from ..contracts.gestante import GestanteWrite
from ..models.gestacao import Gestacao
from ..models.gestante import Gestante
from ..repositories.gestacao_repository import GestacaoRepository
from ..repositories.gestante_repository import GestanteRepository
from .errors import (
    ACTIVE_PREGNANCY_ALREADY_EXISTS,
    ACTIVE_PREGNANCY_ALREADY_EXISTS_MESSAGE,
    DATABASE_UNAVAILABLE,
    DATABASE_UNAVAILABLE_MESSAGE,
    DOMAIN_ERROR,
    DOMAIN_ERROR_MESSAGE,
    PREGNANCY_NOT_FOUND,
    PREGNANCY_NOT_FOUND_MESSAGE,
    PREGNANCY_REOPEN_NOT_ALLOWED,
    PREGNANCY_REOPEN_NOT_ALLOWED_MESSAGE,
    PROFILE_ALREADY_EXISTS,
    PROFILE_ALREADY_EXISTS_MESSAGE,
    DomainError,
)


class GestanteService:
    """Regras de criação/atualização do perfil ``GESTANTE``."""

    def __init__(self, session: Session) -> None:
        self._session = session
        self._gestantes = GestanteRepository(session)

    def create(self, user_id: uuid.UUID, payload: GestanteWrite) -> Gestante:
        """Cria o perfil 1—1 do usuário (409 se já existir)."""
        try:
            if self._gestantes.find_by_user_id(user_id) is not None:
                raise DomainError(PROFILE_ALREADY_EXISTS, PROFILE_ALREADY_EXISTS_MESSAGE, 409)
            gestante = Gestante(
                user_id=user_id,
                nome=payload.nome,
                nome_social=payload.nome_social,
                data_nascimento=payload.data_nascimento,
                cpf=payload.cpf,
                cns=payload.cns,
            )
            self._gestantes.add(gestante)
            self._session.flush()  # garante ``id`` antes do commit
            self._session.commit()
        except DomainError:
            self._session.rollback()
            raise
        except IntegrityError:
            self._session.rollback()
            raise DomainError(PROFILE_ALREADY_EXISTS, PROFILE_ALREADY_EXISTS_MESSAGE, 409) from None
        except OperationalError:
            self._session.rollback()
            raise DomainError(DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None
        return gestante

    def update(self, gestante: Gestante, payload: GestanteWrite) -> Gestante:
        """Atualiza o perfil (full update) e committa."""
        try:
            self._gestantes.update(
                gestante,
                nome=payload.nome,
                nome_social=payload.nome_social,
                data_nascimento=payload.data_nascimento,
                cpf=payload.cpf,
                cns=payload.cns,
            )
            self._session.flush()
            self._session.commit()
        except OperationalError:
            self._session.rollback()
            raise DomainError(DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None
        return gestante


class GestacaoService:
    """Regras de gestação: ownership, ativa única, transição ``ended_at``."""

    def __init__(self, session: Session) -> None:
        self._session = session
        self._gestacoes = GestacaoRepository(session)

    def create(self, gestante_id: uuid.UUID, payload: GestacaoWrite) -> Gestacao:
        """Cria uma gestação ATIVA (409 se já houver ativa)."""
        try:
            if self._gestacoes.find_active_by_gestante_id(gestante_id) is not None:
                raise DomainError(
                    ACTIVE_PREGNANCY_ALREADY_EXISTS,
                    ACTIVE_PREGNANCY_ALREADY_EXISTS_MESSAGE,
                    409,
                )
            gestacao = Gestacao(
                gestante_id=gestante_id,
                data_ultima_menstruacao=payload.data_ultima_menstruacao,
                local_pre_natal=payload.local_pre_natal,
                profissional_pre_natal=payload.profissional_pre_natal,
                contato_local_pre_natal=payload.contato_local_pre_natal,
                ended_at=None,  # toda gestação nasce ATIVA (POST ignora ended_at)
            )
            self._gestacoes.add(gestacao)
            self._session.flush()
            self._session.commit()
        except DomainError:
            self._session.rollback()
            raise
        except IntegrityError:
            self._session.rollback()
            raise DomainError(
                ACTIVE_PREGNANCY_ALREADY_EXISTS,
                ACTIVE_PREGNANCY_ALREADY_EXISTS_MESSAGE,
                409,
            ) from None
        except OperationalError:
            self._session.rollback()
            raise DomainError(DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None
        return gestacao

    def list_gestacoes(self, gestante_id: uuid.UUID) -> list[Gestacao]:
        try:
            return self._gestacoes.list_by_gestante_id(gestante_id)
        except OperationalError:
            raise DomainError(DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503) from None

    def get_atual(self, gestante_id: uuid.UUID) -> Gestacao:
        """A gestação ativa da gestante, ou 404."""
        try:
            gestacao = self._gestacoes.find_active_by_gestante_id(gestante_id)
        except OperationalError:
            raise DomainError(DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503) from None
        if gestacao is None:
            raise DomainError(PREGNANCY_NOT_FOUND, PREGNANCY_NOT_FOUND_MESSAGE, 404)
        return gestacao

    def get_by_id(self, gestante_id: uuid.UUID, gestacao_id: uuid.UUID) -> Gestacao:
        """Busca por ``id + gestante_id`` (ownership); 404 se não for dela."""
        try:
            gestacao = self._gestacoes.find_by_id_and_gestante(gestacao_id, gestante_id)
        except OperationalError:
            raise DomainError(DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503) from None
        if gestacao is None:
            raise DomainError(PREGNANCY_NOT_FOUND, PREGNANCY_NOT_FOUND_MESSAGE, 404)
        return gestacao

    def update(
        self,
        gestante_id: uuid.UUID,
        gestacao_id: uuid.UUID,
        payload: GestacaoWrite,
    ) -> Gestacao:
        """Edita a gestação (ownership) com regra de transição de ``ended_at``."""
        try:
            gestacao = self._gestacoes.find_by_id_and_gestante(gestacao_id, gestante_id)
            if gestacao is None:
                raise DomainError(PREGNANCY_NOT_FOUND, PREGNANCY_NOT_FOUND_MESSAGE, 404)
            # Reabertura PROIBIDA na 8D: encerrada (ended_at preenchido) não pode
            # voltar a ativa (ended_at = null). Distingue "campo AUSENTE" de
            # "null EXPLÍCITO" via model_fields_set: somente o null EXPLÍCITO é
            # tratado como tentativa de reabertura.
            if (
                gestacao.ended_at is not None
                and "ended_at" in payload.model_fields_set
                and payload.ended_at is None
            ):
                raise DomainError(
                    PREGNANCY_REOPEN_NOT_ALLOWED,
                    PREGNANCY_REOPEN_NOT_ALLOWED_MESSAGE,
                    409,
                )
            # ended_at AUSENTE → preserva o valor atual (edição parcial legítima
            # de uma gestação encerrada); PRESENTE → aplica o valor (encerrar,
            # ou editar a data de encerramento). Sem trocar PUT por PATCH.
            effective_ended_at = (
                payload.ended_at
                if "ended_at" in payload.model_fields_set
                else gestacao.ended_at
            )
            self._gestacoes.update(
                gestacao,
                data_ultima_menstruacao=payload.data_ultima_menstruacao,
                local_pre_natal=payload.local_pre_natal,
                profissional_pre_natal=payload.profissional_pre_natal,
                contato_local_pre_natal=payload.contato_local_pre_natal,
                ended_at=effective_ended_at,
            )
            self._session.flush()
            self._session.commit()
        except DomainError:
            self._session.rollback()
            raise
        except OperationalError:
            self._session.rollback()
            raise DomainError(DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None
        return gestacao
