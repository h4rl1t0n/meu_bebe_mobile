"""Repositories de acesso a dados (FASE 8C).

Os repositories NÃO fazem ``commit`` — apenas queries/ORM na ``Session``. O
``commit``/``rollback`` é responsabilidade exclusiva do service (arquitetura 8B).
"""

from __future__ import annotations

from .auth_refresh_session_repository import AuthRefreshSessionRepository
from .avaliacao_dss_repository import AvaliacaoDssRepository
from .consulta_repository import ConsultaRepository
from .exame_repository import ExameRepository
from .gestacao_repository import GestacaoRepository
from .gestante_repository import GestanteRepository
from .medicamento_repository import MedicamentoRepository
from .plano_parto_repository import PlanoPartoRepository
from .user_repository import UserRepository
from .vacina_repository import VacinaRepository

__all__ = [
    "UserRepository",
    "AuthRefreshSessionRepository",
    "GestanteRepository",
    "GestacaoRepository",
    "ConsultaRepository",
    "ExameRepository",
    "MedicamentoRepository",
    "PlanoPartoRepository",
    "VacinaRepository",
    "AvaliacaoDssRepository",
]
