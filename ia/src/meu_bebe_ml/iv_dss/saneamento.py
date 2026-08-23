"""Dimensão Saneamento do IV-DSS.

``D_saneamento = mean(C_agua, C_esgotamento, C_residuos)``, exigindo ao menos
2 dos 3 componentes válidos (docs §8.3). Nenhuma imputação; componentes
ausentes/indeterminados NÃO são substituídos por zero.

Subcomponentes:

* ``C_agua`` = média de 3 subcomponentes (fonte, água encanada, interrupções),
  exigindo ao menos 2 válidos;
* ``C_esgotamento`` = score de ``esgotamento_sanitario``;
* ``C_residuos`` = média dos componentes classificáveis de
  ``frequencia_coleta_lixo`` e ``destino_lixo_sem_coleta``.

``agua_encanada`` é lida de ``itens_residencia`` e atribuída analiticamente a
Saneamento; NÃO é pontuada novamente em Habitação (anti-dupla-contagem).
"""

from __future__ import annotations

from typing import Any, Mapping

from .scoring import mean_of_valid
from .types import (
    ScoreResult,
    analytically_indeterminate,
    missing,
    structural_not_applicable,
    valid,
)

# --- C_agua -----------------------------------------------------------------

# Fonte da água: score 0 para rede pública ou poço/nascente significa apenas
# "nenhuma inadequação identificada pela categoria de fonte isolada segundo
# esta operacionalização" — NÃO é garantia de potabilidade (docs §8.3.1).
_FONTE_MAP: dict[str, float] = {
    "rede_publica": 0.0,
    "poco_nascente": 0.0,
    "carro_pipa": 1.0,
}
# Categorias presentes no schema mas sem score definido nesta operacionalização.
_FONTE_INDETERMINATE: frozenset[str] = frozenset({"cisterna", "outra"})


def score_fonte_agua(fonte_agua: str | None) -> ScoreResult:
    """Score do subcomponente fonte da água."""
    if fonte_agua is None:
        return missing("fonte_agua ausente")
    if fonte_agua in _FONTE_MAP:
        return valid(_FONTE_MAP[fonte_agua])
    if fonte_agua in _FONTE_INDETERMINATE:
        return analytically_indeterminate(
            f"fonte_agua sem score definido: {fonte_agua!r}"
        )
    return analytically_indeterminate(f"fonte_agua desconhecida: {fonte_agua!r}")


def score_agua_encanada(itens_residencia: list[str] | None) -> ScoreResult:
    """Score do subcomponente água encanada (a partir de ``itens_residencia``)."""
    if itens_residencia is None:
        return missing("itens_residencia ausente")
    if not isinstance(itens_residencia, list):
        return analytically_indeterminate(
            f"itens_residencia não é lista: {itens_residencia!r}"
        )
    return valid(0.0 if "agua_encanada" in itens_residencia else 1.0)


def score_interrupcoes_agua(interrupcoes_agua: bool | None) -> ScoreResult:
    """Score do subcomponente interrupções no abastecimento."""
    if interrupcoes_agua is None:
        return missing("interrupcoes_agua ausente")
    if isinstance(interrupcoes_agua, bool):
        return valid(1.0 if interrupcoes_agua else 0.0)
    return analytically_indeterminate(
        f"interrupcoes_agua não booleano: {interrupcoes_agua!r}"
    )


def C_agua(record: Mapping[str, Any]) -> ScoreResult:
    """Componente água: média dos subcomponentes válidos (>= 2 de 3)."""
    subs = [
        score_fonte_agua(record.get("fonte_agua")),
        score_agua_encanada(record.get("itens_residencia")),
        score_interrupcoes_agua(record.get("interrupcoes_agua")),
    ]
    return mean_of_valid(
        subs, min_valid=2, insufficient_reason="C_agua requer ao menos 2 de 3 subcomponentes válidos"
    )


# --- C_esgotamento ----------------------------------------------------------

_ESGOTAMENTO_MAP: dict[str, float] = {
    "rede_coletora": 0.0,
    "fossa_septica": 0.0,
    "ceu_aberto": 1.0,
}


