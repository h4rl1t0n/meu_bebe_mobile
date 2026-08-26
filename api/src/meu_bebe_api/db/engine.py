"""Criação do ``Engine`` SQLAlchemy 2.x SÍNCRONO (FASE 8B).

Regra crítica (congelada na 8B-PLAN): **CRIAR ENGINE != ABRIR CONEXÃO**.

- ``create_engine`` é PREGUIÇOSO: valida a configuração, mas não abre nenhuma
  conexão. O processo FastAPI sobe mesmo com o PostgreSQL temporariamente
  indisponível.
- ``database_url`` ausente/vazia → ``None`` (subsistema persistente inerte).
- ``database_url`` sintaticamente inválida já é rejeitada no ``Settings``
  (config.py), mas ``make_url`` é reaplicado aqui por defesa em profundidade.
- A conexão real ocorre apenas (a) quando o subsistema persistente for usado,
  ou (b) num probe explícito (``db/probe.py``).

A indisponibilidade do PostgreSQL NÃO impede ``/health``, ``/ready`` nem
``/api/v1/risk-estimate`` de funcionarem.
"""

from __future__ import annotations

import logging

from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.engine.url import make_url

from ..config import Settings

logger = logging.getLogger(__name__)

# Timeout curto de CONEXÃO (não de query) — aplicado a toda tentativa de
# conexão do engine, incluindo o probe ``SELECT 1``.
DB_CONNECT_TIMEOUT_SECONDS = 5


def build_engine(settings: Settings) -> Engine | None:
    """Constrói o engine síncrono a partir de ``settings.database_url``.

    Retorna ``None`` quando não há URL configurada (persistência inerte).
    NUNCA abre uma conexão aqui — apenas valida o formato da URL e configura
    o engine de forma preguiçosa.
    """
    url = settings.database_url
    if url is None or url == "":
        logger.debug("DATABASE_URL não configurada; subsistema persistente inerte")
        return None

    # Defesa em profundidade: revalida o formato (Settings já validou).
    make_url(url)

    # ``echo`` é SEMPRE False nesta fase (SQL echo desativado por padrão). NÃO
    # é habilitado automaticamente por ``app_log_level=DEBUG``: futuros
    # statements SQL podem carregar parâmetros/dados pessoais de gestantes, e o
    # logging de SQL deve ser um opt-in deliberado, nunca um efeito colateral do
    # nível de log. ``pool_pre_ping`` recupera conexões mortas do pool;
    # ``connect_timeout`` curto limita qualquer conexão.
    return create_engine(
        url,
        pool_pre_ping=True,
        echo=False,
        connect_args={"connect_timeout": DB_CONNECT_TIMEOUT_SECONDS},
    )
