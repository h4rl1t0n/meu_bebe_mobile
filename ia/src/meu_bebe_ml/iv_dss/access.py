"""Dimensão Acesso do IV-DSS.

``D_acesso = (C_distancia + C_barreiras) / 2``. AMBOS são obrigatórios: se
qualquer um não puder ser calculado, ``D_acesso = None`` (docs §8.4).

* ``C_distancia`` = score de ``distancia_ubs``;
* ``C_barreiras`` = média de 3 domínios binários derivados de
  ``dificuldades_saude`` (transporte, organização, disponibilidade).

O item ``distancia`` de ``dificuldades_saude`` NÃO entra em ``C_barreiras``
(evita dupla contagem com ``C_distancia``). ``sem_dificuldades`` zera as
barreiras. ``outro`` sozinho (ou apenas junto a ``distancia``) torna
``C_barreiras`` analiticamente indeterminado.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Any, Mapping

from .types import ScoreResult, analytically_indeterminate, missing, valid

# C_distancia (docs §8.4.1).
_DISTANCIA_MAP: dict[str, float] = {
    "muito_proxima": 0.0,
    "razoavelmente_proxima": 0.5,
    "distante": 1.0,
}

# Domínios de barreira em dificuldades_saude (docs §8.4.2). `distancia` é
# excluído de C_barreiras para não duplicar C_distancia.
_BARREIRA_TRANSPORTE: frozenset[str] = frozenset({"falta_transporte"})
_BARREIRA_ORGANIZACAO: frozenset[str] = frozenset(
    {"dificuldade_agendamento", "demora_atendimento", "horario_incompativel"}
)
_BARREIRA_DISPONIBILIDADE: frozenset[str] = frozenset({"falta_profissional", "falta_exames"})


def C_distancia(record: Mapping[str, Any]) -> ScoreResult:
    """Componente distância até a UBS."""
    distancia = record.get("distancia_ubs")
    if distancia is None:
        return missing("distancia_ubs ausente")
    if distancia in _DISTANCIA_MAP:
        return valid(_DISTANCIA_MAP[distancia])
    return analytically_indeterminate(f"distancia_ubs desconhecida: {distancia!r}")


def _domain_value(items: Sequence[str] | None, domain: frozenset[str]) -> float | None:
    """Retorna 1.0 se algum item do domínio está presente, 0.0 se não, ``None`` se ausente."""
    if items is None:
        return None
    return 1.0 if bool(set(items) & domain) else 0.0


def barreira_transporte(items: Sequence[str] | None) -> float | None:
    """Domínio transporte (``falta_transporte``)."""
    return _domain_value(items, _BARREIRA_TRANSPORTE)


def barreira_organizacao(items: Sequence[str] | None) -> float | None:
    """Domínio organização (agendamento/demora/horário)."""
    return _domain_value(items, _BARREIRA_ORGANIZACAO)


def barreira_disponibilidade(items: Sequence[str] | None) -> float | None:
    """Domínio disponibilidade (profissional/exames)."""
    return _domain_value(items, _BARREIRA_DISPONIBILIDADE)


def C_barreiras(record: Mapping[str, Any]) -> ScoreResult:
    """Componente barreiras de acesso, a partir de ``dificuldades_saude``.

    Regras (docs §8.4.2):

    * ``["sem_dificuldades"]`` -> 0.0;
    * com ao menos UMA barreira conhecida -> média dos 3 domínios (ignora
      ``outro`` e ``distancia``);
    * sem barreira conhecida: ``outro`` presente -> indeterminado; senão
      (apenas ``distancia`` ou lista vazia) -> 0.0.
    """
    value = record.get("dificuldades_saude")
    if value is None:
        return missing("dificuldades_saude ausente")
    if not isinstance(value, list):
        return analytically_indeterminate(f"dificuldades_saude não é lista: {value!r}")

    items = set(value)
    if items == {"sem_dificuldades"}:
        return valid(0.0)

    t = barreira_transporte(items) or 0.0
    o = barreira_organizacao(items) or 0.0
    d = barreira_disponibilidade(items) or 0.0

    if t or o or d:
        return valid((t + o + d) / 3.0)

    # Nenhuma barreira conhecida.
    if "outro" in items:
        return analytically_indeterminate(
            "dificuldades_saude sem barreira conhecida pontuável ('outro')"
        )
    # Apenas 'distancia' (já representada em C_distancia) ou lista vazia.
    return valid(0.0)


def D_acesso_from(c_distancia: ScoreResult, c_barreiras: ScoreResult) -> ScoreResult:
    """Agrega C_distancia e C_barreiras na dimensão Acesso (ambos obrigatórios)."""
    if not c_distancia.is_valid or not c_barreiras.is_valid:
        return analytically_indeterminate(
            "D_acesso requer C_distancia e C_barreiras, ambos válidos"
        )
    return valid((c_distancia.value + c_barreiras.value) / 2.0)


def D_acesso(record: Mapping[str, Any]) -> ScoreResult:
    """Dimensão Acesso = (C_distancia + C_barreiras) / 2 (ambos obrigatórios)."""
    return D_acesso_from(C_distancia(record), C_barreiras(record))
