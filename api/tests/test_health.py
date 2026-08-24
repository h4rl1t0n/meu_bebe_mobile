"""Testes do health check."""

from __future__ import annotations


def test_health_ok(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.headers["content-type"].startswith("application/json")
    assert resp.json() == {
        "status": "ok",
        "service": "meu-bebe-api",
        "api_version": "0.1.0",
        "dss_schema_version": "1.13",
    }


def test_health_does_not_declare_model_ready(client):
    # Nenhum modelo é carregado nesta fase -> "model_ready" NÃO deve existir.
    body = client.get("/health").json()
    assert "model_ready" not in body
    assert "model" not in body


def test_health_not_under_api_v1_prefix(client):
    # O prefixo /api/v1 fica reservado: /api/v1/health NÃO deve existir.
    assert client.get("/api/v1/health").status_code == 404
