"""Testes do endpoint de readiness ``GET /ready`` (FASE 4B)."""

from __future__ import annotations

import json

from fastapi.testclient import TestClient

from meu_bebe_api.config import Settings
from meu_bebe_api.main import create_app
from meu_bebe_api.ml.artifact import resolve_artifact_path, runtime_library_versions

_ERROR_BODY = {
    "error": {
        "code": "MODEL_NOT_READY",
        "message": "Modelo de inferência indisponível.",
        "details": [],
    }
}


def _corrupted_manifest(tmp_path) -> str:
    """Manifest com hash ERRADO -> força o runtime para o estado ERROR."""
    manifest = tmp_path / "manifest.json"
    manifest.write_text(
        json.dumps(
            {
                "model_name": "random_forest",
                "model_class": "RandomForestClassifier",
                "schema_version": "1.13",
                "n_features": 96,
                "threshold": 0.5,
                "model_file_hash_sha256": "0" * 64,
                "library_versions": runtime_library_versions(),
            }
        ),
        encoding="utf-8",
    )
    return str(manifest)


def test_ready_not_loaded_returns_503_error_contract(client):
    resp = client.get("/ready")
    assert resp.status_code == 503
    assert resp.headers["content-type"].startswith("application/json")
    assert resp.json() == _ERROR_BODY


def test_ready_error_state_returns_503_error_contract(tmp_path):
    artifact = resolve_artifact_path("../ia/artifacts/models/selected_model_v1.joblib")
    manifest = _corrupted_manifest(tmp_path)
    app = create_app(
        Settings(
            model_artifact_path=str(artifact),
            model_manifest_path=manifest,
            model_load_on_startup=True,
            _env_file=None,
        )
    )
    with TestClient(app) as c:
        assert c.get("/health").status_code == 200
        resp = c.get("/ready")
        assert resp.status_code == 503
        assert resp.json() == _ERROR_BODY


def test_ready_503_error_contract_explicit_fields(client):
    body = client.get("/ready").json()
    assert body["error"]["code"] == "MODEL_NOT_READY"
    assert body["error"]["message"] == "Modelo de inferência indisponível."
    assert body["error"]["details"] == []


def test_ready_503_does_not_leak_internal_details(client):
    serialized = client.get("/ready").text
    lowered = serialized.lower()
    for forbidden in (
        "artifacts",
        "selected_model",
        "17db",
        "sha",
        "sklearn",
        "scikit",
        "traceback",
        "hash",
        "manifest",
        ".joblib",
        "c:",
    ):
        assert forbidden not in lowered


def test_health_still_ok_when_model_not_loaded(client):
    # Liveness não depende do modelo (readiness falha, liveness segue 200).
    assert client.get("/health").status_code == 200
    assert client.get("/ready").status_code == 503


def test_ready_ok_with_real_model():
    app = create_app(Settings(model_load_on_startup=True, _env_file=None))
    with TestClient(app) as c:
        resp = c.get("/ready")
        assert resp.status_code == 200
        body = resp.json()
        assert body["status"] == "ready"
        assert body["service"] == "meu-bebe-api"
        assert body["model"] == {
            "name": "random_forest",
            "raw_feature_count": 34,
            "transformed_feature_count": 96,
        }
        # /health também segue 200 com modelo carregado.
        assert c.get("/health").status_code == 200


def test_ready_not_under_api_v1_prefix(client):
    assert client.get("/api/v1/ready").status_code == 404


def test_openapi_exposes_health_and_ready_only(client):
    paths = client.get("/openapi.json").json()["paths"]
    assert "/health" in paths
    assert "/ready" in paths
    for forbidden in ("/predict", "/inference", "/predictions"):
        assert forbidden not in paths
