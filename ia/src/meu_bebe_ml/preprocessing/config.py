"""Carregamento da configuração versionada do preprocessing v1.

Lê ``configs/preprocessing_v1.yaml`` e expõe uma estrutura tipada imutável
(:class:`PreprocessingConfig`). A configuração declara os GRUPOS de features e
suas ordens/flags; as categorias nominais/multiselect vêm do schema DSS 1.13
(via :mod:`meu_bebe_ml.schema`), nunca do dataset.

Nada aqui aprende estatísticas nem acessa ``Y``/``M_sim``/IV-DSS.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml

from ..schema.constants import SCHEMA_VERSION

_CONFIG_PATH = Path(__file__).resolve().parents[3] / "configs" / "preprocessing_v1.yaml"

# Grupos na ordem canônica do ColumnTransformer (determina a ordem das colunas).
GROUP_ORDER: tuple[str, ...] = (
    "boolean_required",
    "boolean_structural",
    "numeric",
    "ordinal",
    "nominal",
    "multiselect",
)


@dataclass(frozen=True)
class OrdinalField:
    name: str
    order: tuple[str, ...]


@dataclass(frozen=True)
class NominalField:
    name: str
    structural_null: bool


@dataclass(frozen=True)
class MultiselectField:
    name: str
    structural_null: bool


@dataclass(frozen=True)
class PreprocessingConfig:
    """Configuração versionada do preprocessing v1 (imutável em uso)."""

    version: str
    schema_version: str
    feature_set: str
    raw_feature_count: int
    not_applicable_token: str

    boolean_required: tuple[str, ...]
    boolean_structural: tuple[str, ...]
    numeric: tuple[str, ...]
    ordinal: tuple[OrdinalField, ...]
    nominal: tuple[NominalField, ...]
    multiselect: tuple[MultiselectField, ...]

    def group_fields(self) -> dict[str, tuple[str, ...]]:
        """Nome dos campos de cada grupo (somente os nomes)."""
        return {
            "boolean_required": self.boolean_required,
            "boolean_structural": self.boolean_structural,
            "numeric": self.numeric,
            "ordinal": tuple(f.name for f in self.ordinal),
            "nominal": tuple(f.name for f in self.nominal),
            "multiselect": tuple(f.name for f in self.multiselect),
        }

    def all_fields_in_order(self) -> tuple[str, ...]:
        """Todos os 34 campos na ordem canônica dos grupos."""
        out: list[str] = []
        for name in GROUP_ORDER:
            out.extend(self.group_fields()[name])
        return tuple(out)


def _parse_ordinal(raw: dict[str, Any]) -> tuple[OrdinalField, ...]:
    return tuple(
        OrdinalField(name=f["name"], order=tuple(f["order"]))
        for f in raw.get("fields", [])
    )


def _parse_nominal(raw: dict[str, Any]) -> tuple[NominalField, ...]:
    return tuple(
        NominalField(name=f["name"], structural_null=bool(f.get("structural_null", False)))
        for f in raw.get("fields", [])
    )


def _parse_multiselect(raw: dict[str, Any]) -> tuple[MultiselectField, ...]:
    return tuple(
        MultiselectField(
            name=f["name"], structural_null=bool(f.get("structural_null", False))
        )
        for f in raw.get("fields", [])
    )


def load_preprocessing_config(path: Path | None = None) -> PreprocessingConfig:
    """Carrega e valida a configuração versionada do preprocessing v1."""
    config_path = path or _CONFIG_PATH
    with open(config_path, "r", encoding="utf-8") as fh:
        raw = yaml.safe_load(fh)

    if raw.get("schema_version") != SCHEMA_VERSION:
        raise ValueError(
            f"preprocessing schema_version {raw.get('schema_version')!r} != "
            f"{SCHEMA_VERSION!r}"
        )

    groups = raw["groups"]
    cfg = PreprocessingConfig(
        version=raw["version"],
        schema_version=raw["schema_version"],
        feature_set=raw["feature_set"],
        raw_feature_count=int(raw["raw_feature_count"]),
        not_applicable_token=raw["not_applicable_token"],
        boolean_required=tuple(groups["boolean_required"]["fields"]),
        boolean_structural=tuple(groups["boolean_structural"]["fields"]),
        numeric=tuple(groups["numeric"]["fields"]),
        ordinal=_parse_ordinal(groups["ordinal"]),
        nominal=_parse_nominal(groups["nominal"]),
        multiselect=_parse_multiselect(groups["multiselect"]),
    )

    if cfg.raw_feature_count != len(cfg.all_fields_in_order()):
        raise ValueError(
            f"raw_feature_count {cfg.raw_feature_count} != {len(cfg.all_fields_in_order())} campos"
        )
    return cfg
