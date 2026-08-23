"""Protocolo de avaliação e regra de seleção do modelo (FASE 3F-A).

REGRA DE OURO DO TEST SET (seção 10):
    O TEST não é usado para escolher modelo, escolher hiperparâmetro, decidir
    class_weight, ajustar threshold, selecionar features, calibrar probabilidade,
    decidir preprocessing nem decidir o modelo vencedor. O TEST é aberto somente
    DEPOIS que o candidato tiver sido selecionado usando exclusivamente
    TRAIN + CV, e é avaliado UMA única vez.

FLUXO FUTURO (FASE 3F-B):
    1. executar CV dos três modelos nos 4000 TRAIN;
    2. calcular métricas dos folds;
    3. selecionar candidato pela regra congelada;
    4. registrar o nome do modelo selecionado;
    5. fit novo pipeline desse modelo nos 4000 TRAIN completos;
    6. somente então abrir o TEST;
    7. avaliar uma única vez nos 1000 TEST.

Nesta fase NENHUM desses passos é executado — apenas definido/estruturado.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Any

# Regra de seleção congelada (espelha ``training_protocol_v1.yaml``).
SELECTION_PRIMARY_METRIC = "mean_pr_auc"
SELECTION_TIEBREAK = ("mean_recall", "mean_f1")


def select_best_model(
    candidates: Sequence[dict[str, Any]],
    *,
    primary: str = SELECTION_PRIMARY_METRIC,
    tiebreak: Sequence[str] = SELECTION_TIEBREAK,
) -> str:
    """Seleciona o modelo candidato pela regra congelada.

    Ordena por ``(primary, tiebreak[0], tiebreak[1], ...)`` em ordem
    decrescente (maior é melhor) e retorna o ``name`` do primeiro. O empate
    numérico no ``primary`` é desempatado, em ordem, pelas métricas de
    ``tiebreak``. O TEST nunca participa desta decisão.

    Cada candidato deve ser um ``dict`` com ``name`` (str) e as chaves das
    métricas (float). Lista vazia ou chave ausente levanta ``ValueError``.
    """
    if len(candidates) == 0:
        raise ValueError("nenhum candidato para seleção")

    keys = (primary, *tiebreak)
    normalized: list[dict[str, Any]] = []
    for cand in candidates:
        missing = [k for k in keys if k not in cand or "name" not in cand]
        if missing:
            raise ValueError(f"candidato sem as chaves exigidas: {sorted(set(missing))!r}")
        normalized.append({k: float(cand[k]) for k in keys} | {"name": cand["name"]})

    def sort_key(c: dict[str, Any]) -> tuple[float, ...]:
        return tuple(c[k] for k in keys)

    ranked = sorted(normalized, key=sort_key, reverse=True)
    return ranked[0]["name"]
