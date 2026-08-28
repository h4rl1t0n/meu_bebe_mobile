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

from ..contracts.consulta import ConsultaWrite
from ..contracts.exame import ExameWrite
from ..contracts.gestacao import GestacaoWrite
from ..contracts.gestante import GestanteWrite
from ..contracts.historico_obstetrico import HistoricoObstetricoWrite
from ..contracts.medicamento import MedicamentoWrite
from ..contracts.vacina import VacinaWrite
from ..models.consulta import Consulta
from ..models.exame import Exame
from ..models.gestacao import Gestacao
from ..models.gestante import Gestante
from ..models.historico_obstetrico import HistoricoObstetrico
from ..models.medicamento import Medicamento
from ..models.vacina import Vacina
from ..repositories.consulta_repository import ConsultaRepository
from ..repositories.exame_repository import ExameRepository
from ..repositories.gestacao_repository import GestacaoRepository
from ..repositories.gestante_repository import GestanteRepository
from ..repositories.historico_obstetrico_repository import HistoricoObstetricoRepository
from ..repositories.medicamento_repository import MedicamentoRepository
from ..repositories.vacina_repository import VacinaRepository
from .errors import (
    ACTIVE_PREGNANCY_ALREADY_EXISTS,
    ACTIVE_PREGNANCY_ALREADY_EXISTS_MESSAGE,
    CONSULTA_NOT_FOUND,
    CONSULTA_NOT_FOUND_MESSAGE,
    DATABASE_UNAVAILABLE,
    DATABASE_UNAVAILABLE_MESSAGE,
    DOMAIN_ERROR,
    DOMAIN_ERROR_MESSAGE,
    EXAME_NOT_FOUND,
    EXAME_NOT_FOUND_MESSAGE,
    MEDICAMENTO_NOT_FOUND,
    MEDICAMENTO_NOT_FOUND_MESSAGE,
    OBSTETRIC_HISTORY_NOT_FOUND,
    OBSTETRIC_HISTORY_NOT_FOUND_MESSAGE,
    PREGNANCY_NOT_FOUND,
    PREGNANCY_NOT_FOUND_MESSAGE,
    PREGNANCY_REOPEN_NOT_ALLOWED,
    PREGNANCY_REOPEN_NOT_ALLOWED_MESSAGE,
    PROFILE_ALREADY_EXISTS,
    PROFILE_ALREADY_EXISTS_MESSAGE,
    VACINA_NOT_FOUND,
    VACINA_NOT_FOUND_MESSAGE,
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


class HistoricoObstetricoService:
    """Regras do histórico obstétrico: GET e UPSERT (1—1)."""

    def __init__(self, session: Session) -> None:
        self._session = session
        self._historico = HistoricoObstetricoRepository(session)

    def get(self, gestante_id: uuid.UUID) -> HistoricoObstetrico:
        """O histórico da gestante, ou 404 ``OBSTETRIC_HISTORY_NOT_FOUND``."""
        try:
            historico = self._historico.find_by_gestante_id(gestante_id)
        except OperationalError:
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        if historico is None:
            raise DomainError(
                OBSTETRIC_HISTORY_NOT_FOUND, OBSTETRIC_HISTORY_NOT_FOUND_MESSAGE, 404
            )
        return historico

    def _apply(
        self, historico: HistoricoObstetrico, payload: HistoricoObstetricoWrite
    ) -> HistoricoObstetrico:
        """Aplica o payload ao histórico (via ``repository.update``).

        Reutilizado no caminho normal e na recuperação de corrida — evita
        duplicar os três campos em dois blocos distintos.
        """
        return self._historico.update(
            historico,
            pregnancy_number=payload.pregnancy_number,
            given_birth_number=payload.given_birth_number,
            abortions_number=payload.abortions_number,
        )

    def upsert(
        self, gestante_id: uuid.UUID, payload: HistoricoObstetricoWrite
    ) -> HistoricoObstetrico:
        """Cria (se ausente) ou atualiza (se existente) o histórico e committa.

        Corrida de UPSERT (duas requisições ``find``→``None`` concorrentes): o
        ``IntegrityError`` do UNIQUE dispara rollback + UMA re-busca do singleton
        vencedor + aplicação do payload nele (sem loop/retry, sem ``ON CONFLICT``,
        sem lock explícito). O ``id`` e o ``created_at`` do vencedor são preservados.
        """
        try:
            historico = self._historico.find_by_gestante_id(gestante_id)
            if historico is None:
                historico = HistoricoObstetrico(gestante_id=gestante_id)
                self._apply(historico, payload)
                self._historico.add(historico)
            else:
                self._apply(historico, payload)
            self._session.flush()
            self._session.commit()
        except IntegrityError:
            # UNIQUE(gestante_id): outra requisição criou o singleton entre o
            # find e o INSERT. Recupera re-aplicando o payload à linha vencedora.
            self._session.rollback()
            historico = self._historico.find_by_gestante_id(gestante_id)
            if historico is None:
                raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None
            self._apply(historico, payload)
            self._session.flush()
            self._session.commit()
        except OperationalError:
            self._session.rollback()
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None
        return historico


class ConsultaService:
    """Regras de consulta: CRUD de lista + ownership (FASE 8F).

    O ``gestacao_id`` já chega validado por ownership (``get_owned_gestacao``):
    a gestação pertence à gestante autenticada. Ainda assim, GET/PUT/DELETE
    buscam por ``consulta_id + gestacao_id`` (defense in depth).
    """

    def __init__(self, session: Session) -> None:
        self._session = session
        self._consultas = ConsultaRepository(session)

    def list(self, gestacao_id: uuid.UUID) -> list[Consulta]:
        try:
            return self._consultas.list_by_gestacao_id(gestacao_id)
        except OperationalError:
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None

    def get(self, gestacao_id: uuid.UUID, consulta_id: uuid.UUID) -> Consulta:
        """A consulta da gestação, ou 404 ``CONSULTA_NOT_FOUND``."""
        try:
            consulta = self._consultas.find_by_id_and_gestacao(consulta_id, gestacao_id)
        except OperationalError:
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        if consulta is None:
            raise DomainError(CONSULTA_NOT_FOUND, CONSULTA_NOT_FOUND_MESSAGE, 404)
        return consulta

    def create(self, gestacao_id: uuid.UUID, payload: ConsultaWrite) -> Consulta:
        try:
            consulta = Consulta(
                gestacao_id=gestacao_id,
                titulo=payload.titulo,
                data_consulta=payload.data_consulta,
                descricao=payload.descricao,
            )
            self._consultas.add(consulta)
            self._session.flush()
            self._session.commit()
        except OperationalError:
            self._session.rollback()
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None
        return consulta

    def update(
        self,
        gestacao_id: uuid.UUID,
        consulta_id: uuid.UUID,
        payload: ConsultaWrite,
    ) -> Consulta:
        try:
            consulta = self._consultas.find_by_id_and_gestacao(consulta_id, gestacao_id)
            if consulta is None:
                raise DomainError(CONSULTA_NOT_FOUND, CONSULTA_NOT_FOUND_MESSAGE, 404)
            self._consultas.update(
                consulta,
                titulo=payload.titulo,
                data_consulta=payload.data_consulta,
                descricao=payload.descricao,
            )
            self._session.flush()
            self._session.commit()
        except DomainError:
            self._session.rollback()
            raise
        except OperationalError:
            self._session.rollback()
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None
        return consulta

    def delete(self, gestacao_id: uuid.UUID, consulta_id: uuid.UUID) -> None:
        try:
            consulta = self._consultas.find_by_id_and_gestacao(consulta_id, gestacao_id)
            if consulta is None:
                raise DomainError(CONSULTA_NOT_FOUND, CONSULTA_NOT_FOUND_MESSAGE, 404)
            self._consultas.delete(consulta)
            self._session.commit()
        except DomainError:
            self._session.rollback()
            raise
        except OperationalError:
            self._session.rollback()
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None


class ExameService:
    """Regras de exame: CRUD de lista + ownership (FASE 8F).

    Igual a ``ConsultaService``, com o campo opcional ``categoria`` (string livre)
    reservado ao mapeamento legado da 1ª ultrassonografia.
    """

    def __init__(self, session: Session) -> None:
        self._session = session
        self._exames = ExameRepository(session)

    def list(self, gestacao_id: uuid.UUID) -> list[Exame]:
        try:
            return self._exames.list_by_gestacao_id(gestacao_id)
        except OperationalError:
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None

    def get(self, gestacao_id: uuid.UUID, exame_id: uuid.UUID) -> Exame:
        """O exame da gestação, ou 404 ``EXAME_NOT_FOUND``."""
        try:
            exame = self._exames.find_by_id_and_gestacao(exame_id, gestacao_id)
        except OperationalError:
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        if exame is None:
            raise DomainError(EXAME_NOT_FOUND, EXAME_NOT_FOUND_MESSAGE, 404)
        return exame

    def create(self, gestacao_id: uuid.UUID, payload: ExameWrite) -> Exame:
        try:
            exame = Exame(
                gestacao_id=gestacao_id,
                titulo=payload.titulo,
                data_exame=payload.data_exame,
                descricao=payload.descricao,
                categoria=payload.categoria,
            )
            self._exames.add(exame)
            self._session.flush()
            self._session.commit()
        except OperationalError:
            self._session.rollback()
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None
        return exame

    def update(
        self,
        gestacao_id: uuid.UUID,
        exame_id: uuid.UUID,
        payload: ExameWrite,
    ) -> Exame:
        try:
            exame = self._exames.find_by_id_and_gestacao(exame_id, gestacao_id)
            if exame is None:
                raise DomainError(EXAME_NOT_FOUND, EXAME_NOT_FOUND_MESSAGE, 404)
            self._exames.update(
                exame,
                titulo=payload.titulo,
                data_exame=payload.data_exame,
                descricao=payload.descricao,
                categoria=payload.categoria,
            )
            self._session.flush()
            self._session.commit()
        except DomainError:
            self._session.rollback()
            raise
        except OperationalError:
            self._session.rollback()
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None
        return exame

    def delete(self, gestacao_id: uuid.UUID, exame_id: uuid.UUID) -> None:
        try:
            exame = self._exames.find_by_id_and_gestacao(exame_id, gestacao_id)
            if exame is None:
                raise DomainError(EXAME_NOT_FOUND, EXAME_NOT_FOUND_MESSAGE, 404)
            self._exames.delete(exame)
            self._session.commit()
        except DomainError:
            self._session.rollback()
            raise
        except OperationalError:
            self._session.rollback()
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None


class MedicamentoService:
    """Regras de medicamento: CRUD de lista + ownership (FASE 8G).

    O ``gestacao_id`` já chega validado por ownership (``get_owned_gestacao``):
    a gestação pertence à gestante autenticada. Ainda assim, GET/PUT/DELETE
    buscam por ``medicamento_id + gestacao_id`` (defense in depth).
    """

    def __init__(self, session: Session) -> None:
        self._session = session
        self._medicamentos = MedicamentoRepository(session)

    def list(self, gestacao_id: uuid.UUID) -> list[Medicamento]:
        try:
            return self._medicamentos.list_by_gestacao_id(gestacao_id)
        except OperationalError:
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None

    def get(self, gestacao_id: uuid.UUID, medicamento_id: uuid.UUID) -> Medicamento:
        """O medicamento da gestação, ou 404 ``MEDICAMENTO_NOT_FOUND``."""
        try:
            medicamento = self._medicamentos.find_by_id_and_gestacao(
                medicamento_id, gestacao_id
            )
        except OperationalError:
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        if medicamento is None:
            raise DomainError(
                MEDICAMENTO_NOT_FOUND, MEDICAMENTO_NOT_FOUND_MESSAGE, 404
            )
        return medicamento

    def create(self, gestacao_id: uuid.UUID, payload: MedicamentoWrite) -> Medicamento:
        try:
            medicamento = Medicamento(
                gestacao_id=gestacao_id,
                nome=payload.nome,
                dose=payload.dose,
                frequencia=payload.frequencia,
            )
            self._medicamentos.add(medicamento)
            self._session.flush()
            self._session.commit()
        except OperationalError:
            self._session.rollback()
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None
        return medicamento

    def update(
        self,
        gestacao_id: uuid.UUID,
        medicamento_id: uuid.UUID,
        payload: MedicamentoWrite,
    ) -> Medicamento:
        try:
            medicamento = self._medicamentos.find_by_id_and_gestacao(
                medicamento_id, gestacao_id
            )
            if medicamento is None:
                raise DomainError(
                    MEDICAMENTO_NOT_FOUND, MEDICAMENTO_NOT_FOUND_MESSAGE, 404
                )
            self._medicamentos.update(
                medicamento,
                nome=payload.nome,
                dose=payload.dose,
                frequencia=payload.frequencia,
            )
            self._session.flush()
            self._session.commit()
        except DomainError:
            self._session.rollback()
            raise
        except OperationalError:
            self._session.rollback()
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None
        return medicamento

    def delete(self, gestacao_id: uuid.UUID, medicamento_id: uuid.UUID) -> None:
        try:
            medicamento = self._medicamentos.find_by_id_and_gestacao(
                medicamento_id, gestacao_id
            )
            if medicamento is None:
                raise DomainError(
                    MEDICAMENTO_NOT_FOUND, MEDICAMENTO_NOT_FOUND_MESSAGE, 404
                )
            self._medicamentos.delete(medicamento)
            self._session.commit()
        except DomainError:
            self._session.rollback()
            raise
        except OperationalError:
            self._session.rollback()
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None


class VacinaService:
    """Regras de vacina: CRUD de lista + ownership, SEM delete (FASE 8G).

    O Flutter não remove vacina (o ``deleteVaccine`` do repositório é código
    morto); o checklist apenas alterna ``aplicada`` via update. Por isso não há
    DELETE aqui (não inventar endpoint por simetria).
    """

    def __init__(self, session: Session) -> None:
        self._session = session
        self._vacinas = VacinaRepository(session)

    def list(self, gestacao_id: uuid.UUID) -> list[Vacina]:
        try:
            return self._vacinas.list_by_gestacao_id(gestacao_id)
        except OperationalError:
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None

    def get(self, gestacao_id: uuid.UUID, vacina_id: uuid.UUID) -> Vacina:
        """A vacina da gestação, ou 404 ``VACINA_NOT_FOUND``."""
        try:
            vacina = self._vacinas.find_by_id_and_gestacao(vacina_id, gestacao_id)
        except OperationalError:
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        if vacina is None:
            raise DomainError(VACINA_NOT_FOUND, VACINA_NOT_FOUND_MESSAGE, 404)
        return vacina

    def create(self, gestacao_id: uuid.UUID, payload: VacinaWrite) -> Vacina:
        try:
            vacina = Vacina(
                gestacao_id=gestacao_id,
                nome=payload.nome,
                aplicada=payload.aplicada,
            )
            self._vacinas.add(vacina)
            self._session.flush()
            self._session.commit()
        except OperationalError:
            self._session.rollback()
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None
        return vacina

    def update(
        self,
        gestacao_id: uuid.UUID,
        vacina_id: uuid.UUID,
        payload: VacinaWrite,
    ) -> Vacina:
        try:
            vacina = self._vacinas.find_by_id_and_gestacao(vacina_id, gestacao_id)
            if vacina is None:
                raise DomainError(VACINA_NOT_FOUND, VACINA_NOT_FOUND_MESSAGE, 404)
            self._vacinas.update(
                vacina,
                nome=payload.nome,
                aplicada=payload.aplicada,
            )
            self._session.flush()
            self._session.commit()
        except DomainError:
            self._session.rollback()
            raise
        except OperationalError:
            self._session.rollback()
            raise DomainError(
                DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE, 503
            ) from None
        except Exception:  # noqa: BLE001 — sanitizado
            self._session.rollback()
            raise DomainError(DOMAIN_ERROR, DOMAIN_ERROR_MESSAGE, 500) from None
        return vacina
