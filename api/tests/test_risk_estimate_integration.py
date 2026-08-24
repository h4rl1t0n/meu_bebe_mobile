"""Integração END-TO-END do ``POST /api/v1/risk-estimate`` (modelo REAL).

Usa o ``ModelRuntime`` real + ``selected_model_v1.joblib`` real + um
``DssPayload`` sintético válido. NÃO lê ``test_predictions_selected_v1.csv``
(TEST ML) nem recalcula métricas.
"""

from __future__ import annotations

from fastapi.testclient import TestClient

from conftest import make_dss_payload
from meu_bebe_api.config import Settings
from meu_bebe_api.contracts.risk_estimate import (
    EXPERIMENTAL_ESTIMATE_NOTICE,
    EXPERIMENTAL_TARGET,
)
from meu_bebe_api.main import create_app
from meu_bebe_api.ml import runtime as runtime_module
from meu_bebe_api.ml.runtime import ModelRuntime


def _real_client(runtime: ModelRuntime) -> TestClient:
    settings = Settings(model_load_on_startup=False, _env_file=None)
    return TestClient(create_app(settings, runtime=runtime))


def test_end_to_end_real_model(real_runtime):
    payload = make_dss_payload()
    with _real_client(real_runtime) as c:
        resp = c.post("/api/v1/risk-estimate", json=payload.model_dump(mode="json"))

    assert resp.status_code == 200
    body = resp.json()

    assert body["result"]["target"] == EXPERIMENTAL_TARGET
    assert body["model"] == {
        "name": "random_forest",
        "schema_version": "1.13",
        "raw_feature_count": 34,
        "transformed_feature_count": 96,
    }
    assert body["notice"] == EXPERIMENTAL_ESTIMATE_NOTICE

    # probability HTTP == runtime direto (tolerância 1e-12, sem hardcode).
    expected = real_runtime.predict_probability(payload)
    proba = body["result"]["probability"]
    assert isinstance(proba, float)
    assert 0.0 <= proba <= 1.0
    assert abs(proba - expected) <= 1e-12


def test_determinism_real_model(real_runtime):
    payload = make_dss_payload().model_dump(mode="json")
    with _real_client(real_runtime) as c:
        r1 = c.post("/api/v1/risk-estimate", json=payload).json()
        r2 = c.post("/api/v1/risk-estimate", json=payload).json()

    assert r1["result"]["probability"] == r2["result"]["probability"]


def test_no_joblib_load_per_request(real_runtime, monkeypatch):
    """POST repetidos NÃO chamam ``joblib.load`` (load fica no lifespan/runtime)."""

    def _forbidden_load(path):
        raise AssertionError("joblib.load não deve ser chamado por request")

    monkeypatch.setattr(runtime_module.joblib, "load", _forbidden_load)

    payload = make_dss_payload().model_dump(mode="json")
    with _real_client(real_runtime) as c:
        for _ in range(2):
            assert c.post("/api/v1/risk-estimate", json=payload).status_code == 200
