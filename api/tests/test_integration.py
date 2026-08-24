"""Testes de integração com o modelo REAL (``ia/artifacts/models/``)."""

from __future__ import annotations

import pandas as pd

from conftest import make_dss_payload
from meu_bebe_api.config import Settings
from meu_bebe_api.ml.adapter import flatten_q_full
from meu_bebe_api.ml.artifact import load_manifest, resolve_artifact_path, verify_integrity
from meu_bebe_api.ml.runtime import ModelRuntime

# Hash do artefato congelado (baseline de FASE 4B — guarda de regressão).
_EXPECTED_JOBLIB_SHA256 = "17db2db0c2b87c2a52c46e953162b3f1509a01857b651370ebcc2b4354ce883b"


def test_smoke_inference(real_runtime):
    value = real_runtime.predict_probability(make_dss_payload())
    assert isinstance(value, float)
    assert 0.0 <= value <= 1.0


def test_predict_is_deterministic(real_runtime):
    payload = make_dss_payload()
    assert real_runtime.predict_probability(payload) == real_runtime.predict_probability(payload)


def test_adapter_matches_direct_pipeline(real_runtime):
    """Adapter (DssPayload -> X_MODEL) deve produzir a MESMA predição que o
    pipeline alimentado diretamente com o DataFrame X_MODEL (tolerância 1e-12)."""
    from meu_bebe_ml.features.selectors import select_x_model
    from meu_bebe_ml.schema.constants import X_MODEL

    payload = make_dss_payload()

    via_runtime = real_runtime.predict_probability(payload)

    flat = flatten_q_full(payload)
    x_row = select_x_model(flat)
    x_direct = pd.DataFrame([x_row], columns=list(X_MODEL))
    proba = real_runtime._pipeline.predict_proba(x_direct)
    via_direct = float(proba[0, real_runtime.metadata.positive_class_index])

    assert abs(via_runtime - via_direct) <= 1e-12


def test_artifact_hash_matches_manifest():
    """§59 — o artefato NÃO foi modificado: SHA-256 bate com o manifest."""
    artifact_path = resolve_artifact_path("../ia/artifacts/models/selected_model_v1.joblib")
    manifest_path = resolve_artifact_path(
        "../ia/artifacts/models/selected_model_v1_manifest.json"
    )
    manifest = load_manifest(manifest_path)
    actual = verify_integrity(artifact_path, manifest.model_file_hash_sha256)
    assert actual == manifest.model_file_hash_sha256
    assert actual == _EXPECTED_JOBLIB_SHA256


def test_load_is_cwd_independent(tmp_path, monkeypatch):
    """§74 — carregar o modelo funciona mesmo com o CWD trocado."""
    monkeypatch.chdir(tmp_path)
    rt = ModelRuntime(Settings(model_load_on_startup=False, _env_file=None))
    rt.load()
    assert rt.is_ready
    assert rt.metadata is not None
    assert rt.metadata.raw_feature_count == 34
    assert rt.metadata.transformed_feature_count == 96
