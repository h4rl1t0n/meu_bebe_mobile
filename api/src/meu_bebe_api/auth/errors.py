"""Erros de domínio da autenticação (FASE 8C) — códigos estáveis.

Os códigos seguem a seção 18.1 do plano. ``AuthError`` carrega o código, a
mensagem sanitizada (nunca segredo/senha/token/hash) e o HTTP status. O formato
HTTP é definido no handler de exceção: ``<500`` → plano ``{code, message,
details}``; ``>=500`` → ``{"error": {...}}`` (mesmo envelope dos 500/503 já
existentes no ``/ready`` e no ``/risk-estimate``).
"""

from __future__ import annotations

# Códigos de erro (seção 18.1 do plano).
INVALID_CREDENTIALS = "INVALID_CREDENTIALS"
ACCOUNT_INACTIVE = "ACCOUNT_INACTIVE"
UNAUTHORIZED = "UNAUTHORIZED"
TOKEN_INVALID = "TOKEN_INVALID"
TOKEN_EXPIRED = "TOKEN_EXPIRED"
TOKEN_REVOKED = "TOKEN_REVOKED"
DUPLICATE_EMAIL = "DUPLICATE_EMAIL"
AUTH_NOT_CONFIGURED = "AUTH_NOT_CONFIGURED"
DATABASE_UNAVAILABLE = "DATABASE_UNAVAILABLE"
TOKEN_ERROR = "TOKEN_ERROR"

# Mensagens sanitizadas. Anti-enumeração (seção 12) exige a MESMA mensagem para
# e-mail inexistente e senha errada no login.
INVALID_CREDENTIALS_MESSAGE = "E-mail ou senha inválidos."
ACCOUNT_INACTIVE_MESSAGE = "Conta inativa."
UNAUTHORIZED_MESSAGE = "Credencial de acesso ausente ou inválida."
TOKEN_INVALID_MESSAGE = "Token inválido."
TOKEN_EXPIRED_MESSAGE = "Token expirado."
TOKEN_REVOKED_MESSAGE = "Refresh token revogado."
DUPLICATE_EMAIL_MESSAGE = "E-mail já cadastrado."
AUTH_NOT_CONFIGURED_MESSAGE = "Autenticação não configurada."
DATABASE_UNAVAILABLE_MESSAGE = "Banco de dados indisponível."
TOKEN_ERROR_MESSAGE = "Falha ao processar a solicitação."


class AuthError(Exception):
    """Erro de autenticação mapeado a um envelope HTTP estável."""

    def __init__(self, code: str, message: str, status_code: int) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code
