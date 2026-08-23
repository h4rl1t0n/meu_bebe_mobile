"""Factories dos pipelines candidatos (Logistic Regression / Random Forest /
XGBoost) com hiperparâmetros CONGELADOS do protocolo v1.

IMPORTANTE (anti-leakage):
  * cada factory devolve um ``Pipeline`` cujo primeiro passo é um
    ``build_x_model_preprocessor()`` NOVO (nunca um objeto já fitado nos 5000
    registros). No futuro, o fit do preprocessor acontece SOMENTE sobre o
    training fold corrente;
  * o ``scale_pos_weight`` do XGBoost é calculado EXCLUSIVAMENTE a partir do
    ``y`` passado àquela factory (o ``y`` do fit corrente — nunca validation,
    test, dataset completo nem a taxa-alvo do DGM).

Os coeficientes da Logistic Regression NÃO são interpretados como efeitos
causais nem odds ratios epidemiológicos independentes.
"""

from __future__ import annotations

import numpy as np
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from xgboost import XGBClassifier

from ..preprocessing.builder import build_x_model_preprocessor
from .config import load_training_config

_FROZEN_MODEL_CLASSES = {
    "logistic_regression": LogisticRegression,
    "random_forest": RandomForestClassifier,
    "xgboost": XGBClassifier,
}


def compute_scale_pos_weight(y: np.ndarray) -> float:
    """Calcula ``scale_pos_weight = n_negative / n_positive`` do ``y`` recebido.

    Usa SOMENTE o ``y`` passado (nunca validation/test/dataset completo/taxa do
    DGM). Se ``y`` contém apenas uma classe, falha com mensagem clara.
    """
    y = np.asarray(y).ravel()
    classes = np.unique(y)

    if len(classes) == 1:
        only = classes[0]
        raise ValueError(
            f"scale_pos_weight requer as duas classes em y; recebido somente "
            f"classe {only!r}"
        )
    if len(classes) != 2:
        raise ValueError(
            f"y deve ser binário (2 classes); recebido {len(classes)} classes "
            f"{sorted(int(c) for c in classes)!r}"
        )

    n_negative = int((y == 0).sum())
    n_positive = int((y == 1).sum())
    if n_negative == 0 or n_positive == 0:
        raise ValueError(
            f"y deve conter ambas as classes com contagem > 0; "
            f"neg={n_negative} pos={n_positive}"
        )
    return n_negative / n_positive


def _frozen_params(model_name: str) -> dict:
    """Hiperparâmetros congelados do protocolo v1 para o modelo informado."""
    cfg = load_training_config()
    return dict(cfg.model_params[model_name])


def build_logistic_pipeline(
    preprocessor: ColumnTransformer | None = None,
) -> Pipeline:
    """Pipeline Logistic Regression (baseline regularizado) com params congelados."""
    params = _frozen_params("logistic_regression")
    pre = preprocessor if preprocessor is not None else build_x_model_preprocessor()
    return Pipeline(
        [
            ("preprocessor", pre),
            ("model", LogisticRegression(**params)),
        ]
    )


def build_random_forest_pipeline(
    preprocessor: ColumnTransformer | None = None,
) -> Pipeline:
    """Pipeline Random Forest com params congelados (``random_state=42``)."""
    params = _frozen_params("random_forest")
    pre = preprocessor if preprocessor is not None else build_x_model_preprocessor()
    return Pipeline(
        [
            ("preprocessor", pre),
            ("model", RandomForestClassifier(**params)),
        ]
    )


def build_xgboost_pipeline(
    preprocessor: ColumnTransformer | None = None,
    y_fit: np.ndarray | None = None,
) -> Pipeline:
    """Pipeline XGBoost com params congelados.

    Se ``y_fit`` for fornecido (o ``y`` do TRAINING FOLD corrente), calcula
    ``scale_pos_weight = n_negative / n_positive`` SOMENTE desse ``y``. Caso
    contrário, o parâmetro não é definido (o fit futuro deve sempre passar
    ``y_fit`` para lidar com o desbalanceamento de forma explícita e testável).
    """
    params = _frozen_params("xgboost")
    if y_fit is not None:
        params["scale_pos_weight"] = compute_scale_pos_weight(y_fit)
    pre = preprocessor if preprocessor is not None else build_x_model_preprocessor()
    return Pipeline(
        [
            ("preprocessor", pre),
            ("model", XGBClassifier(**params)),
        ]
    )


def model_class_of(model_name: str):
    """Classe do estimador congelado para o nome canônico do modelo."""
    if model_name not in _FROZEN_MODEL_CLASSES:
        raise KeyError(f"modelo desconhecido: {model_name!r}")
    return _FROZEN_MODEL_CLASSES[model_name]
