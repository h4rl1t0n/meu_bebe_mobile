"""Transformers compatíveis com scikit-learn para o preprocessing v1.

Cada transformer opera sobre um grupo de colunas de ``X_MODEL``, com vocabulário
/ordem CONGELADOS (nunca aprendidos do dataset), sem imputação, sem scaling e
sem qualquer uso de ``y``/``M_sim``/IV-DSS.

* :class:`BooleanRequiredEncoder` — bool obrigatório -> 0.0/1.0 (null = erro).
* :class:`StructuralBooleanEncoder` — bool estrutural -> ``[value, not_applicable]``.
* :class:`NumericEncoder` — numérico -> float64 (null = erro).
* :class:`OrdinalFeatureEncoder` — :class:`OrdinalEncoder` com ordem congelada.
* :class:`NominalOneHotEncoder` — :class:`OneHotEncoder` com categorias fixas
  e null estrutural -> ``__not_applicable__``.
* :class:`MultiSelectBinarizerTransformer` — multi-hot com vocabulário fixo.

Todos herdam :class:`BaseEstimator`/:class:`TransformerMixin`, são clonáveis e
implementam ``fit``/``transform``/``get_feature_names_out``.
"""

from __future__ import annotations

import math
from typing import Any

import numpy as np
import pandas as pd
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.preprocessing import OneHotEncoder, OrdinalEncoder

from .contract import NOT_APPLICABLE_FEATURE_SUFFIX

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------


def _is_null(value: Any) -> bool:
    """Null estrutural/ausente: ``None`` ou NaN (nunca lista/str/int/bool)."""
    if value is None:
        return True
    if isinstance(value, (list, tuple, dict, set, str, bool, int)):
        return False
    if isinstance(value, float):
        return math.isnan(value)
    return False


def _category_label(category: str, token: str) -> str:
    """Label da feature para uma categoria; o token vira ``not_applicable``."""
    return NOT_APPLICABLE_FEATURE_SUFFIX if category == token else category


def _select_columns(X: Any, fields: list[str]) -> np.ndarray:
    """Seleciona as colunas ``fields`` em ordem, como matriz ``object``."""
    if isinstance(X, pd.DataFrame):
        return X[fields].to_numpy(dtype=object)
    return np.asarray(X, dtype=object)


def _require_scalar(value: Any, name: str, i: int, kind: str) -> None:
    if _is_null(value):
        raise ValueError(f"{kind} '{name}' é null na linha {i}")


# ---------------------------------------------------------------------------
# 1. Booleanos obrigatórios
# ---------------------------------------------------------------------------


class BooleanRequiredEncoder(BaseEstimator, TransformerMixin):
    """true -> 1.0; false -> 0.0; null inesperado -> erro. Sem imputação."""

    def __init__(self, fields: list[str]):
        self.fields = fields

    def fit(self, X: Any, y: Any = None):
        self.fields_ = list(self.fields)
        return self

    def transform(self, X: Any) -> np.ndarray:
        arr = _select_columns(X, self.fields_)
        n = arr.shape[0]
        out = np.empty((n, len(self.fields_)), dtype=np.float64)
        for j, name in enumerate(self.fields_):
            for i in range(n):
                v = arr[i, j]
                if isinstance(v, (bool, np.bool_)):
                    out[i, j] = 1.0 if bool(v) else 0.0
                else:
                    _require_scalar(v, name, i, "booleano obrigatório")
                    raise ValueError(
                        f"booleano obrigatório '{name}' recebeu {type(v).__name__} na linha {i}"
                    )
        return out

    def get_feature_names_out(self, input_features=None) -> np.ndarray:
        return np.asarray(self.fields_, dtype=object)


# ---------------------------------------------------------------------------
# 2. Booleanos com null estrutural
# ---------------------------------------------------------------------------


