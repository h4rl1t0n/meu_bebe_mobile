"""Builder do preprocessor v1 (ColumnTransformer de X_MODEL -> 96 features).

:func:`build_x_model_preprocessor` devolve um
:class:`sklearn.compose.ColumnTransformer` NÃO ajustado, pronto para ser
encaixado num ``Pipeline``:

.. code-block:: python

    Pipeline([
        ("preprocessor", build_x_model_preprocessor()),
        ("model", futuro_modelo),  # NÃO incluído nesta fase
    ])

Esse ``Pipeline`` será fitado SOMENTE sobre o conjunto de treinamento em uma
etapa futura. Nesta fase NÃO há split, NÃO há fit definitivo e NÃO há
serialização do objeto como modelo de produção.

Todas as categorias/ordens vêm do contrato congelado (schema + config) — nada
é aprendido da distribuição dos dados; ``y`` é ignorado.
"""

from __future__ import annotations

from sklearn.compose import ColumnTransformer

from .contract import ResolvedSpec, resolve_spec
from .transformers import (
    BooleanRequiredEncoder,
    MultiSelectBinarizerTransformer,
    NominalOneHotEncoder,
    NumericEncoder,
    OrdinalFeatureEncoder,
    StructuralBooleanEncoder,
)


def build_x_model_preprocessor(spec: ResolvedSpec | None = None) -> ColumnTransformer:
    """Constrói o ``ColumnTransformer`` do preprocessing v1 (não ajustado)."""
    spec = spec or resolve_spec()
    token = spec.config.not_applicable_token

    ordinal_fields = list(spec.ordinal_order.keys())
    ordinal_orders = {name: list(order) for name, order in spec.ordinal_order.items()}

    nominal_fields = [name for name, _ in spec.nominal]
    nominal_cats = {name: list(cats) for name, cats in spec.nominal}
    structural_nominal = [f.name for f in spec.config.nominal if f.structural_null]

    ms_fields = [name for name, _ in spec.multiselect]
    ms_cats = {name: list(cats) for name, cats in spec.multiselect}
    structural_ms = [f.name for f in spec.config.multiselect if f.structural_null]

    transformers = [
        (
            "boolean_required",
            BooleanRequiredEncoder(list(spec.boolean_required)),
            list(spec.boolean_required),
        ),
        (
            "boolean_structural",
            StructuralBooleanEncoder(list(spec.boolean_structural)),
            list(spec.boolean_structural),
        ),
        ("numeric", NumericEncoder(list(spec.numeric)), list(spec.numeric)),
        (
            "ordinal",
            OrdinalFeatureEncoder(ordinal_fields, ordinal_orders),
            ordinal_fields,
        ),
        (
            "nominal",
            NominalOneHotEncoder(
                nominal_fields, nominal_cats, structural_nominal, token
            ),
            nominal_fields,
        ),
        (
            "multiselect",
            MultiSelectBinarizerTransformer(ms_fields, ms_cats, structural_ms, token),
            ms_fields,
        ),
    ]

    return ColumnTransformer(
        transformers=transformers,
        remainder="drop",
        verbose_feature_names_out=False,
    )
