"""Runtime de ML da API (FASE 4B).

Integração segura com o artefato congelado de ``ia/`` (DSS 1.13). NÃO duplica
preprocessing nem a lista de features: reutiliza os helpers canônicos do pacote
``meu_bebe_ml`` (instalado editável). O artefato permanece em
``ia/artifacts/models/`` — nunca é copiado para ``api/``.
"""
