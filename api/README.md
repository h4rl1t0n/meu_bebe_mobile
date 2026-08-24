# Meu Bebê API

API Python (FastAPI) do projeto **Meu Bebê** — **FASE 4B: integração segura do
runtime de ML com a API**.

A fase anterior (4A) entregou o *health check* e o contrato de dados DSS 1.13
(48 variáveis em 6 dimensões). Esta fase adiciona o carregamento **seguro** do
modelo congelado (RandomForest, DSS 1.13) e um endpoint de *readiness* — **sem**
expor previsão via HTTP (isso fica para a FASE 4C).

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

| Endpoint          | Tipo       | Descrição                                                    |
|-------------------|------------|--------------------------------------------------------------|
| `GET /health`     | liveness   | Sempre `200` (não depende do modelo).                        |
| `GET /ready`      | readiness  | `200` se o modelo carregou; `503` `MODEL_NOT_READY` senão.   |
| `GET /docs`       | documentação | Se `APP_DOCS_ENABLED=true`.                                |

> O prefixo `/api/v1` fica **reservado** para endpoints funcionais versionados
> futuros. **Não** há endpoint público de previsão (`/predict` etc.) nesta fase.

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

Caminhos `MODEL_*` são resolvidos a partir da raiz de `api/`, **independentes do
CWD**.

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
