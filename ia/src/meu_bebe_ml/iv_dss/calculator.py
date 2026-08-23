"""Cálculo agregado do IV-DSS.

Agrega as seis dimensões ``D_*`` no índice principal e nas saídas auxiliares
de sensibilidade:

* ``iv_dss`` — média aritmética das 6 dimensões, SOMENTE quando todas válidas
  (6/6). Se menos de 6, ``None`` (sem renormalizar pesos nem substituir
  dimensão ausente por zero).
* ``iv_dss_coverage`` — ``n_dimensoes_validas / 6`` (cobertura analítica, NÃO
  vulnerabilidade).
* ``iv_dss_parcial`` — média das 5 válidas SOMENTE quando exatamente 5/6.
* ``iv_dss_generalized_p2`` — sensibilidade (média generalizada p=2) quando 6/6.
* ``iv_dss_housing_binary_sensitivity`` — sensibilidade que substitui apenas
  ``D_habitacao`` pelo score binário (densidade > 3), exigindo 6/6.

Nada aqui lê ``Y``, ``p_true``, ``g_*``, ``Z_*``, ``C_*`` ou ``M_sim``.
"""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass
from typing import Any, Mapping

from .access import C_barreiras, C_distancia, D_acesso_from, barreira_disponibilidade, barreira_organizacao, barreira_transporte
from .education import D_educacao
from .food import D_alimentacao
from .housing import D_habitacao, D_habitacao_binary_sensitivity, crowding_ratio
from .saneamento import C_agua, C_esgotamento, C_residuos, D_saneamento_from, score_agua_encanada, score_destino_residuos, score_fonte_agua, score_frequencia_residuos, score_interrupcoes_agua
from .scoring import arithmetic_mean
from .sensitivity import generalized_mean_p2
from .types import ScoreResult
from .work_income import D_trabalho

# Nomes canônicos das 6 dimensões, na ordem do IV-DSS principal.
DIMENSION_NAMES: tuple[str, ...] = (
    "D_educacao",
    "D_trabalho",
    "D_saneamento",
    "D_acesso",
    "D_habitacao",
    "D_alimentacao",
)

N_DIMENSIONS: int = len(DIMENSION_NAMES)

# Campos observados de Q_full realmente utilizados no cálculo principal.
# Somente campos necessários; NÃO inclui OUT_LEAKAGE, Y, Z_*, C_*, g_*, eta,
# p_true, U nem latent_income_band (docs §8, seção 23 da fase).
IV_DSS_INPUT_FIELDS: tuple[str, ...] = (
    "escolaridade",
    "faixa_renda",
    "fonte_agua",
    "itens_residencia",
    "interrupcoes_agua",
    "esgotamento_sanitario",
    "frequencia_coleta_lixo",
    "destino_lixo_sem_coleta",
    "distancia_ubs",
    "dificuldades_saude",
    "numero_pessoas",
    "numero_dormitorios",
    "deixou_de_comer_falta_dinheiro",
)


@dataclass(frozen=True)
class IvDssResult:
    """Resultado completo do IV-DSS para um registro (dimensões + auditoria)."""

    # Dimensões principais (docs §8).
    D_educacao: ScoreResult
    D_trabalho: ScoreResult
    D_saneamento: ScoreResult
    D_acesso: ScoreResult
    D_habitacao: ScoreResult
    D_alimentacao: ScoreResult

    # Índice principal e cobertura.
    iv_dss: float | None
    iv_dss_coverage: float

    # Saídas auxiliares de sensibilidade.
    iv_dss_parcial: float | None
    iv_dss_generalized_p2: float | None
    D_habitacao_binary_sensitivity: ScoreResult
    iv_dss_housing_binary_sensitivity: float | None

    # Subcomponentes (para auditoria).
    score_fonte_agua: ScoreResult
    score_agua_encanada: ScoreResult
    score_interrupcoes_agua: ScoreResult
    C_agua: ScoreResult
    C_esgotamento: ScoreResult
    score_frequencia_residuos: ScoreResult
    score_destino_residuos: ScoreResult
    C_residuos: ScoreResult
    C_distancia: ScoreResult
    barreira_transporte: float | None
    barreira_organizacao: float | None
    barreira_disponibilidade: float | None
    C_barreiras: ScoreResult
    crowding_ratio: float | None

    def dimension_values(self) -> dict[str, ScoreResult]:
        """As 6 dimensões na ordem canônica, para o artefato principal."""
        return {
            "D_educacao": self.D_educacao,
            "D_trabalho": self.D_trabalho,
            "D_saneamento": self.D_saneamento,
            "D_acesso": self.D_acesso,
            "D_habitacao": self.D_habitacao,
            "D_alimentacao": self.D_alimentacao,
        }


def _dimension_results(
    d_educacao: ScoreResult,
    d_trabalho: ScoreResult,
    d_saneamento: ScoreResult,
    d_acesso: ScoreResult,
    d_habitacao: ScoreResult,
    d_alimentacao: ScoreResult,
) -> tuple[ScoreResult, ...]:
    return (d_educacao, d_trabalho, d_saneamento, d_acesso, d_habitacao, d_alimentacao)


@dataclass(frozen=True)
class Aggregates:
    """Resultado da agregação das 6 dimensões (índice + cobertura + sensibilidades)."""

    iv_dss: float | None
    iv_dss_coverage: float
    iv_dss_parcial: float | None
    iv_dss_generalized_p2: float | None
    iv_dss_housing_binary_sensitivity: float | None


