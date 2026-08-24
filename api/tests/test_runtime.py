"""Testes do ``ModelRuntime`` (estado, load idempotente, inferência interna)."""

from __future__ import annotations

import json

import pytest

from conftest import make_dss_payload
from meu_bebe_api.config import Settings
from meu_bebe_api.ml import runtime as runtime_module
from meu_bebe_api.ml.artifact import runtime_library_versions
from meu_bebe_api.ml.errors import (
    ModelArtifactNotFoundError,
    ModelIntegrityError,
    ModelNotReadyError,
)
from meu_bebe_api.ml.runtime import ModelRuntime, RuntimeState


def _fresh_runtime() -> ModelRuntime:
    return ModelRuntime(Settings(model_load_on_startup=False, _env_file=None))


# ---------------------------------------------------------------------------
# Estado inicial e predição sem modelo
# ---------------------------------------------------------------------------


def test_runtime_starts_not_loaded():
    rt = _fresh_runtime()
    assert rt.state is RuntimeState.NOT_LOADED
    assert rt.is_ready is False
    assert rt.metadata is None
    assert rt.last_error_code is None


def test_predict_before_load_raises_not_ready():
    rt = _fresh_runtime()
    with pytest.raises(ModelNotReadyError):
        rt.predict_probability(make_dss_payload())


# ---------------------------------------------------------------------------
# Carregamento FAIL-CLOSED (sem tocar no modelo real)
# ---------------------------------------------------------------------------


def test_load_missing_artifact_raises(tmp_path):
    rt = ModelRuntime(
        Settings(
            model_artifact_path=str(tmp_path / "nao_existe.joblib"),
            model_manifest_path=str(tmp_path / "nao_existe.json"),
            model_load_on_startup=False,
            _env_file=None,
        )
    )
    with pytest.raises(ModelArtifactNotFoundError):
        rt.load()
    assert rt.state is RuntimeState.ERROR
    assert rt.last_error_code == ModelArtifactNotFoundError.code


def test_hash_verified_before_joblib_load(monkeypatch, tmp_path):
    """Ordem obrigatória: SHA-256 é verificado ANTES de ``joblib.load``."""
    artifact_path = tmp_path / "model.joblib"
    artifact_path.write_bytes(b"falso")

    manifest_path = tmp_path / "manifest.json"
    manifest_path.write_text(
        json.dumps(
            {
                "model_name": "random_forest",
                "model_class": "RandomForestClassifier",
                "schema_version": "1.13",
                "n_features": 96,
                "threshold": 0.5,
                # hash ERRADO de propósito -> integridade deve falhar ANTES do load
                "model_file_hash_sha256": "0" * 64,
                "library_versions": runtime_library_versions(),
            }
        ),
        encoding="utf-8",
    )

    joblib_called = {"value": False}

    def _forbidden_load(path):
        joblib_called["value"] = True
        raise AssertionError("joblib.load NÃO deveria ser chamado antes do hash")

    monkeypatch.setattr(runtime_module.joblib, "load", _forbidden_load)

    rt = ModelRuntime(
        Settings(
            model_artifact_path=str(artifact_path),
            model_manifest_path=str(manifest_path),
            model_load_on_startup=False,
            _env_file=None,
        )
    )

    with pytest.raises(ModelIntegrityError):
        rt.load()

    assert joblib_called["value"] is False
    assert rt.state is RuntimeState.ERROR
    assert rt.last_error_code == ModelIntegrityError.code


# ---------------------------------------------------------------------------
# Integração com o modelo REAL (fixture ``real_runtime`` carrega 1x/sessão)
# ---------------------------------------------------------------------------


def test_load_idempotent(real_runtime):
    rt = real_runtime
    assert rt.is_ready
    meta_before = rt.metadata
    # Segunda chamada com o mesmo artefato NÃO deve recarregar nem falhar.
    rt.load()
    assert rt.is_ready
    assert rt.metadata == meta_before


def test_metadata_structure(real_runtime):
    meta = real_runtime.metadata
    assert meta is not None
    assert meta.name == "random_forest"
    assert meta.raw_feature_count == 34
    assert meta.transformed_feature_count == 96
    assert meta.positive_class_index == 1
    assert meta.schema_version == "1.13"


def test_predict_probability_returns_float_in_range(real_runtime):
    value = real_runtime.predict_probability(make_dss_payload())
    assert isinstance(value, float)
    assert 0.0 <= value <= 1.0
