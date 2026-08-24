"""Testes do OpenAPI e da documentação interativa."""

from __future__ import annotations

from fastapi.testclient import TestClient

from meu_bebe_api.config import Settings
from meu_bebe_api.main import create_app


def test_openapi_title_and_version(client):
    schema = client.get("/openapi.json").json()
    assert schema["info"]["title"] == "Meu Bebê API"
    assert schema["info"]["version"] == "0.1.0"


def test_openapi_exposes_health_at_root_only(client):
    schema = client.get("/openapi.json").json()
    assert "/health" in schema["paths"]
    assert "/api/v1/health" not in schema["paths"]


def test_openapi_has_no_ml_or_validate_endpoints(client):
    schema = client.get("/openapi.json").json()
    for forbidden in ("/predict", "/inference", "/validate", "/api/v1/validate"):
        assert forbidden not in schema["paths"]


def test_openapi_contains_medical_disclaimer(client):
    schema = client.get("/openapi.json").json()
    assert "não fornece" in schema["info"]["description"].lower()


def test_docs_enabled_by_default(client):
    assert client.get("/docs").status_code == 200
    assert client.get("/openapi.json").status_code == 200


def test_docs_disabled_hides_docs_and_openapi():
    app = create_app(Settings(app_docs_enabled=False, _env_file=None))
    with TestClient(app) as c:
        assert c.get("/docs").status_code == 404
        assert c.get("/redoc").status_code == 404
        assert c.get("/openapi.json").status_code == 404
