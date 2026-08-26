# Meu Bebê API

API Python (FastAPI) do projeto **Meu Bebê** — **FASE 4C: endpoint HTTP de
estimativa probabilística experimental**.

As fases anteriores entregaram o *health check* e o contrato de dados DSS 1.13
(4A, 48 variáveis em 6 dimensões) e o carregamento **seguro** do modelo
congelado com *readiness* (4B, RandomForest, DSS 1.13). Esta fase expõe a
estimativa probabilística **experimental** via HTTP — **sem** threshold,
classificação, faixa de risco nem recomendação.

A IA v1 (`ia/`) permanece congelada e separada. O artefato continua em
`ia/artifacts/models/` (nunca é copiado para `api/`).

## Requisitos

- Python **3.14.x** (mesma versão usada pela IA).
- Ambiente virtual **próprio** (`api/.venv`), separado de `ia/.venv`.

## Instalação (Windows / PowerShell)

```powershell
cd api
py -3.14 -m venv .venv
.venv\Scripts\Activate.ps1
pip install -e ".[dev]"     # deps da API (FastAPI, Pydantic, etc.)
pip install -e ..\ia        # pacote ML congelado (meu_bebe_ml) + deps de ML
```

> A ordem acima instala o pacote `meu_bebe_ml` de forma **editável** (sem
> `sys.path`/`PYTHONPATH`/cópia de módulos). As dependências de ML
> (scikit-learn, numpy, pandas, joblib, …) vêm **do pacote IA**, não são
> duplicadas no `pyproject.toml` da API.

## Executar

```powershell
# a partir de api/, com o venv ativado
uvicorn meu_bebe_api.main:app --reload
```

| Endpoint                      | Tipo       | Descrição                                                    |
|-------------------------------|------------|--------------------------------------------------------------|
| `GET /health`                 | liveness   | Sempre `200` (não depende do modelo).                        |
| `GET /ready`                  | readiness  | `200` se o modelo carregou; `503` `MODEL_NOT_READY` senão.   |
| `POST /api/v1/risk-estimate`  | funcional  | Estimativa probabilística experimental (DSS 1.13).           |
| `GET /docs`                   | documentação | Se `APP_DOCS_ENABLED=true`.                                |

> Não há endpoint público de **previsão/classificação** (`/predict`,
> `/inference`, `/classify` etc.) — apenas a estimativa probabilística
> experimental em `/api/v1/risk-estimate`.

## Readiness (`/ready`)

- **200** (modelo carregado):
  ```json
  {"status": "ready", "service": "meu-bebe-api",
   "model": {"name": "random_forest", "raw_feature_count": 34,
             "transformed_feature_count": 96}}
  ```
- **503** (modelo ausente/incompatível — sem detalhes internos):
  ```json
  {"error": {"code": "MODEL_NOT_READY",
             "message": "Modelo de inferência indisponível.", "details": []}}
  ```

O carregamento é **FAIL-CLOSED** e segue uma ordem rígida: resolver caminho →
confirmar arquivo → validar manifest → validar compatibilidade de versões →
calcular SHA-256 → comparar hash → **só então** `joblib.load` → validar objeto →
marcar READY. Nenhum `fit`/`fit_transform` é executado (sem retreinamento).

## Estimativa de risco (`/api/v1/risk-estimate`)

`POST /api/v1/risk-estimate` recebe **diretamente** o questionário DSS 1.13
(`DssPayload`, as 48 variáveis em 6 dimensões — sem *wrapper* como
`{"questionnaire": ...}`) e devolve a **estimativa probabilística
experimental** do desfecho sintético.

**Exemplo de requisição** (corpo = `DssPayload` canônico):

```json
{
  "schema_version": "1.13",
  "educacao": { "estuda_atualmente": true, "escolaridade": "medio_completo", "..." },
  "trabalho": { "..." },
  "saneamento": { "..." },
  "saude": { "..." },
  "habitacao": { "..." },
  "alimentacao": { "..." }
}
```

**Exemplo de resposta (200):**

```json
{
  "result": { "target": "descontinuou_pre_natal", "probability": 0.222 },
  "model": {
    "name": "random_forest",
    "schema_version": "1.13",
    "raw_feature_count": 34,
    "transformed_feature_count": 96
  },
  "notice": "Estimativa estatística experimental baseada em dados sintéticos; não constitui diagnóstico médico nem certeza de descontinuidade do pré-natal."
}
```

**Erros:**