def C_esgotamento(record: Mapping[str, Any]) -> ScoreResult:
    """Componente esgotamento sanitário."""
    esgotamento = record.get("esgotamento_sanitario")
    if esgotamento is None:
        return missing("esgotamento_sanitario ausente")
    if esgotamento in _ESGOTAMENTO_MAP:
        return valid(_ESGOTAMENTO_MAP[esgotamento])
    if esgotamento == "outro":
        return analytically_indeterminate("esgotamento_sanitario == 'outro' não classificado")
    return analytically_indeterminate(f"esgotamento_sanitario desconhecido: {esgotamento!r}")


# --- C_residuos -------------------------------------------------------------

_FREQUENCIA_MAP: dict[str, float] = {
    "regular": 0.0,
    "irregular": 0.5,
    "nao_possui": 1.0,
}

# Destino do lixo sem coleta. ``aguarda_proxima_coleta`` = 0 evita apenas
# penalização adicional; NÃO significa que uma coleta irregular seja ideal.
_DESTINO_MAP: dict[str, float] = {
    "aguarda_proxima_coleta": 0.0,
    "queima": 1.0,
    "enterra": 1.0,
    "terreno_baldio": 1.0,
}


def score_frequencia_residuos(frequencia: str | None) -> ScoreResult:
    """Score do componente frequência de coleta de lixo."""
    if frequencia is None:
        return missing("frequencia_coleta_lixo ausente")
    if frequencia in _FREQUENCIA_MAP:
        return valid(_FREQUENCIA_MAP[frequencia])
    return analytically_indeterminate(f"frequencia_coleta_lixo desconhecida: {frequencia!r}")


def score_destino_residuos(frequencia: str | None, destino: str | None) -> ScoreResult:
    """Score do componente destino do lixo sem coleta.

    Quando ``frequencia == regular``, o destino é ``structural_not_applicable``
    (NÃO é missing penalizador). ``outro`` é analiticamente indeterminado.
    """
    if frequencia == "regular":
        return structural_not_applicable(
            "destino_lixo_sem_coleta não aplicável quando coleta regular"
        )
    if destino is None:
        return missing("destino_lixo_sem_coleta ausente")
    if destino in _DESTINO_MAP:
        return valid(_DESTINO_MAP[destino])
    if destino == "outro":
        return analytically_indeterminate("destino_lixo_sem_coleta == 'outro' não classificado")
    return analytically_indeterminate(f"destino_lixo_sem_coleta desconhecido: {destino!r}")


def C_residuos(record: Mapping[str, Any]) -> ScoreResult:
    """Componente resíduos: média dos componentes classificáveis.

    ``frequencia`` é sempre classificável (quando presente); ``destino`` só entra
    na média se for classificável (excluindo ``outro``/indeterminado e o caso
    ``regular``, em que é estruturalmente não aplicável).
    """
    frequencia = record.get("frequencia_coleta_lixo")
    destino = record.get("destino_lixo_sem_coleta")

    f_score = score_frequencia_residuos(frequencia)
    d_score = score_destino_residuos(frequencia, destino)

    components = []
    if f_score.is_valid:
        components.append(f_score.value)
    if d_score.is_valid:
        components.append(d_score.value)

    if not components:
        return analytically_indeterminate("C_residuos sem componente classificável")
    return valid(sum(components) / len(components))


# --- D_saneamento -----------------------------------------------------------

_SANEAMENTO_INSUFFICIENT_REASON = "D_saneamento requer ao menos 2 de 3 componentes válidos"


def D_saneamento_from(
    c_agua: ScoreResult, c_esgotamento: ScoreResult, c_residuos: ScoreResult
) -> ScoreResult:
    """Agrega os 3 componentes já calculados na dimensão Saneamento (>= 2 de 3)."""
    return mean_of_valid(
        [c_agua, c_esgotamento, c_residuos],
        min_valid=2,
        insufficient_reason=_SANEAMENTO_INSUFFICIENT_REASON,
    )


def D_saneamento(record: Mapping[str, Any]) -> ScoreResult:
    """Dimensão Saneamento = média de C_agua, C_esgotamento, C_residuos (>= 2 de 3)."""
    return D_saneamento_from(C_agua(record), C_esgotamento(record), C_residuos(record))