class StructuralBooleanEncoder(BaseEstimator, TransformerMixin):
    """true -> [1,0]; false -> [0,0]; null -> [0,1] (ordem value, not_applicable)."""

    def __init__(self, fields: list[str]):
        self.fields = fields

    def fit(self, X: Any, y: Any = None):
        self.fields_ = list(self.fields)
        return self

    def transform(self, X: Any) -> np.ndarray:
        arr = _select_columns(X, self.fields_)
        n = arr.shape[0]
        out = np.empty((n, len(self.fields_) * 2), dtype=np.float64)
        for j, name in enumerate(self.fields_):
            for i in range(n):
                v = arr[i, j]
                if _is_null(v):
                    out[i, 2 * j] = 0.0
                    out[i, 2 * j + 1] = 1.0
                elif isinstance(v, (bool, np.bool_)):
                    out[i, 2 * j] = 1.0 if bool(v) else 0.0
                    out[i, 2 * j + 1] = 0.0
                else:
                    raise ValueError(
                        f"booleano estrutural '{name}' recebeu {type(v).__name__} na linha {i}"
                    )
        return out

    def get_feature_names_out(self, input_features=None) -> np.ndarray:
        names: list[str] = []
        for f in self.fields_:
            names.append(f"{f}__value")
            names.append(f"{f}__not_applicable")
        return np.asarray(names, dtype=object)


# ---------------------------------------------------------------------------
# 3. Numéricos
# ---------------------------------------------------------------------------


class NumericEncoder(BaseEstimator, TransformerMixin):
    """Numérico -> float64; null -> erro. Sem scaling nesta fase."""

    def __init__(self, fields: list[str]):
        self.fields = fields

    def fit(self, X: Any, y: Any = None):
        self.fields_ = list(self.fields)
        return self

    def transform(self, X: Any) -> np.ndarray:
        arr = _select_columns(X, self.fields_)
        n = arr.shape[0]
        out = np.empty((n, len(self.fields_)), dtype=np.float64)
        for j, name in enumerate(self.fields_):
            for i in range(n):
                v = arr[i, j]
                if _is_null(v):
                    raise ValueError(f"numérico '{name}' é null na linha {i}")
                out[i, j] = float(v)
        return out

    def get_feature_names_out(self, input_features=None) -> np.ndarray:
        return np.asarray(self.fields_, dtype=object)


# ---------------------------------------------------------------------------
# 4. Ordinais (OrdinalEncoder com ordem congelada)
# ---------------------------------------------------------------------------


class OrdinalFeatureEncoder(BaseEstimator, TransformerMixin):
    """OrdinalEncoder com categorias EXPLÍCITAS (ordem semântica congelada)."""

    def __init__(self, fields: list[str], orders: dict[str, list[str]]):
        self.fields = fields
        self.orders = orders

    def fit(self, X: Any, y: Any = None):
        self.fields_ = list(self.fields)
        categories = [list(self.orders[f]) for f in self.fields_]
        self._encoder_ = OrdinalEncoder(
            categories=categories, dtype=np.float64, handle_unknown="error"
        )
        arr = self._validated(X)
        self._encoder_.fit(arr)
        return self

    def transform(self, X: Any) -> np.ndarray:
        arr = self._validated(X)
        return self._encoder_.transform(arr)

    def _validated(self, X: Any) -> np.ndarray:
        arr = _select_columns(X, self.fields_)
        for j, name in enumerate(self.fields_):
            for i in range(arr.shape[0]):
                if _is_null(arr[i, j]):
                    raise ValueError(f"ordinal '{name}' é null na linha {i}")
        return arr

    def get_feature_names_out(self, input_features=None) -> np.ndarray:
        return np.asarray(self.fields_, dtype=object)


# ---------------------------------------------------------------------------
# 5. Nominais (OneHotEncoder com categorias fixas + null estrutural)
# ---------------------------------------------------------------------------


