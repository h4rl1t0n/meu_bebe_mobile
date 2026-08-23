"""Índice de Vulnerabilidade baseado nos Determinantes Sociais da Saúde (IV-DSS).

Índice **descritivo e experimental** (docs §6/§8): varia conceitualmente de 0 a
1, onde maior valor = maior vulnerabilidade segundo a operacionalização
congelada do estudo. NÃO é probabilidade de abandono, modelo preditivo,
diagnóstico nem classificação clínica; NÃO possui pontos de corte absolutos
validados.

O IV-DSS é calculado **diretamente a partir de ``Q_full``** e é independente do
desfecho sintético ``Y`` (``descontinuou_pre_natal``). Nenhum score ausente é
substituído por zero; não há imputação.

Principal::

    IV_DSS = (D_educacao + D_trabalho + D_saneamento + D_acesso
              + D_habitacao + D_alimentacao) / 6
"""

from __future__ import annotations

from .access import (
    C_barreiras,
    C_distancia,
    D_acesso,
    D_acesso_from,
    barreira_disponibilidade,
    barreira_organizacao,
    barreira_transporte,
)
from .calculator import (
    DIMENSION_NAMES,
    IV_DSS_INPUT_FIELDS,
    N_DIMENSIONS,
    Aggregates,
    IvDssResult,
    aggregate_dimensions,
    compute_iv_dss,
)
from .education import D_educacao, score_escolaridade
from .food import D_alimentacao, score_alimentacao
from .housing import (
    D_habitacao,
    D_habitacao_binary_sensitivity,
    crowding_ratio,
    score_habitacao_binary_from_ratio,
    score_habitacao_from_ratio,
)
from .saneamento import (
    C_agua,
    C_esgotamento,
    C_residuos,
    D_saneamento,
    D_saneamento_from,
    score_agua_encanada,
    score_destino_residuos,
    score_fonte_agua,
    score_frequencia_residuos,
    score_interrupcoes_agua,
)
from .scoring import arithmetic_mean, mean_of_valid
from .sensitivity import generalized_mean_p2
from .types import ScoreResult, ScoreStatus
from .work_income import D_trabalho, score_faixa_renda

__all__ = [
    "Aggregates",
    "C_agua",
    "C_barreiras",
    "C_distancia",
    "C_esgotamento",
    "C_residuos",
    "DIMENSION_NAMES",
    "D_acesso",
    "D_acesso_from",
    "D_alimentacao",
    "D_educacao",
    "D_habitacao",
    "D_habitacao_binary_sensitivity",
    "D_saneamento",
    "D_saneamento_from",
    "D_trabalho",
    "IV_DSS_INPUT_FIELDS",
    "IvDssResult",
    "N_DIMENSIONS",
    "ScoreResult",
    "ScoreStatus",
    "aggregate_dimensions",
    "arithmetic_mean",
    "barreira_disponibilidade",
    "barreira_organizacao",
    "barreira_transporte",
    "compute_iv_dss",
    "crowding_ratio",
    "generalized_mean_p2",
    "mean_of_valid",
    "score_agua_encanada",
    "score_alimentacao",
    "score_destino_residuos",
    "score_escolaridade",
    "score_faixa_renda",
    "score_fonte_agua",
    "score_frequencia_residuos",
    "score_habitacao_binary_from_ratio",
    "score_habitacao_from_ratio",
    "score_interrupcoes_agua",
]
