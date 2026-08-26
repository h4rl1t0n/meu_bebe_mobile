"""Probe de disponibilidade do PostgreSQL (FASE 8B).

Verificação ESPECÍFICA do subsistema persistente, separada de ``/health``
(liveness) e ``/ready`` (readiness do modelo ML). NÃO é um endpoint público: é
uma função de infraestrutura, testável de forma independente do fluxo DSS.

Usa ``SELECT 1`` — barato, timeout curto (via ``connect_timeout`` do engine),
resultado controlado (bool), sem expor informação sensível nem stack trace.
"""

from __future__ import annotations

import logging

from sqlalchemy import text
from sqlalchemy.engine import Engine

logger = logging.getLogger(__name__)


def probe_database(engine: Engine | None) -> bool:
    """Verifica se o PostgreSQL está alcançável com um ``SELECT 1``.

    - ``engine`` ausente (persistência inerte) → ``False``.
    - Indisponibilidade/erro de conexão/erro no probe → ``False`` (controlado),
      NUNCA uma exceção. O resultado distingue apenas "alcançável × não
      alcançável", sem vazar host/senha/SQL/stack trace.
    """
    if engine is None:
        return False

    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return True
    except Exception:  # noqa: BLE001 — indisponibilidade é resultado controlado
        logger.debug(
            "probe do PostgreSQL falhou (indisponível ou erro de conexão)"
        )
        return False
