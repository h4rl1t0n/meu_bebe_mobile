# FASE 4A — Fundação da API Python + Contrato HTTP/DSS (Relatório)

**Status:** concluído (após correção do health check) · **Commit:** nenhum (aguardando revisão) · **Testes:** 72 passed

---

## 1. Precondições

| Item | Resultado |
|---|---|
| `git status --short` limpo no início | ✅ limpo (último commit `67fd370` — FASE 3H) |
| Python 3.14.x | ✅ 3.14.5 (usado no `api/.venv`) |
| Ambiente separado de `ia/.venv` | ✅ `api/.venv` criado via `python -m venv` |

## 2. Auditoria de contrato (somente leitura — tarefa #94)

Derivei todos os códigos/nomes dos arquivos congelados e **não encontrei
divergência** entre Flutter e IA:

- Envelope canônico = `FormularioData.toMap()` → `schema_version` + 6 seções:
  **`educacao`, `trabalho`, `saneamento`, `saude`, `habitacao`, `alimentacao`**.
- `toFlatMap()` (`dimensao.campo`) **NÃO** é o contrato HTTP — ignorado.
- 48 variáveis conferidas campo a campo contra `ia/src/meu_bebe_ml/schema/constants.py`
  (`Q_FULL`) e `ia/configs/schema_v1_13.yaml`. Contagem por dimensão:
  Educação 6 · Trabalho 10 · Saneamento 7 · Saúde 9 · Habitação 9 · Alimentação 7.
- 27 enums canônicos derivados de `catalog/*_options.dart` (código snake_case,
  nunca rótulo).

> **Nota (não é divergência):** a IA nomeia a dimensão internamente como
> `trabalho_renda` (rótulo de classificação metodológica), enquanto a chave JSON
> do Flutter é `trabalho`. O contrato HTTP usa **`trabalho`** (chave real do
> `toMap()`).

## 3. Estrutura criada (somente `api/`)

```
api/
├── pyproject.toml            # src-layout, deps: fastapi/uvicorn/pydantic/pydantic-settings
├── .gitignore                # .venv/, __pycache__/, .env etc.
├── .env.example              # APP_NAME/APP_ENV/APP_HOST/APP_PORT/APP_LOG_LEVEL/APP_DOCS_ENABLED
├── README.md                 # Windows/PowerShell
├── FASE_4A_REPORT.md
├── src/meu_bebe_api/
│   ├── __init__.py           # __version__ = "0.1.0"
│   ├── config.py             # Settings (pydantic-settings)
│   ├── main.py               # create_app() + app = create_app()
│   ├── api/{__init__,health}.py
│   ├── contracts/{__init__,dss,errors}.py
│   └── core/{__init__,exception_handlers}.py
└── tests/{conftest,test_health,test_dss_contract,test_error_contract,test_openapi}.py
```

## 4. Health check (corrigido)

- `GET /health` → **200** com o JSON exato (sem `model_ready`):

  ```json
  {"status":"ok","service":"meu-bebe-api","api_version":"0.1.0","dss_schema_version":"1.13"}
  ```

- `GET /api/v1/health` → **404** (`NOT_FOUND`). O prefixo `/api/v1` fica
  **reservado** para endpoints funcionais versionados futuros; nenhum endpoint
  é registrado sob ele nesta fase.

## 5. Verificação de conformidade (resumo dos itens do spec)

