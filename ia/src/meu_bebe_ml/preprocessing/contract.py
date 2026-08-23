"""Contrato de encoding do preprocessing v1 (resolução + validação).

Combina a configuração versionada (:mod:`config`) com as categorias congeladas
do schema DSS 1.13 e produz um :class:`ResolvedSpec` imutável com:

* os 6 grupos na ordem canônica;
* a ordem semântica de cada ordinal;
* as categorias (incluindo ``__not_applicable__`` quando estrutural) de cada
  nominal/multiselect;
* a lista ordenada e completa dos 96 feature names;
* o mapa ``feature_name -> raw_field`` (anti-leakage).

Valida que a união dos grupos é exatamente ``X_MODEL``, que são disjuntos e que
a cardinalidade é 34. Nada aqui é aprendido do dataset.
"""

from __future__ import annotations

from dataclasses import dataclass

from ..schema import constants
from ..schema.validator import SchemaSpec, load_schema
from .config import GROUP_ORDER, PreprocessingConfig, load_preprocessing_config

# Sufixo usado na feature "não aplicável" (ex.: `beneficios_trabalho__not_applicable`).
NOT_APPLICABLE_FEATURE_SUFFIX = "not_applicable"


@dataclass(frozen=True)
class ResolvedSpec:
    """Especificação resolvida (config + schema) pronta para o builder."""

    config: PreprocessingConfig
    boolean_required: tuple[str, ...]
    boolean_structural: tuple[str, ...]
    numeric: tuple[str, ...]
    ordinal_order: dict[str, tuple[str, ...]]
    # (name, categories) na ordem canônica — categories já incluem o token estrutural.
    nominal: tuple[tuple[str, tuple[str, ...]], ...]
    multiselect: tuple[tuple[str, tuple[str, ...]], ...]
    feature_names: tuple[str, ...]
    source_map: dict[str, str]

    @property
    def n_features(self) -> int:
        return len(self.feature_names)


def _categories_for(schema: SchemaSpec, name: str) -> tuple[str, ...]:
    return tuple(schema.variables[name]["categories"])


def _resolve_feature_names(spec: "ResolvedSpec") -> tuple[tuple[str, ...], dict[str, str]]:
    """Deriva os 96 feature names e o mapa feature->campo, na ordem canônica."""
    names: list[str] = []
    source: dict[str, str] = {}
    token = spec.config.not_applicable_token

    for name in spec.boolean_required:
        names.append(name)
        source[name] = name

    for name in spec.boolean_structural:
        for suffix in ("value", "not_applicable"):
            fname = f"{name}__{suffix}"
            names.append(fname)
            source[fname] = name

    for name in spec.numeric:
        names.append(name)
        source[name] = name

    for name in spec.ordinal_order:
        names.append(name)
        source[name] = name

    for name, categories in spec.nominal:
        for cat in categories:
            fname = f"{name}__{_category_label(cat, token)}"
            names.append(fname)
            source[fname] = name

    for name, categories in spec.multiselect:
        for cat in categories:
            fname = f"{name}__{_category_label(cat, token)}"
            names.append(fname)
            source[fname] = name

    return tuple(names), source


def _category_label(category: str, token: str) -> str:
    """Label da feature para uma categoria; o token vira ``not_applicable``."""
    if category == token:
        return NOT_APPLICABLE_FEATURE_SUFFIX
    return category


def resolve_spec(
    config: PreprocessingConfig | None = None, schema: SchemaSpec | None = None
) -> ResolvedSpec:
    """Resolve config + schema em uma especificação validada e imutável."""
    cfg = config or load_preprocessing_config()
    schema = schema or load_schema()

    # 1) União dos grupos == X_MODEL, disjuntos, cardinalidade 34.
    fields = cfg.all_fields_in_order()
    as_set = set(fields)
    if len(fields) != len(as_set):
        raise ValueError("grupos não são mutuamente disjuntos (campo duplicado)")
    if as_set != set(constants.X_MODEL):
        extra = as_set - set(constants.X_MODEL)
        missing = set(constants.X_MODEL) - as_set
        raise ValueError(
            f"união dos grupos != X_MODEL: extras={sorted(extra)} faltando={sorted(missing)}"
        )
    if len(fields) != constants.X_MODEL.__len__():
        raise ValueError("cardinalidade != 34")

    token = cfg.not_applicable_token
    ordinal_order = {f.name: f.order for f in cfg.ordinal}

    # 2) Validação: ordens ordinais == categorias do schema (sem perda/sobra).
    for name, order in ordinal_order.items():
        schema_cats = set(_categories_for(schema, name))
        if set(order) != schema_cats:
            raise ValueError(
                f"ordem ordinal de {name} não bate com as categorias do schema"
            )

    # 3) Nominais: categorias do schema + token estrutural quando aplicável.
    nominal: list[tuple[str, tuple[str, ...]]] = []
    for f in cfg.nominal:
        cats = list(_categories_for(schema, f.name))
        if f.structural_null:
            cats.append(token)
        nominal.append((f.name, tuple(cats)))

    # 4) Multiselect: idem.
    multiselect: list[tuple[str, tuple[str, ...]]] = []
    for f in cfg.multiselect:
        cats = list(_categories_for(schema, f.name))
        if f.structural_null:
            cats.append(token)
        multiselect.append((f.name, tuple(cats)))

    spec = ResolvedSpec(
        config=cfg,
        boolean_required=cfg.boolean_required,
        boolean_structural=cfg.boolean_structural,
        numeric=cfg.numeric,
        ordinal_order=ordinal_order,
        nominal=tuple(nominal),
        multiselect=tuple(multiselect),
        feature_names=(),
        source_map={},
    )
    names, source = _resolve_feature_names(spec)
    return ResolvedSpec(
        config=cfg,
        boolean_required=cfg.boolean_required,
        boolean_structural=cfg.boolean_structural,
        numeric=cfg.numeric,
        ordinal_order=ordinal_order,
        nominal=spec.nominal,
        multiselect=spec.multiselect,
        feature_names=names,
        source_map=source,
    )
