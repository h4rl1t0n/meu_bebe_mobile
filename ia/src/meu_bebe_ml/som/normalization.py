"""Normalização EXCLUSIVA DO SOM (min-max 0-1) — FASE IA-SOM-FIX.

O Random Forest usa árvores e não depende de escala; o SOM, porém, usa distância
euclidiana. Para impedir que as 9 features não-binárias (3 numéricas + 6
ordinais) dominem a distância, normalizamos SOMENTE essas colunas para [0,1]
(``min-max``), mantendo as 87 features binárias/one-hot/multi-hot intactas.

Regras (conforme a auditoria IA-SOM):

* ``fit`` calcula ``min``/``range`` SOMENTE sobre o conjunto de treino;
* ``transform`` aplica os MESMOS parâmetros ao treino e ao holdout (nunca
  re-ajusta sobre o holdout);
* coluna constante no treino (``range == 0``) é mapeada para ``0.0`` (seguro,
  sem divisão por zero);
* nenhum uso de target / P(RF) / IV-DSS — apenas re-escala colunas já derivadas
  do ``preprocessor`` congelado do RF.

Nada aqui altera ``selected_model_v1.joblib``, o pipeline congelado nem o
``/api/v1/risk-estimate``.
"""

from __future__ import annotations

from typing import Iterable, Mapping

import numpy as np
from sklearn.base import BaseEstimator, TransformerMixin


def som_scale_mask(
    feature_names: Iterable[str],
    source_map: Mapping[str, str],
    numeric_fields: Iterable[str],
    ordinal_fields: Iterable[str],
) -> np.ndarray:
    """Máscara booleana sobre as colunas de saída: ``True`` = normalizar.

    ``True`` para features numéricas e ordinais (cuja coluna de saída leva o
    nome do campo bruto); ``False`` para binárias/one-hot/multi-hot (mantidas em
    0-1). ``source_map`` mapeia feature -> campo bruto (mapa anti-leakage do
    contrato de preprocessing), então a decisão é feita sobre o campo de origem.
    """
    scale = frozenset(numeric_fields) | frozenset(ordinal_fields)
    return np.asarray(
        [source_map.get(str(name), str(name)) in scale for name in feature_names],
        dtype=bool,
    )


class SomMinMaxNormalizer(BaseEstimator, TransformerMixin):
    """Min-max (0-1) SOMENTE nas colunas marcadas por ``scale_mask``.

    As demais colunas (binárias/one-hot/multi-hot) são copiadas sem alteração.
    Parâmetros aprendidos exclusivamente no ``fit`` (treino); ``transform``
    reutiliza os mesmos. Coluna constante no treino -> ``0.0``.
    """

    def __init__(self, scale_mask: Iterable[bool]):
        self.scale_mask = np.asarray(list(scale_mask), dtype=bool)

    def fit(self, X, y=None):  # noqa: D401 - assinatura scikit-learn
        X = np.asarray(X, dtype=np.float64)
        if X.ndim != 2:
            raise ValueError("SomMinMaxNormalizer espera matriz 2D")
        if X.shape[1] != self.scale_mask.shape[0]:
            raise ValueError(
                f"scale_mask ({self.scale_mask.shape[0]}) != n_features "
                f"({X.shape[1]})"
            )
        idx = np.flatnonzero(self.scale_mask)
        if idx.size:
            self.min_ = X[:, idx].min(axis=0)
            self.range_ = X[:, idx].max(axis=0) - self.min_
        else:
            self.min_ = np.zeros(0, dtype=np.float64)
            self.range_ = np.zeros(0, dtype=np.float64)
        self.n_features_in_ = X.shape[1]
        return self

    def transform(self, X):
        X = np.asarray(X, dtype=np.float64)
        if X.shape[1] != self.n_features_in_:
            raise ValueError(
                f"n_features ({X.shape[1]}) != fit ({self.n_features_in_})"
            )
        out = X.copy()
        idx = np.flatnonzero(self.scale_mask)
        if idx.size:
            denom = np.where(self.range_ > 0.0, self.range_, 1.0)
            out[:, idx] = (X[:, idx] - self.min_) / denom
            const = idx[self.range_ <= 0.0]
            if const.size:
                out[:, const] = 0.0
        return out

    def get_feature_names_out(self, input_features=None):
        return np.asarray(input_features, dtype=object)
