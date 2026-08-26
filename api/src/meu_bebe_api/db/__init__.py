"""Camada de infraestrutura de persistência (FASE 8B).

Estrutura mínima e proporcional ao projeto: uma Base declarativa única,
engine/session síncronos (SQLAlchemy 2.x + psycopg 3) e um probe de
disponibilidade do PostgreSQL. Nenhuma entidade de domínio vive aqui ainda.

Separação ML × DB: este pacote é independente do ``ml/``; a disponibilidade do
banco NUNCA afeta o fluxo DSS congelado (``/api/v1/risk-estimate``) nem a
readiness do modelo.
"""