| Código HTTP | Contrato                                                                  |
|-------------|---------------------------------------------------------------------------|
| `422`       | Payload DSS inválido (`VALIDATION_ERROR`).                                |
| `503`       | Modelo não carregado (`MODEL_NOT_READY`, mesmo do `/ready`).              |
| `500`       | Falha inesperada na inferência (`INFERENCE_ERROR`, sanitizado).           |

**Limitações (obrigatórias):**

- **Dados sintéticos**: o modelo foi desenvolvido/avaliado sobre dados
  sintéticos; a saída é uma estimativa **experimental**.
- **Não é diagnóstico médico** nem previsão clínica validada.
- **Sem threshold operacional** e **sem classificação**: a API expõe apenas a
  probabilidade (um `float` em `[0,1]`, sem arredondamento). O Flutter poderá
  formatar futuramente.
- **Sem persistência**: a API é *stateless*; nenhum questionário é armazenado,
  logado ou ecoado na resposta.
- O `target` (`descontinuou_pre_natal`) é apenas o **nome da variável resposta**
  do experimento — não é uma afirmação de que o desfecho ocorreu.

## Testes

```powershell
pytest
```

## Configuração

Via variáveis de ambiente (ver `.env.example`):

| Variável               | Padrão                                           | Descrição                                   |
|------------------------|--------------------------------------------------|---------------------------------------------|
| `APP_NAME`             | `meu-bebe-api`                                   | Nome do serviço (health/readiness).         |
| `APP_ENV`              | `development`                                    | Ambiente (`development`/`production`/etc.). |
| `APP_HOST`             | `127.0.0.1`                                      | Host de bind do Uvicorn.                    |
| `APP_PORT`             | `8000`                                           | Porta.                                      |
| `APP_LOG_LEVEL`        | `INFO`                                           | Nível de log.                               |
| `APP_DOCS_ENABLED`     | `true`                                           | Habilita `/docs`, `/redoc` e `/openapi.json`.|
| `MODEL_ARTIFACT_PATH`  | `../ia/artifacts/models/selected_model_v1.joblib` | Joblib do modelo (relativo a `api/`).      |
| `MODEL_MANIFEST_PATH`  | `../ia/artifacts/models/selected_model_v1_manifest.json` | Manifest do modelo.                |
| `MODEL_LOAD_ON_STARTUP`| `true`                                           | Carrega o modelo no startup.                |
| `DATABASE_URL`         | *(vazio)*                                        | URL SQLAlchemy (`postgresql+psycopg://…`). Vazio = persistência inerte. |
| `TEST_DATABASE_URL`    | *(vazio)*                                        | URL do banco de teste (`meu_bebe_test`), só para a suíte de integração. Vazio = testes pulados. |

Caminhos `MODEL_*` são resolvidos a partir da raiz de `api/`, **independentes do
CWD**.

## Persistência (FASE 8B — infraestrutura)

A infraestrutura de persistência (SQLAlchemy 2.x **síncrono** + psycopg 3 +
Alembic) está preparada, mas **sem entidades de domínio**: nenhuma tabela é
criada nesta fase e o endpoint DSS (`/api/v1/risk-estimate`) continua
**stateless e independente de banco**.

- **Inerte por padrão:** com `DATABASE_URL` vazio, nenhum engine é criado e nada
  depende do PostgreSQL.
- **Engine preguiçoso:** criar o engine **não** abre conexão — o processo sobe
  mesmo com o PostgreSQL indisponível; a conexão só ocorre ao usar o subsistema
  persistente ou num probe explícito (`SELECT 1`).
- **Dois bancos locais (recomendado):** `meu_bebe` (dev) e `meu_bebe_test`
  (testes), criados manualmente:

  ```sql
  CREATE DATABASE meu_bebe;
  CREATE DATABASE meu_bebe_test;
  ```

- **Configuração:** defina no `.env` (nunca versionar senha):

  ```env
  DATABASE_URL=postgresql+psycopg://usuario:senha@localhost:5432/meu_bebe
  ```

- **Testes de integração:** executam apenas quando `TEST_DATABASE_URL` aponta
  para o banco de teste (`meu_bebe_test`) e o PostgreSQL está alcançável; caso
  contrário, são pulados explicitamente (nunca substituídos por SQLite).

- **Migrations (Alembic):** configuradas em `alembic.ini` + `alembic/`. Nenhum
  revision foi criado (decisão 8B-PLAN §18): a primeira migration nascerá junto
  com a primeira entidade real (8C/8D).

  ```powershell
  # a partir de api/, com o venv ativado
  alembic heads        # sem revisões nesta fase
  alembic history      # sem histórico
  ```

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

Nenhum *body* bruto, caminho absoluto, hash ou stack trace é exposto.
