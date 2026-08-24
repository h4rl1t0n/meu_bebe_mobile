# Meu Bebê API

API Python (FastAPI) do projeto **Meu Bebê** — **FASE 4A: fundação da API + contrato HTTP/DSS**.

Esta fase expõe apenas o *health check* e o contrato de dados DSS 1.13
(48 variáveis em 6 dimensões). **Não** carrega modelo, **não** prediz, **não**
acessa banco e **não** autentica. A IA v1 (`ia/`) permanece congelada e separada.

## Requisitos

- Python **3.14.x** (mesma versão usada pela IA).
- Ambiente virtual **próprio** (`api/.venv`), separado de `ia/.venv`.

## Instalação (Windows / PowerShell)

```powershell
cd api
py -3.14 -m venv .venv
.venv\Scripts\Activate.ps1
pip install -e ".[dev]"
```

## Executar

```powershell
# a partir de api/, com o venv ativado
uvicorn meu_bebe_api.main:app --reload
```

- Health check (infraestrutura): `GET /health`
- Documentação interativa (se `APP_DOCS_ENABLED=true`): `GET /docs`

> O prefixo `/api/v1` fica **reservado** para endpoints funcionais versionados
> futuros (não há rota sob ele nesta fase).

## Testes

```powershell
pytest
```

## Configuração

Via variáveis de ambiente (ver `.env.example`):

| Variável          | Padrão         | Descrição                                   |
|-------------------|----------------|---------------------------------------------|
| `APP_NAME`        | `meu-bebe-api` | Nome do serviço (aparece no health check).  |
| `APP_ENV`         | `development`  | Ambiente (`development`/`production`/etc.). |
| `APP_HOST`        | `127.0.0.1`    | Host de bind do Uvicorn.                    |
| `APP_PORT`        | `8000`         | Porta.                                      |
| `APP_LOG_LEVEL`   | `INFO`         | Nível de log.                               |
| `APP_DOCS_ENABLED`| `true`         | Habilita `/docs`, `/redoc` e `/openapi.json`.|

## Contrato de erro

Toda resposta de erro segue um envelope único:

```json
{
  "code": "VALIDATION_ERROR",
  "message": "Requisição inválida",
  "details": [
    { "loc": ["body", "educacao", "escolaridade"], "msg": "...", "type": "..." }
  ]
}
```

Nenhum *body* bruto nem stack trace é exposto.