class NominalOneHotEncoder(BaseEstimator, TransformerMixin):
    """OneHotEncoder com categorias FIXAS; null estrutural -> token."""

    def __init__(
        self,
        fields: list[str],
        categories: dict[str, list[str]],
        structural_null_fields: list[str] | None = None,
        not_applicable_token: str = "__not_applicable__",
    ):
        self.fields = fields
        self.categories = categories
        self.structural_null_fields = structural_null_fields
        self.not_applicable_token = not_applicable_token

    def fit(self, X: Any, y: Any = None):
        self.fields_ = list(self.fields)
        self.structural_ = set(self.structural_null_fields or ())
        cats = [list(self.categories[f]) for f in self.fields_]
        self._encoder_ = OneHotEncoder(
            categories=cats,
            sparse_output=False,
            handle_unknown="error",
            dtype=np.float64,
        )
        self._encoder_.fit(self._map_structural_null(X))
        return self

    def transform(self, X: Any) -> np.ndarray:
        return self._encoder_.transform(self._map_structural_null(X))

    def _map_structural_null(self, X: Any) -> np.ndarray:
        arr = _select_columns(X, self.fields_)
        out = np.empty(arr.shape, dtype=object)
        for j, name in enumerate(self.fields_):
            for i in range(arr.shape[0]):
                v = arr[i, j]
                if _is_null(v):
                    if name in self.structural_:
                        out[i, j] = self.not_applicable_token
                    else:
                        raise ValueError(f"nominal '{name}' é null na linha {i}")
                else:
                    out[i, j] = v
        return out

    def get_feature_names_out(self, input_features=None) -> np.ndarray:
        names: list[str] = []
        for f in self.fields_:
            for cat in self.categories[f]:
                names.append(f"{f}__{_category_label(cat, self.not_applicable_token)}")
        return np.asarray(names, dtype=object)


# ---------------------------------------------------------------------------
# 6. Multiselect (multi-hot com vocabulário fixo)
# ---------------------------------------------------------------------------


class MultiSelectBinarizerTransformer(BaseEstimator, TransformerMixin):
    """Multi-hot com vocabulário FIXO; null estrutural -> ``__not_applicable``."""

    def __init__(
        self,
        fields: list[str],
        categories: dict[str, list[str]],
        structural_null_fields: list[str] | None = None,
        not_applicable_token: str = "__not_applicable__",
    ):
        self.fields = fields
        self.categories = categories
        self.structural_null_fields = structural_null_fields
        self.not_applicable_token = not_applicable_token

    def fit(self, X: Any, y: Any = None):
        self.fields_ = list(self.fields)
        self.structural_ = set(self.structural_null_fields or ())
        self.categories_ = {f: list(self.categories[f]) for f in self.fields_}
        names: list[str] = []
        for f in self.fields_:
            for cat in self.categories_[f]:
                names.append(f"{f}__{_category_label(cat, self.not_applicable_token)}")
        self._feature_names_ = names
        return self

    def transform(self, X: Any) -> np.ndarray:
        arr = _select_columns(X, self.fields_)
        n = arr.shape[0]
        n_out = len(self._feature_names_)
        out = np.zeros((n, n_out), dtype=np.float64)

        col = 0
        for j, name in enumerate(self.fields_):
            cats = self.categories_[name]
            n_cats = len(cats)
            structural = name in self.structural_
            for i in range(n):
                v = arr[i, j]
                if _is_null(v):
                    if not structural:
                        raise ValueError(
                            f"multiselect '{name}' é null na linha {i} (não estrutural)"
                        )
                    # null estrutural: todas as categorias = 0; not_applicable = 1.
                    # o token é a ÚLTIMA categoria do campo estrutural.
                    if cats[-1] == self.not_applicable_token:
                        out[i, col + n_cats - 1] = 1.0
                    else:  # pragma: no cover - invariante do contrato
                        raise ValueError(f"token ausente nas categorias de '{name}'")
                    continue
                if not isinstance(v, list):
                    raise ValueError(
                        f"multiselect '{name}' deve ser lista na linha {i}, recebeu {type(v).__name__}"
                    )
                if len(v) == 0:
                    raise ValueError(f"multiselect '{name}' é lista vazia na linha {i}")
                for code in v:
                    if code not in cats:
                        raise ValueError(
                            f"código desconhecido '{code}' em '{name}' na linha {i}"
                        )
                    out[i, col + cats.index(code)] = 1.0
            col += n_cats
        return out

    def get_feature_names_out(self, input_features=None) -> np.ndarray:
        return np.asarray(self._feature_names_, dtype=object)
