"""Derivação dos fatores ``g_*`` do DGM do target sintético (FASE 3C).

Este módulo converte os campos observados de ``Q_full`` (mais a renda latente
``latent_income_band``, exclusiva de ``M_sim``) nos **8 fatores internos**
``g_*``, nas **2 interações** e no **componente linear** ``linear_component`` do
DGM experimental congelado (docs §18):

    eta = alpha + linear_component + U

    linear_component =
          0.50 * g_escolaridade
        + 0.55 * g_renda
        + 0.45 * g_distancia
        + 0.55 * g_transporte
        + 0.40 * g_organizacao
        + 0.40 * g_trabalho
        + 0.30 * g_privacao_alimentar
        + 0.25 * g_adensamento
        + 0.30 * interaction_income_food
        + 0.35 * interaction_distance_transport

Os **coeficientes** (0.50, 0.55, …) são lidos de ``simulation_v1.yaml``
(seção ``dgmgm``), nunca duplicados como literais aqui. As **tabelas de
mapeamento** ``g_*`` (categoria -> score em [0,1]) são parâmetros experimentais
do DGM definidos na especificação da fase e em docs §18.1; não existem em YAML.

Nada aqui gera ruído, probabilidade ou Y — apenas deriva os fatores e a soma
linear. A montagem probabilística fica em :mod:`meu_bebe_ml.simulation.target`.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Mapping, Sequence

# ---------------------------------------------------------------------------
# Constantes do DGM
# ---------------------------------------------------------------------------

# Campos observados de Q_full usados como INPUTS do DGM principal (docs §18).
# NÃO inclui OUT_LEAKAGE, OUT_TEMPORAL nem latentes (a renda latente é M_sim).
DGM_INPUT_FIELDS: tuple[str, ...] = (
    "escolaridade",
    "faixa_renda",
    "distancia_ubs",
    "dificuldades_saude",
    "empregado",
    "trabalho_permite_pre_natal",
    "deixou_de_comer_falta_dinheiro",
    "numero_pessoas",
    "numero_dormitorios",
)

# Ordem canônica dos 8 fatores g_* (espelha simulation_v1.yaml ``g_factors``).
G_FACTOR_NAMES: tuple[str, ...] = (
    "g_escolaridade",
    "g_renda",
    "g_distancia",
    "g_transporte",
    "g_organizacao",
    "g_trabalho",
    "g_privacao_alimentar",
    "g_adensamento",
)

# Nomes canônicos das interações (docs §18.2), no formato de armazenamento.
INTERACTION_NAMES: tuple[str, ...] = (
    "interaction_income_food",
    "interaction_distance_transport",
)

# Mapeamento nome-yaml -> nome-canônico das interações (simulation_v1.yaml usa I1/I2).
_INTERACTION_NAME_BY_YAML: dict[str, str] = {
    "I1": "interaction_income_food",
    "I2": "interaction_distance_transport",
}

# Barreiras organizacionais reconhecidas pelo DGM (docs §18.1). NÃO somar:
# a presença de várias continua produzindo g_organizacao == 1.
_ORGANIZATIONAL_BARRIERS: frozenset[str] = frozenset(
    {"dificuldade_agendamento", "demora_atendimento", "horario_incompativel"}
)

# Campos de M_sim do DGM que NUNCA devem aparecer no dataset observado.
# (Z_* e C_* ficam em latent.py e são somados a este conjunto pelos testes.)
M_SIM_DGM_FIELDS: frozenset[str] = frozenset(
    {
        "latent_income_band",
        "income_was_masked",
        *G_FACTOR_NAMES,
        "crowding_ratio",
        *INTERACTION_NAMES,
        "I1",
        "I2",
        "linear_component",
        "U",
        "eta",
        "p_true",
        "alpha",
    }
)

# ---------------------------------------------------------------------------
# Tabelas de mapeamento g_* (parâmetros experimentais do DGM — congelados)
# ---------------------------------------------------------------------------

_G_ESCOLARIDADE: dict[str, float] = {
    "superior_completo": 0.00,
    "superior_incompleto": 0.17,
    "medio_completo": 0.33,
    "medio_incompleto": 0.50,
    "fundamental_completo": 0.67,
    "fundamental_incompleto": 0.83,
    "sem_instrucao": 1.00,
}

_G_RENDA: dict[str, float] = {
    "mais_3_sm": 0.00,
    "entre_2_3_sm": 0.33,
    "entre_1_2_sm": 0.67,
    "ate_1_sm": 1.00,
}

_G_DISTANCIA: dict[str, float] = {
    "muito_proxima": 0.00,
    "razoavelmente_proxima": 0.50,
    "distante": 1.00,
}


@dataclass(frozen=True)
class DgmSpec:
    """Coeficientes do DGM lidos de ``simulation_v1.yaml`` (seção ``dgmgm``)."""

    g_coefficients: dict[str, float]
    interaction_coefficients: dict[str, float]


def load_dgm_spec(sim_config: Mapping[str, Any]) -> DgmSpec:
    """Extrai os coeficientes do DGM do ``simulation_v1.yaml`` carregado.

    Nunca duplica os números como literais: lê ``dgmgm.g_factors`` e
    ``dgmgm.interactions`` e mapeia ``I1``/``I2`` para os nomes canônicos.
    """
    dgm = sim_config["dgmgm"]
    g_coefficients = {
        str(item["name"]): float(item["coefficient"]) for item in dgm["g_factors"]
    }
    interaction_coefficients: dict[str, float] = {}
    for item in dgm["interactions"]:
        yaml_name = str(item["name"])
        canonical = _INTERACTION_NAME_BY_YAML.get(yaml_name, yaml_name)
        interaction_coefficients[canonical] = float(item["coefficient"])
    return DgmSpec(g_coefficients=g_coefficients, interaction_coefficients=interaction_coefficients)


# ---------------------------------------------------------------------------
# Fatores g_* individuais (testáveis isoladamente)
# ---------------------------------------------------------------------------

def g_escolaridade(escolaridade: str) -> float:
    """Score de escolaridade (docs §18.1)."""
    if escolaridade not in _G_ESCOLARIDADE:
        raise ValueError(f"escolaridade desconhecida: {escolaridade!r}")
    return _G_ESCOLARIDADE[escolaridade]


def g_renda(faixa_renda: str, latent_income_band: str | None) -> float:
    """Score de renda, usando a renda latente quando ``nao_informar``.

    Verifica coerência: se ``faixa_renda`` não foi mascarada, ela deve ser igual
    a ``latent_income_band`` (senão falha). Quando ``nao_informar``, usa a faixa
    verdadeira sintética de ``M_sim`` — NUNCA imputa média nem score arbitrário.
    """
    if faixa_renda == "nao_informar":
        if latent_income_band is None or latent_income_band == "nao_informar":
            raise ValueError(
                "faixa_renda == 'nao_informar' exige latent_income_band real de M_sim"
            )
        return _g_renda_of(latent_income_band)
    if faixa_renda != latent_income_band:
        raise ValueError(
            f"incoerência de renda: faixa_renda={faixa_renda!r} != "
            f"latent_income_band={latent_income_band!r}"
        )
    return _g_renda_of(faixa_renda)


def _g_renda_of(band: str) -> float:
    if band not in _G_RENDA:
        raise ValueError(f"faixa de renda desconhecida: {band!r}")
    return _G_RENDA[band]


def g_distancia(distancia_ubs: str) -> float:
    """Score de distância até a UBS (docs §18.1)."""
    if distancia_ubs not in _G_DISTANCIA:
        raise ValueError(f"distancia_ubs desconhecida: {distancia_ubs!r}")
    return _G_DISTANCIA[distancia_ubs]


def g_transporte(dificuldades_saude: Sequence[str] | None) -> float:
    """1.0 se ``falta_transporte`` está em ``dificuldades_saude``; senão 0.0."""
    return 1.0 if "falta_transporte" in (dificuldades_saude or []) else 0.0


def g_organizacao(dificuldades_saude: Sequence[str] | None) -> float:
    """1.0 se há ao menos UMA barreira organizacional; senão 0.0 (não soma)."""
    items = dificuldades_saude or []
    return 1.0 if any(b in items for b in _ORGANIZATIONAL_BARRIERS) else 0.0


def g_trabalho(empregado: bool | None, trabalho_permite_pre_natal: bool | None) -> float:
    """1.0 quando empregada e sem permissão de pré-natal no trabalho; senão 0.0."""
    if empregado is True and trabalho_permite_pre_natal is False:
        return 1.0
    return 0.0


def g_privacao_alimentar(deixou_de_comer_falta_dinheiro: bool | None) -> float:
    """1.0 se ``deixou_de_comer_falta_dinheiro == true``; senão 0.0."""
    return 1.0 if deixou_de_comer_falta_dinheiro is True else 0.0


def crowding_ratio(numero_pessoas: int, numero_dormitorios: int) -> float:
    """Razão pessoas/dormitórios (denominador >= 1 pelo schema)."""
    if numero_dormitorios < 1:
        raise ValueError(f"numero_dormitorios deve ser >= 1, recebido {numero_dormitorios}")
    return numero_pessoas / numero_dormitorios


def g_adensamento(densidade: float) -> float:
    """Score de adensamento a partir da razão pessoas/dormitórios (docs §18.1)."""
    if densidade <= 2.0:
        return 0.0
    if densidade <= 3.0:
        return 0.5
    return 1.0


# ---------------------------------------------------------------------------
# Fatores agregados + componente linear
# ---------------------------------------------------------------------------

def compute_g_factors(record: Mapping[str, Any], latent_income_band: str | None) -> dict[str, float]:
    """Deriva os 8 ``g_*``, a razão de adensamento e as 2 interações de 1 registro."""
    g_renda_val = g_renda(record["faixa_renda"], latent_income_band)
    g_dist_val = g_distancia(record["distancia_ubs"])
    g_priv_val = g_privacao_alimentar(record["deixou_de_comer_falta_dinheiro"])
    g_transp_val = g_transporte(record["dificuldades_saude"])
    density = crowding_ratio(record["numero_pessoas"], record["numero_dormitorios"])

    return {
        "g_escolaridade": g_escolaridade(record["escolaridade"]),
        "g_renda": g_renda_val,
        "g_distancia": g_dist_val,
        "g_transporte": g_transp_val,
        "g_organizacao": g_organizacao(record["dificuldades_saude"]),
        "g_trabalho": g_trabalho(record["empregado"], record["trabalho_permite_pre_natal"]),
        "g_privacao_alimentar": g_priv_val,
        "g_adensamento": g_adensamento(density),
        "crowding_ratio": density,
        "interaction_income_food": g_renda_val * g_priv_val,
        "interaction_distance_transport": g_dist_val * g_transp_val,
    }


def compute_linear_component(g_factors: Mapping[str, float], spec: DgmSpec) -> float:
    """Soma ponderada ``linear_component`` usando os coeficientes do YAML."""
    linear = 0.0
    for name in G_FACTOR_NAMES:
        linear += spec.g_coefficients[name] * g_factors[name]
    for name in INTERACTION_NAMES:
        linear += spec.interaction_coefficients[name] * g_factors[name]
    return linear