| # | Requisito | Cumprido |
|---|---|---|
| 1 | IA v1 congelada, não modificada | ✅ `git status` só mostra `api/` novo |
| 2 | Nada fora de `api/` alterado | ✅ |
| 3 | Nenhum código ML em `api/` | ✅ sem ML/prediction |
| 4 | Stack sem framework extra | ✅ FastAPI + Pydantic v2 + pydantic-settings + Uvicorn + pytest + httpx |
| 5 | Proibidos (Django/Flask/SQLAlchemy/ORM/Celery/Redis/DB/JWT) | ✅ nenhum |
| 6 | `create_app()` + `app = create_app()` | ✅ |
| 7 | `API_VERSION` (`0.1.0`) separada de `DSS_SCHEMA_VERSION` (`1.13`) | ✅ |
| 8 | `GET /health` na raiz; `/api/v1` reservado (sem rota) | ✅ |
| 9 | Health sem `model_ready` | ✅ testado (`"model_ready" not in body`) |
| 10 | 6 settings via pydantic-settings | ✅ |
| 11 | Sem CORS wildcard | ✅ nenhum `CORSMiddleware` |
| 12 | Sem log de body/dados pessoais | ✅ handler descarta `input`; sem logging de corpo |
| 13 | Chave ausente→erro; null aceito só quando permitido; `bool \| None` sem default | ✅ |
| 14 | StrictBool/StrictInt + Enum canônico | ✅ |
| 15 | `extra="forbid"` em todos os modelos | ✅ |
| 16 | Multiselect `list[código]` + exclusividade | ✅ `sem_dificuldades/sem_beneficios/sem_cuidados/sem_melhorias/nenhum_dos_listados` |
| 17 | Null estrutural (`empregado`→`tipo_emprego`/`beneficios_trabalho`/`motivo_desemprego`; `frequencia_coleta_lixo`→`destino_lixo_sem_coleta`) | ✅ |
| 18 | Health nullable (`faltou_consulta`, `exames_pre_natal_completos`, `vacinas_em_dia`) | ✅ `StrictBool \| None` |
| 19 | Invariantes Habitação (`>=1`; `dormitorios <= comodos`) | ✅ `StrictInt ge=1` + validator |
| 20 | Contrato de erro `VALIDATION_ERROR`/`NOT_FOUND` | ✅ |
| 21 | Handlers 422 (RequestValidationError) e 404 | ✅ sem body/stack trace |
| 22 | OpenAPI título "Meu Bebê API", versão 0.1.0, aviso médico | ✅ |
| 23 | `APP_DOCS_ENABLED=false` desabilita `/docs`/`/redoc`/`/openapi.json` | ✅ aprovado e mantido |
| 24 | Sem `/predict`, sem carregar modelo, sem DB, sem auth | ✅ |
| 25 | Sem abstrações falsas (PredictionService etc.) | ✅ |
| 26 | Sem copiar `selected_model_v1.joblib`; sem `api/models/` | ✅ |
| 27 | Sem deps ML (scikit-learn/xgboost/numpy/pandas/joblib) | ✅ |
| 28 | Testes (health, 48 chaves, presence, strict, enum, multiselect, structural null, extra, 422, openapi, docs) | ✅ 72 tests |
| 29 | Sem endpoint público `/validate` (422 testado via rota só-de-teste) | ✅ `/_test/validate` em conftest |
| 30 | Sem commit | ✅ |

## 6. Testes

```
72 passed, 1 warning in 0.16s
```

- `test_health.py` — 3 · `test_dss_contract.py` — 58 · `test_error_contract.py` — 5 · `test_openapi.py` — 6.

O warning é cosmético e **mantido por decisão do revisor** (não trocar `httpx`
por `httpx2`):

```
StarletteDeprecationWarning: Using `httpx` with `starlette.testclient` is deprecated;
install `httpx2` instead.
  from starlette.testclient import TestClient as TestClient  # noqa
```

## 7. Verificações finais

- `python -m compileall -q src` → OK.
- Smoke real (`TestClient`): `GET /health` → **200**; `GET /api/v1/health` → **404**;
  `GET /openapi.json` → **200**; `paths` do OpenAPI = `['/health']` (nenhum
  `/predict`, `/inference` ou `/validate`).
- `git diff --check` → limpo (sem whitespace errors).
- `git status --porcelain` → apenas arquivos novos dentro de `api/` (`.venv/`,
  `__pycache__/`, `.egg-info/` corretamente ignorados).

**Confirmado:** schema DSS continua `1.13`; exatamente 48 variáveis; nenhum
contrato Pydantic relaxado; nenhum modelo ML carregado; nenhuma dependência ML;
nenhum banco; nenhuma autenticação; `ia/` não alterado; Flutter não alterado;
nenhum commit realizado.

**Aguardando revisão.**
