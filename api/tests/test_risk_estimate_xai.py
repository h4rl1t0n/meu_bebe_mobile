"""Testes para explicabilidade local (XAI) no endpoint POST /api/v1/risk-estimate."""

from __future__ import annotations

from fastapi.testclient import TestClient
import pytest

from conftest import make_dss_payload
from meu_bebe_api.config import Settings
from meu_bebe_api.contracts.risk_estimate import RiskEstimateResponse
from meu_bebe_api.main import create_app
from meu_bebe_api.ml.runtime import ModelRuntime


def _real_client(runtime: ModelRuntime) -> TestClient:
    settings = Settings(model_load_on_startup=False, _env_file=None)
    return TestClient(create_app(settings, runtime=runtime))


def test_risk_estimate_returns_xai_factors_with_real_model(real_runtime):
    """Verifica que o endpoint retorna fatores de explicabilidade local com modelo real."""
    payload = make_dss_payload()
    with _real_client(real_runtime) as c:
        resp = c.post("/api/v1/risk-estimate", json=payload.model_dump(mode="json"))

    assert resp.status_code == 200
    body = resp.json()

    # Valida conformidade estrita com o modelo Pydantic
    parsed = RiskEstimateResponse.model_validate(body)
    assert parsed.factors is not None
    assert len(parsed.factors) > 0
    assert len(parsed.factors) <= 6

    for factor in parsed.factors:
        assert isinstance(factor.feature, str)
        assert isinstance(factor.label, str)
        assert isinstance(factor.contribution, float)
        assert factor.direction in ("increases_risk", "decreases_risk")
        assert len(factor.description) > 0

        if factor.contribution > 0:
            assert factor.direction == "increases_risk"
        else:
            assert factor.direction == "decreases_risk"


def test_predict_and_explain_fail_closed_graceful_fallback(monkeypatch, real_runtime):
    """Garante mecanismo de defesa fail-closed: se XAI falhar, retorna probabilidade e factors=None."""
    from meu_bebe_ml.explainability import local_xai

    def _failing_explain(*args, **kwargs):
        raise RuntimeError("Simulação de falha inesperada em XAI")

    monkeypatch.setattr(local_xai, "explain_prediction_rf", _failing_explain)

    payload = make_dss_payload()
    prob, factors = real_runtime.predict_and_explain(payload)

    assert isinstance(prob, float)
    assert 0.0 <= prob <= 1.0
    assert factors is None
