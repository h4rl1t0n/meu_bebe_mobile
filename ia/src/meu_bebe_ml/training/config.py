"""Configuração versionada do protocolo experimental de treinamento (FASE 3F-A).

Lê ``configs/training_protocol_v1.yaml`` e expõe uma estrutura tipada imutável
(:class:`TrainingProtocolConfig`). Os valores aqui são CONGELADOS antes de
qualquer resultado preditivo real e NÃO devem ser alterados após a Fase 3F-B
sem nova decisão metodológica + versionamento.

Nada aqui treina modelos nem calcula desempenho preditivo real.
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml

from ..schema.constants import SCHEMA_VERSION

_CONFIG_PATH = (
    Path(__file__).resolve().parents[3] / "configs" / "training_protocol_v1.yaml"
)

# Ordem canônica dos modelos candidatos (determina a ordem em relatórios/tabelas).
MODEL_ORDER: tuple[str, ...] = (
    "logistic_regression",
    "random_forest",
    "xgboost",
)


@dataclass(frozen=True)
class SplitConfig:
    test_size: float
    train_size: float
    stratified: bool
    shuffle: bool
    random_state: int


@dataclass(frozen=True)
class CrossValidationConfig:
    type: str
    n_splits: int
    shuffle: bool
    random_state: int


@dataclass(frozen=True)
class TrainingProtocolConfig:
    """Protocolo experimental congelado (imutável em uso)."""

    version: str
    schema_version: str
    preprocessing_version: str
    target_name: str

    split: SplitConfig
    cross_validation: CrossValidationConfig
    decision_threshold: float
    decision_threshold_tuning: bool

    models: tuple[str, ...]
    model_params: dict[str, dict[str, Any]]

    imbalance_strategy: dict[str, str]

    metrics_threshold: float
    metrics_thresholded: tuple[str, ...]
    metrics_threshold_independent: tuple[str, ...]
    metrics_calibration: tuple[str, ...]

    pr_auc_implementation: str
    pr_auc_average_precision: str

    calibration_n_bins: int
    calibration_strategy: str
    calibration_recalibrate: bool

    selection_source: str
    selection_primary_metric: str
    selection_tiebreak: tuple[str, ...]


def sha256_file(path: Path) -> str:
    """Calcula o hash SHA-256 (hex) do conteúdo de um arquivo."""
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def _parse_split(raw: dict[str, Any]) -> SplitConfig:
    return SplitConfig(
        test_size=float(raw["test_size"]),
        train_size=float(raw["train_size"]),
        stratified=bool(raw["stratified"]),
        shuffle=bool(raw["shuffle"]),
        random_state=int(raw["random_state"]),
    )


def _parse_cv(raw: dict[str, Any]) -> CrossValidationConfig:
    return CrossValidationConfig(
        type=raw["type"],
        n_splits=int(raw["n_splits"]),
        shuffle=bool(raw["shuffle"]),
        random_state=int(raw["random_state"]),
    )


def _parse_model_params(raw: dict[str, Any]) -> dict[str, dict[str, Any]]:
    """Lê os hiperparâmetros congelados; ``null`` do YAML vira ``None``."""
    out: dict[str, dict[str, Any]] = {}
    for name, params in raw.items():
        out[name] = {
            key: (None if value is None else value) for key, value in params.items()
        }
    return out


def load_training_config(path: Path | None = None) -> TrainingProtocolConfig:
    """Carrega e valida a configuração versionada do protocolo de treinamento."""
    config_path = path or _CONFIG_PATH
    with open(config_path, "r", encoding="utf-8") as fh:
        raw = yaml.safe_load(fh)

    if raw.get("schema_version") != SCHEMA_VERSION:
        raise ValueError(
            f"training schema_version {raw.get('schema_version')!r} != "
            f"{SCHEMA_VERSION!r}"
        )
    if raw.get("preprocessing_version") != "1.0":
        raise ValueError(
            f"training preprocessing_version {raw.get('preprocessing_version')!r} != '1.0'"
        )

    models = tuple(raw["models"])
    if models != MODEL_ORDER:
        raise ValueError(f"models {models!r} != ordem canônica {MODEL_ORDER!r}")

    model_params = _parse_model_params(raw["model_params"])
    if set(model_params) != set(models):
        raise ValueError(
            f"model_params keys {sorted(model_params)!r} != models {sorted(models)!r}"
        )

    metrics = raw["metrics"]
    cfg = TrainingProtocolConfig(
        version=raw["version"],
        schema_version=raw["schema_version"],
        preprocessing_version=raw["preprocessing_version"],
        target_name=raw["target"]["name"],
        split=_parse_split(raw["split"]),
        cross_validation=_parse_cv(raw["cross_validation"]),
        decision_threshold=float(raw["decision_threshold"]["initial"]),
        decision_threshold_tuning=bool(raw["decision_threshold"]["tuning"]),
        models=models,
        model_params=model_params,
        imbalance_strategy=dict(raw["imbalance_strategy"]),
        metrics_threshold=float(metrics["threshold"]),
        metrics_thresholded=tuple(metrics["thresholded"]),
        metrics_threshold_independent=tuple(metrics["threshold_independent"]),
        metrics_calibration=tuple(metrics["calibration"]),
        pr_auc_implementation=raw["pr_auc"]["implementation"],
        pr_auc_average_precision=raw["pr_auc"]["average_precision"],
        calibration_n_bins=int(raw["calibration"]["n_bins"]),
        calibration_strategy=raw["calibration"]["strategy"],
        calibration_recalibrate=bool(raw["calibration"]["recalibrate"]),
        selection_source=raw["model_selection"]["source"],
        selection_primary_metric=raw["model_selection"]["primary_metric"],
        selection_tiebreak=tuple(raw["model_selection"]["tiebreak"]),
    )
    return cfg
