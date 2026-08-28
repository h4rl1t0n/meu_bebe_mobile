"""Contratos do domínio ``PLANO DE PARTO`` (FASE 8H) — escrita e resposta.

O "Plano de Parto" do Flutter é, na verdade, CINCO singletons locais
(``expectation``, ``birth_moment``, ``birth``, ``pain_relief``, ``observations``),
cada um salvo por UPSERT. Aqui eles são CONSOLIDADOS num único recurso SINGLETON
por gestação (GESTAÇÃO 1—0..1): um único ``PUT`` (upsert) substitui o plano.

Enums: o Flutter persiste ``.index`` (ordinal) em SQLite; o backend usa STRINGS
ESTÁVEIS via ``Literal`` — nunca ordinal, e nenhum enum clínico inventado (cada
valor mapeia 1:1 o enum do app).

A entrada NUNCA contém ``id``, ``gestacao_id``, ``user_id``, ``gestante_id`` nem
timestamps (o vínculo é derivado da rota ``/gestacoes/{gestacao_id}/plano-de-parto``,
validada por ownership). A resposta NÃO ecoa ``gestacao_id``.

Strings: ``observacoes`` é texto livre (pode ser vazio; apenas strip). ``outra_posicao``
é opcional e, se vier vazia/só espaços, é normalizada para ``null`` (lição da 8F).
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, field_validator

# ---- Enums como strings estáveis (nunca ordinal) ----
# Tri-state genérico (Alternatives/Anesthesia/VaginalCut/SkinBabyContact/
# BreastfeedFirstHour/NeedPainRelief): "sim" | "nao" | "nao_sei".
TriState = Literal["sim", "nao", "nao_sei"]
# Via de parto (BirthWay).
BirthWay = Literal["vaginal", "cesarea", "nao_sei"]
# Quem corta o cordão / quem dá o primeiro banho (WhoCut/FirstBath).
ActorChoice = Literal["profissional", "acompanhante", "eu", "nao_sei"]
# Posição preferida (Positions).
Position = Literal[
    "deitada",
    "sentada",
    "agachada",
    "de_lado",
    "de_joelhos",
    "em_pe",
    "nao_sei",
    "outra",
]


class PlanoPartoWrite(BaseModel):
    """Payload de escrita do plano (PUT — upsert do singleton)."""

    model_config = ConfigDict(extra="forbid")

    # Expectativas
    acompanhante: TriState
    raspar_pelos_intimos: TriState
    lavagem_intestinal: TriState
    ambiente_pouca_luz: TriState
    ouvir_musica: TriState
    beber_liquidos: TriState
    registrar_fotos_videos: TriState

    # Momento do parto
    via_parto: BirthWay
    anestesia: TriState
    corte_vaginal: TriState
    posicao_preferida: Position | None = None
    outra_posicao: str | None = None

    # Nascimento
    quem_corta_cordao: ActorChoice
    coleta_celulas_tronco: bool
    contato_pele_a_pele: TriState
    amamentar_primeira_hora: TriState
    restricoes_amamentacao: bool
    primeiro_banho: ActorChoice

    # Alívio da dor
    quer_alivio_dor: TriState
    massagem: bool
    exercicios_bola: bool
    exercicios_respiracao: bool
    banho_chuveiro: bool
    banho_banheira: bool
    acupuntura: bool
    acupressao: bool
    outro_metodo: bool

    # Observações (texto livre)
    observacoes: str

    @field_validator("outra_posicao")
    @classmethod
    def _normalize_optional(cls, value: str | None) -> str | None:
        """Opcional: ``null``/``""``/``"   "`` → ``None`` (sem strings vazias)."""
        if value is None:
            return None
        value = value.strip()
        return value or None

    @field_validator("observacoes")
    @classmethod
    def _strip_observacoes(cls, value: str) -> str:
        """Texto livre: apenas strip (vazio é permitido — "sem observações")."""
        return value.strip()


class PlanoPartoResponse(BaseModel):
    """Resposta segura do plano (sem ``gestacao_id``)."""

    model_config = ConfigDict(from_attributes=True, extra="forbid")

    id: uuid.UUID
    acompanhante: str
    raspar_pelos_intimos: str
    lavagem_intestinal: str
    ambiente_pouca_luz: str
    ouvir_musica: str
    beber_liquidos: str
    registrar_fotos_videos: str
    via_parto: str
    anestesia: str
    corte_vaginal: str
    posicao_preferida: str | None
    outra_posicao: str | None
    quem_corta_cordao: str
    coleta_celulas_tronco: bool
    contato_pele_a_pele: str
    amamentar_primeira_hora: str
    restricoes_amamentacao: bool
    primeiro_banho: str
    quer_alivio_dor: str
    massagem: bool
    exercicios_bola: bool
    exercicios_respiracao: bool
    banho_chuveiro: bool
    banho_banheira: bool
    acupuntura: bool
    acupressao: bool
    outro_metodo: bool
    observacoes: str
    created_at: datetime
    updated_at: datetime
