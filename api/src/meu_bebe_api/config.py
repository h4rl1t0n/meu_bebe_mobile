"""Configuração da aplicação (pydantic-settings).

Nenhum dado pessoal nem corpo de requisição é configurável/lido aqui — apenas
parâmetros de operação do serviço.
"""

from __future__ import annotations

from functools import lru_cache

from pydantic import ValidationInfo, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine.url import make_url


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

    # FASE 8B — persistência (SQLAlchemy 2.x sync + psycopg 3). ``None`` (ou
    # string vazia) mantém o subsistema persistente INERTE: nenhum engine é
    # criado e nada depende do PostgreSQL (o contrato DSS congelado permanece
    # stateless/independente). Quando preenchida, é a URL SQLAlchemy completa
    # (``postgresql+psycopg://...``) — validada como FORMATO (fail-fast de
    # configuração), sem abrir conexão (a conexão é preguiçosa, seção 8B-PLAN).
    database_url: str | None = None
    # URL do banco DEDICADO de testes (``meu_bebe_test``). Usada APENAS pela
    # suíte de integração; NUNCA pelo app em runtime. ``None``/vazia = sem banco
    # de teste configurado (os testes de integração PostgreSQL são pulados).
    test_database_url: str | None = None

    @field_validator("database_url", "test_database_url")
    @classmethod
    def _validate_database_url(
        cls, value: str | None, info: ValidationInfo
    ) -> str | None:
        """Valida apenas o FORMATO da URL (não abre conexão).

        ``None``/vazio → subsistema inerte/sem teste (sem erro). URL não vazia e
        sintaticamente inválida → erro de CONFIGURAÇÃO (falha previsível na
        inicialização), distinto de indisponibilidade do PostgreSQL em runtime.
        """
        if value is None or value == "":
            return None
        try:
            make_url(value)
        except Exception as exc:  # noqa: BLE001 — vira erro de configuração
            field = info.field_name.upper()
            raise ValueError(
                f"{field} inválida (formato SQLAlchemy): {exc!s}"
            ) from exc
        return value


@lru_cache
def get_settings() -> Settings:
    """Retorna a instância de configuração (cacheada por processo)."""
    return Settings()
