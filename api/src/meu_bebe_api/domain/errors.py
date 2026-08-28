"""Erros de domínio (FASE 8D) — códigos estáveis.

``DomainError`` segue o mesmo padrão de ``AuthError`` (8C): código, mensagem
sanitizada (nunca dado pessoal/segredo) e HTTP status. O handler em
``core.exception_handlers`` mapeia ``<500`` → plano ``{code, message, details}``
e ``>=500`` → ``{"error": {...}}``.

Códigos mínimos (seção 22 do plano). ``DATABASE_UNAVAILABLE`` é REUTILIZADO da
auth (mesmo erro de infraestrutura, sem duplicar código).
"""

from __future__ import annotations

from ..auth.errors import DATABASE_UNAVAILABLE, DATABASE_UNAVAILABLE_MESSAGE

PROFILE_NOT_FOUND = "PROFILE_NOT_FOUND"
PROFILE_ALREADY_EXISTS = "PROFILE_ALREADY_EXISTS"
PREGNANCY_NOT_FOUND = "PREGNANCY_NOT_FOUND"
ACTIVE_PREGNANCY_ALREADY_EXISTS = "ACTIVE_PREGNANCY_ALREADY_EXISTS"
PREGNANCY_REOPEN_NOT_ALLOWED = "PREGNANCY_REOPEN_NOT_ALLOWED"
OBSTETRIC_HISTORY_NOT_FOUND = "OBSTETRIC_HISTORY_NOT_FOUND"
CONSULTA_NOT_FOUND = "CONSULTA_NOT_FOUND"
EXAME_NOT_FOUND = "EXAME_NOT_FOUND"
MEDICAMENTO_NOT_FOUND = "MEDICAMENTO_NOT_FOUND"
VACINA_NOT_FOUND = "VACINA_NOT_FOUND"
PLANO_PARTO_NOT_FOUND = "PLANO_PARTO_NOT_FOUND"
AVALIACAO_DSS_NOT_FOUND = "AVALIACAO_DSS_NOT_FOUND"
DOMAIN_ERROR = "DOMAIN_ERROR"

PROFILE_NOT_FOUND_MESSAGE = "Perfil de gestante não encontrado."
PROFILE_ALREADY_EXISTS_MESSAGE = "Perfil de gestante já cadastrado."
PREGNANCY_NOT_FOUND_MESSAGE = "Gestação não encontrada."
ACTIVE_PREGNANCY_ALREADY_EXISTS_MESSAGE = "Já existe uma gestação ativa."
PREGNANCY_REOPEN_NOT_ALLOWED_MESSAGE = "Não é permitido reabrir uma gestação encerrada."
OBSTETRIC_HISTORY_NOT_FOUND_MESSAGE = "Histórico obstétrico não encontrado."
CONSULTA_NOT_FOUND_MESSAGE = "Consulta não encontrada."
EXAME_NOT_FOUND_MESSAGE = "Exame não encontrado."
MEDICAMENTO_NOT_FOUND_MESSAGE = "Medicamento não encontrado."
VACINA_NOT_FOUND_MESSAGE = "Vacina não encontrada."
PLANO_PARTO_NOT_FOUND_MESSAGE = "Plano de parto não encontrado."
AVALIACAO_DSS_NOT_FOUND_MESSAGE = "Avaliação DSS não encontrada."
DOMAIN_ERROR_MESSAGE = "Falha ao processar a solicitação."

# Reexporta o erro de infraestrutura compartilhado com a auth (seção 22).
__all__ = [
    "DATABASE_UNAVAILABLE",
    "DATABASE_UNAVAILABLE_MESSAGE",
    "PROFILE_NOT_FOUND",
    "PROFILE_NOT_FOUND_MESSAGE",
    "PROFILE_ALREADY_EXISTS",
    "PROFILE_ALREADY_EXISTS_MESSAGE",
    "PREGNANCY_NOT_FOUND",
    "PREGNANCY_NOT_FOUND_MESSAGE",
    "ACTIVE_PREGNANCY_ALREADY_EXISTS",
    "ACTIVE_PREGNANCY_ALREADY_EXISTS_MESSAGE",
    "PREGNANCY_REOPEN_NOT_ALLOWED",
    "PREGNANCY_REOPEN_NOT_ALLOWED_MESSAGE",
    "OBSTETRIC_HISTORY_NOT_FOUND",
    "OBSTETRIC_HISTORY_NOT_FOUND_MESSAGE",
    "CONSULTA_NOT_FOUND",
    "CONSULTA_NOT_FOUND_MESSAGE",
    "EXAME_NOT_FOUND",
    "EXAME_NOT_FOUND_MESSAGE",
    "MEDICAMENTO_NOT_FOUND",
    "MEDICAMENTO_NOT_FOUND_MESSAGE",
    "VACINA_NOT_FOUND",
    "VACINA_NOT_FOUND_MESSAGE",
    "PLANO_PARTO_NOT_FOUND",
    "PLANO_PARTO_NOT_FOUND_MESSAGE",
    "AVALIACAO_DSS_NOT_FOUND",
    "AVALIACAO_DSS_NOT_FOUND_MESSAGE",
    "DOMAIN_ERROR",
    "DOMAIN_ERROR_MESSAGE",
    "DomainError",
]


class DomainError(Exception):
    """Erro de domínio mapeado a um envelope HTTP estável."""

    def __init__(self, code: str, message: str, status_code: int) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code
