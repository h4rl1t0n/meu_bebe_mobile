"""Configuração da aplicação (pydantic-settings).

Nenhum dado pessoal nem corpo de requisição é configurável/lido aqui — apenas
parâmetros de operação do serviço.
"""

from __future__ import annotations

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Parâmetros de operação, lidos de variáveis de ambiente / ``.env``."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    app_name: str = "meu-bebe-api"
    app_env: str = "development"
    app_host: str = "127.0.0.1"
    app_port: int = 8000
    app_log_level: str = "INFO"
    app_docs_enabled: bool = True

    # Caminhos do artefato de ML (FASE 4B). São RELATIVOS à raiz de ``api/`` e
    # resolvidos de forma independente do CWD (ver ``ml.artifact``). O artefato
    # NÃO é copiado para ``api/``: continua em ``ia/artifacts/models/``.
    model_artifact_path: str = "../ia/artifacts/models/selected_model_v1.joblib"
    model_manifest_path: str = "../ia/artifacts/models/selected_model_v1_manifest.json"
    # Se ``false``, o app sobe sem carregar o modelo (``/ready`` responde 503).
    model_load_on_startup: bool = True


@lru_cache
def get_settings() -> Settings:
    """Retorna a instância de configuração (cacheada por processo)."""
    return Settings()
