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


@lru_cache
def get_settings() -> Settings:
    """Retorna a instância de configuração (cacheada por processo)."""
    return Settings()
