"""Explicabilidade local baseada em decomposição de caminhos de árvore (Tree Path Contribution).

Calcula as contribuições das variáveis para uma predição individual de
um modelo ensemble baseado em árvores (ex.: RandomForestClassifier).

Para cada árvore, decompõe a probabilidade predita na folha a partir do nó raiz:
    P(folha) = P(raiz) + sum_{i in caminho} (P(filho) - P(pai))

A média sobre todas as árvores decompõe perfeitamente a probabilidade predita:
    predict_proba(x) = bias_médio + sum_{f in features_transformadas} contribuição[f]

As contribuições das features transformadas são agregadas de volta para as 34
variáveis brutas de ``X_MODEL`` do contrato DSS 1.13.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Sequence
import numpy as np
import pandas as pd

from ..schema.constants import X_MODEL

FEATURE_LABELS_PT_BR: dict[str, str] = {
    "estuda_atualmente": "Estudo atual",
    "escolaridade": "Nível de escolaridade",
    "dificuldades_educacao": "Dificuldades na educação/estudo",
    "entende_orientacoes_saude": "Compreensão das orientações de saúde",
    "fez_curso_qualificacao_profissional": "Curso de qualificação profissional",
    "empregado": "Situação de emprego",
    "tipo_emprego": "Tipo de vínculo de trabalho",
    "faixa_renda": "Faixa de renda familiar",
    "trabalho_permite_pre_natal": "Liberação no trabalho para pré-natal",
    "ambiente_trabalho_seguro": "Segurança no ambiente de trabalho",
    "tem_pausas_descanso": "Pausas para descanso no trabalho",
    "beneficios_trabalho": "Benefícios trabalhistas",
    "recebe_beneficio_social": "Recebimento de benefício social",
    "fonte_agua": "Fonte de abastecimento de água",
    "interrupcoes_agua": "Interrupções no abastecimento de água",
    "esgotamento_sanitario": "Rede de esgotamento sanitário",
    "frequencia_coleta_lixo": "Frequência de coleta de lixo",
    "destino_lixo_sem_coleta": "Destino do lixo sem coleta",
    "distancia_ubs": "Distância até a UBS",
    "acesso_ubs": "Meio de deslocamento até a UBS",
    "cadastrada_ubs": "Cadastro ativo na UBS",
    "dificuldades_saude": "Dificuldades de acesso aos serviços de saúde",
    "tipo_moradia": "Tipo de moradia",
    "material_moradia": "Material da construção da moradia",
    "numero_pessoas": "Número de pessoas no domicílio",
    "numero_comodos": "Número de cômodos da residência",
    "numero_dormitorios": "Número de dormitórios",
    "itens_residencia": "Bens e itens disponíveis na residência",
    "seguranca_residencia": "Percepção de segurança na moradia",
    "refeicoes_por_dia": "Quantidade de refeições diárias",
    "deixou_de_comer_falta_dinheiro": "Insegurança alimentar por falta de recursos",
    "alimentos_consumidos": "Diversidade de alimentos consumidos",
    "fonte_alimentos": "Origem dos alimentos consumidos",
    "avaliacao_alimentacao": "Autoavaliação da qualidade da alimentação",
}


@dataclass(frozen=True)
class LocalFactorContribution:
    """Contribuição local de uma variável bruta para a estimativa de risco."""

    feature: str
    label: str
    contribution: float
    direction: str  # "increases_risk" | "decreases_risk"
    description: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "feature": self.feature,
            "label": self.label,
            "contribution": round(self.contribution, 4),
            "direction": self.direction,
            "description": self.description,
        }


def map_transformed_to_raw(transformed_names: Sequence[str]) -> list[str]:
    """Mapeia cada coluna transformada de volta à sua variável de origem em X_MODEL.

    Utiliza correspondência exata ou casamento pelo prefixo mais longo com delimitador.
    """
    raw_set = set(X_MODEL)
    mapping: list[str] = []

    for name in transformed_names:
        if name in raw_set:
            mapping.append(name)
            continue

        candidates = [
            r for r in X_MODEL
            if name.startswith(f"{r}__") or name.startswith(f"{r}_")
        ]
        if candidates:
            candidates.sort(key=len, reverse=True)
            mapping.append(candidates[0])
        else:
            # Fallback defensivo
            mapping.append(name)

    return mapping


def explain_prediction_rf(
    preprocessor: Any,
    rf_model: Any,
    x_raw: pd.DataFrame,
    positive_class_index: int = 1,
    top_k: int = 6,
) -> tuple[float, float, list[LocalFactorContribution]]:
    """Calcula a decomposição exata da predição por caminhos de árvore.

    Args:
        preprocessor: ColumnTransformer ajustado.
        rf_model: RandomForestClassifier ajustado.
        x_raw: DataFrame com 1 linha contendo as features brutas de X_MODEL.
        positive_class_index: Índice da classe positiva (padrão 1).
        top_k: Quantidade máxima de fatores determinantes a retornar.

    Returns:
        tuple (predicted_probability, mean_bias, top_factors).
    """
    x_trans = preprocessor.transform(x_raw)
    if hasattr(x_trans, "toarray"):
        x_trans = x_trans.toarray()

    transformed_names = list(preprocessor.get_feature_names_out())
    raw_mapping = map_transformed_to_raw(transformed_names)

    n_trees = len(rf_model.estimators_)
    n_features = x_trans.shape[1]
    contributions_trans = np.zeros(n_features, dtype=float)
    biases = np.zeros(n_trees, dtype=float)

    for t_idx, tree in enumerate(rf_model.estimators_):
        tree_obj = tree.tree_
        node_values = tree_obj.value[:, 0, :]
        sums = np.sum(node_values, axis=1)
        sums[sums == 0] = 1.0  # Proteção contra divisão por zero
        node_probs = node_values[:, positive_class_index] / sums

        biases[t_idx] = node_probs[0]

        d_path = tree.decision_path(x_trans)
        node_indices = d_path.indices

        for i in range(len(node_indices) - 1):
            parent = node_indices[i]
            child = node_indices[i + 1]
            feat = tree_obj.feature[parent]
            if feat >= 0:
                delta = node_probs[child] - node_probs[parent]
                contributions_trans[feat] += delta / n_trees

    mean_bias = float(np.mean(biases))

    # Agregação para variáveis brutas
    raw_contributions: dict[str, float] = {col: 0.0 for col in X_MODEL}
    for feat_idx, delta_val in enumerate(contributions_trans):
        raw_name = raw_mapping[feat_idx]
        if raw_name in raw_contributions:
            raw_contributions[raw_name] += float(delta_val)

    # Probabilidade direta
    predicted_prob = float(mean_bias + np.sum(contributions_trans))
    predicted_prob = max(0.0, min(1.0, predicted_prob))

    # Classificação e ordenação dos fatores pelo impacto absoluto (|contribuição|)
    sorted_factors = sorted(
        raw_contributions.items(),
        key=lambda item: abs(item[1]),
        reverse=True,
    )

    factors: list[LocalFactorContribution] = []
    for feat_name, contrib in sorted_factors[:top_k]:
        if abs(contrib) < 1e-4:
            continue

        direction = "increases_risk" if contrib > 0 else "decreases_risk"
        label = FEATURE_LABELS_PT_BR.get(feat_name, feat_name)
        if direction == "increases_risk":
            desc = f"{label}: fator que contribui para elevação da probabilidade estimada."
        else:
            desc = f"{label}: fator de proteção associado a menor risco de descontinuidade."

        factors.append(
            LocalFactorContribution(
                feature=feat_name,
                label=label,
                contribution=float(contrib),
                direction=direction,
                description=desc,
            )
        )

    return predicted_prob, mean_bias, factors
