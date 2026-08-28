"""Router funcional versionado (FASE 4C) — prefixo ``/api/v1``.

Reúne os endpoints funcionais versionados. Os endpoints de infraestrutura
(``/health`` e ``/ready``) permanecem na RAIZ e NÃO são movidos para cá.
"""

from __future__ import annotations

from fastapi import APIRouter

from .auth import router as auth_router
from .avaliacoes_dss import router as avaliacoes_dss_router
from .consultas import router as consultas_router
from .exames import router as exames_router
from .gestacoes import router as gestacoes_router
from .gestantes import router as gestantes_router
from .historico_obstetrico import router as historico_obstetrico_router
from .medicamentos import router as medicamentos_router
from .plano_parto import router as plano_parto_router
from .risk_estimate import router as risk_estimate_router
from .vacinas import router as vacinas_router

api_v1_router = APIRouter(prefix="/api/v1")
api_v1_router.include_router(risk_estimate_router)
api_v1_router.include_router(auth_router)
api_v1_router.include_router(gestantes_router)
api_v1_router.include_router(gestacoes_router)
api_v1_router.include_router(historico_obstetrico_router)
api_v1_router.include_router(consultas_router)
api_v1_router.include_router(exames_router)
api_v1_router.include_router(medicamentos_router)
api_v1_router.include_router(vacinas_router)
api_v1_router.include_router(plano_parto_router)
api_v1_router.include_router(avaliacoes_dss_router)
