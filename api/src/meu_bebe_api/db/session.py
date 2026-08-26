"""Session factory síncrona + dependency ``get_session`` (FASE 8B).

Política congelada (8B-PLAN): UMA ``Session`` POR REQUEST.

- A dependency obtém/cria a ``Session``, faz ``yield`` e fecha em ``finally``.
- A dependency NÃO executa commit automático e NÃO esconde rollback: o controle
  de transação é do service/use case (futuro); aqui só se gerencia o ciclo de
  vida da ``Session``.
- NÃO há ``scoped_session`` global e NÃO se compartilha a mesma ``Session``
  entre requests.
"""

from __future__ import annotations

from collections.abc import Iterator

from fastapi import Request
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker


def build_session_factory(engine: Engine | None) -> sessionmaker[Session] | None:
    """Cria a ``sessionmaker`` vinculada ao engine (ou ``None`` se não houver)."""
    if engine is None:
        return None
    # ``expire_on_commit=False`` evita refresh automático desnecessário após o
    # commit do service/use case; ``autoflush=False`` deixa o flush explícito
    # (a transação é controlada pelo service/use case).
    return sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def get_session(request: Request) -> Iterator[Session]:
    """Dependency FastAPI: fornece uma ``Session`` por request e a fecha.

    Levanta ``RuntimeError`` se o ``session_factory`` não foi registrado no
    ``app.state`` (o lifespan o registra antes de aceitar requisições). O
    ``close()`` no ``finally`` devolve a conexão ao pool mesmo em exceção.
    """
    factory = getattr(request.app.state, "session_factory", None)
    if factory is None:
        raise RuntimeError("session_factory não inicializado no app.state")

    session: Session = factory()
    try:
        yield session
    finally:
        session.close()
