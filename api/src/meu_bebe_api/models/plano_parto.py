"""Modelo ``PlanoParto`` — plano de parto (FASE 8H).

O "Plano de Parto" do Flutter é, na verdade, CINCO singletons locais
(``expectation``, ``birth_moment``, ``birth``, ``pain_relief`` e
``observations``), cada um salvo por UPSERT e exibido num "Resumo do plano de
parto". Aqui eles são CONSOLIDADOS num único recurso SINGLETON por gestação
(GESTAÇÃO 1—0..1, ``gestacao_id`` UNIQUE): todos os campos pertencem ao MESMO
plano, então não há tabela-filha 1—N (diretiva de não criar uma tabela por
classe Dart).

Enums: o Flutter persiste ``.index`` (ordinal) em SQLite; o backend usa STRINGS
ESTÁVEIS (``sim``/``nao``/``nao_sei``, ``profissional``/``acompanhante``/``eu``/
``nao_sei``, etc.), nunca ordinal, e não inventa enum clínico — cada valor mapeia
1:1 o enum do app.

NÃO modela sistema hospitalar (sem equipe médica/hospital/profissional/assinatura/
consentimento/CRM/procedimentos clínicos estruturados). NÃO duplica GESTAÇÃO nem
os demais domínios (histórico, consultas, exames, medicamentos, vacinas, DSS/ML).
"""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base
from ._common import utc_now


class PlanoParto(Base):
    __tablename__ = "planos_de_parto"

    # UUID v4 gerado NO SERVIDOR (Python) — nunca ``gen_random_uuid()``.
    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    # FK UNIQUE → gestacoes.id: garante o 1—0..1 com GESTAÇÃO e o ownership.
    gestacao_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("gestacoes.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )

    # ---- Expectativas (``Alternatives``: sim/nao/nao_sei) ----
    acompanhante: Mapped[str] = mapped_column(String(16), nullable=False)
    raspar_pelos_intimos: Mapped[str] = mapped_column(String(16), nullable=False)
    lavagem_intestinal: Mapped[str] = mapped_column(String(16), nullable=False)
    ambiente_pouca_luz: Mapped[str] = mapped_column(String(16), nullable=False)
    ouvir_musica: Mapped[str] = mapped_column(String(16), nullable=False)
    beber_liquidos: Mapped[str] = mapped_column(String(16), nullable=False)
    registrar_fotos_videos: Mapped[str] = mapped_column(String(16), nullable=False)

    # ---- Momento do parto (``BirthMoment``) ----
    via_parto: Mapped[str] = mapped_column(String(16), nullable=False)
    anestesia: Mapped[str] = mapped_column(String(16), nullable=False)
    corte_vaginal: Mapped[str] = mapped_column(String(16), nullable=False)
    posicao_preferida: Mapped[str | None] = mapped_column(String(32), nullable=True)
    outra_posicao: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # ---- Nascimento (``Birth``) ----
    quem_corta_cordao: Mapped[str] = mapped_column(String(16), nullable=False)
    coleta_celulas_tronco: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    contato_pele_a_pele: Mapped[str] = mapped_column(String(16), nullable=False)
    amamentar_primeira_hora: Mapped[str] = mapped_column(String(16), nullable=False)
    restricoes_amamentacao: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    primeiro_banho: Mapped[str] = mapped_column(String(16), nullable=False)

    # ---- Alívio da dor (``PainRelief``) ----
    quer_alivio_dor: Mapped[str] = mapped_column(String(16), nullable=False)
    massagem: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    exercicios_bola: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    exercicios_respiracao: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    banho_chuveiro: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    banho_banheira: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    acupuntura: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    acupressao: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    outro_metodo: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    # ---- Observações (``Observations``) — TEXT, pode ser vazio ----
    observacoes: Mapped[str] = mapped_column(Text, nullable=False, default="")

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utc_now, onupdate=utc_now
    )