def aggregate_dimensions(
    dims: Sequence[ScoreResult], housing_binary: ScoreResult
) -> Aggregates:
    """Agrega as 6 dimensões no IV-DSS principal e nas saídas auxiliares.

    ``dims`` deve ter exatamente 6 :class:`ScoreResult` na ordem canônica.
    ``housing_binary`` é a sensibilidade binária de Habitação (substituto de
    ``D_habitacao`` apenas na sensibilidade binária do índice).

    * 6/6 -> ``iv_dss`` = média aritmética; ``generalized_p2`` e
      ``housing_binary_sensitivity`` calculáveis; ``parcial = None``.
    * 5/6 -> ``iv_dss = None``; ``parcial`` = média das 5; demais ``None``.
    * <5/6 -> tudo ``None`` (exceto ``coverage``).
    """
    valid_vals = [d.value for d in dims if d.is_valid]
    n_valid = len(valid_vals)
    coverage = n_valid / N_DIMENSIONS

    iv_dss: float | None = None
    iv_dss_parcial: float | None = None
    iv_dss_generalized_p2: float | None = None
    iv_dss_housing_binary: float | None = None

    if n_valid == N_DIMENSIONS:
        iv_dss = arithmetic_mean(valid_vals)
        iv_dss_generalized_p2 = generalized_mean_p2(valid_vals)
        if housing_binary.is_valid:
            housing_vals = [
                dims[0].value,
                dims[1].value,
                dims[2].value,
                dims[3].value,
                housing_binary.value,
                dims[5].value,
            ]
            iv_dss_housing_binary = arithmetic_mean(housing_vals)
    elif n_valid == N_DIMENSIONS - 1:
        iv_dss_parcial = arithmetic_mean(valid_vals)

    return Aggregates(
        iv_dss=iv_dss,
        iv_dss_coverage=coverage,
        iv_dss_parcial=iv_dss_parcial,
        iv_dss_generalized_p2=iv_dss_generalized_p2,
        iv_dss_housing_binary_sensitivity=iv_dss_housing_binary,
    )


def compute_iv_dss(record: Mapping[str, Any]) -> IvDssResult:
    """Calcula o IV-DSS completo de um registro observado de ``Q_full``.

    Nenhum campo é imputado e nenhum score ausente é substituído por zero. O
    índice principal só é calculado com 6/6 dimensões válidas.
    """
    # --- Dimensões simples ---------------------------------------------------
    d_educacao = D_educacao(record)
    d_trabalho = D_trabalho(record)
    d_alimentacao = D_alimentacao(record)

    densidade = crowding_ratio(record.get("numero_pessoas"), record.get("numero_dormitorios"))
    d_habitacao = D_habitacao(record)
    d_habitacao_binary = D_habitacao_binary_sensitivity(record)

    # --- Saneamento (subcomponentes + dimensão) -----------------------------
    score_fonte = score_fonte_agua(record.get("fonte_agua"))
    score_encanada = score_agua_encanada(record.get("itens_residencia"))
    score_interrupcoes = score_interrupcoes_agua(record.get("interrupcoes_agua"))
    c_agua = C_agua(record)
    c_esgotamento = C_esgotamento(record)
    score_freq_residuos = score_frequencia_residuos(record.get("frequencia_coleta_lixo"))
    score_destino_res = score_destino_residuos(
        record.get("frequencia_coleta_lixo"), record.get("destino_lixo_sem_coleta")
    )
    c_residuos = C_residuos(record)
    d_saneamento = D_saneamento_from(c_agua, c_esgotamento, c_residuos)

    # --- Acesso (subcomponentes + dimensão) ----------------------------------
    c_distancia = C_distancia(record)
    c_barreiras = C_barreiras(record)
    b_transporte = barreira_transporte(record.get("dificuldades_saude"))
    b_organizacao = barreira_organizacao(record.get("dificuldades_saude"))
    b_disponibilidade = barreira_disponibilidade(record.get("dificuldades_saude"))
    d_acesso = D_acesso_from(c_distancia, c_barreiras)

    # --- Agregação principal e cobertura -------------------------------------
    dims = _dimension_results(
        d_educacao, d_trabalho, d_saneamento, d_acesso, d_habitacao, d_alimentacao
    )
    agg = aggregate_dimensions(dims, d_habitacao_binary)

    return IvDssResult(
        D_educacao=d_educacao,
        D_trabalho=d_trabalho,
        D_saneamento=d_saneamento,
        D_acesso=d_acesso,
        D_habitacao=d_habitacao,
        D_alimentacao=d_alimentacao,
        iv_dss=agg.iv_dss,
        iv_dss_coverage=agg.iv_dss_coverage,
        iv_dss_parcial=agg.iv_dss_parcial,
        iv_dss_generalized_p2=agg.iv_dss_generalized_p2,
        D_habitacao_binary_sensitivity=d_habitacao_binary,
        iv_dss_housing_binary_sensitivity=agg.iv_dss_housing_binary_sensitivity,
        score_fonte_agua=score_fonte,
        score_agua_encanada=score_encanada,
        score_interrupcoes_agua=score_interrupcoes,
        C_agua=c_agua,
        C_esgotamento=c_esgotamento,
        score_frequencia_residuos=score_freq_residuos,
        score_destino_residuos=score_destino_res,
        C_residuos=c_residuos,
        C_distancia=c_distancia,
        barreira_transporte=b_transporte,
        barreira_organizacao=b_organizacao,
        barreira_disponibilidade=b_disponibilidade,
        C_barreiras=c_barreiras,
        crowding_ratio=densidade,
    )
