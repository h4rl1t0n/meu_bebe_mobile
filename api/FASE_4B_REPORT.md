# FASE 4B — Integração segura do runtime de ML com a API (Relatório)

**Status:** concluído (aguardando revisão) · **Commit:** nenhum (aguardando revisão)
**Testes:** 109 passed (72 da 4A + 37 novos) · **Smoke real:** OK · **Smoke de falha:** OK

---

## 0. Objetivo

Carregar o modelo congelado (`selected_model_v1.joblib`, DSS 1.13) de forma
**segura** dentro da API, expor apenas *readiness* (`GET /ready`) e inferência
**interna** (`predict_probability`), **sem** endpoint público de previsão.
A IA (`ia/`) permanece congelada e o artefato continua em `ia/artifacts/models/`.

## 1. Escopo respeitado (arquitetura congelada)

- **Alterado somente `api/`** (código, testes, `.env.example`, README, relatório).
- `ia/src/`, `ia/tests/`, `ia/configs/`, `ia/data/`, `ia/artifacts/`,
  `ia/pyproject.toml` **não foram tocados** (somente lidos).
- Flutter (`lib/`) **não foi alterado**.
- Nenhuma mudança na IA foi necessária → **não houve "PARE E REPORTE"**.

## 2. Ambiente

| Item | Resultado |
|---|---|
| Python | 3.14.5 (`api/.venv`) |
| Ambiente separado de `ia/.venv` | ✅ `api/.venv` próprio |
| `pip install -e ..\ia` | ✅ wheel editável `meu_bebe_ml-0.1.0` |
| Sem `sys.path.append` / `PYTHONPATH` / cópia de módulos / vendor | ✅ |
| `import meu_bebe_ml` resolve para `ia/src/meu_bebe_ml/__init__.py` | ✅ |
| `pip check` | ✅ "No broken requirements found." |

**Versões de runtime (todas idênticas ao manifest, sem incompatibilidade):**

| Lib | Manifest | Runtime |
|---|---|---|
| python | 3.14.5 | 3.14.5 |
| numpy | 2.5.2 | 2.5.2 |
| pandas | 3.0.5 | 3.0.5 |
| scipy | 1.18.1 | 1.18.1 |
| scikit_learn | 1.9.0 | 1.9.0 |
| xgboost | 3.4.1 | 3.4.1 |
| matplotlib | 3.11.1 | 3.11.1 |
| joblib | 1.5.3 | 1.5.3 |

## 3. Manifest real (auditado, NÃO reescrito, NÃO inventado)

Campos realmente presentes em `selected_model_v1_manifest.json`:

- `model_name="random_forest"`, `display_name="Random Forest"`,
  `model_class="RandomForestClassifier"`, `protocol_version="1.0"`,
  `schema_version="1.13"`, `preprocessing_version="1.0"`, `fit_scope`,
  `n_train=4000`, `class_counts_train={Y0:3023, Y1:977}`,
  `n_features=96`, `scale_pos_weight=null`, `threshold=0.5`,
  `dataset_hash_sha256`, `split_file_hash_sha256`, `folds_file_hash_sha256`,
  `training_protocol_config_hash_sha256`, `preprocessing_config_hash_sha256`,
  **`model_file_hash_sha256`**,
  `library_versions` (8 libs acima), `timestamp`, `note`.

**Ausências registradas (não fabricadas):** não há `raw_feature_count`, não há
`feature_names`, não há `artifact_version`. O `raw_feature_count=34` usado no
`/ready` vem de `len(X_MODEL)` (canônico), **não** do manifest.

## 4. Modelo carregado (estrutura validada)

- `Pipeline(steps=[("preprocessor", ColumnTransformer), ("model", RandomForestClassifier)])`.
- Preprocessor = `ColumnTransformer` com 6 transformers:
  `boolean_required`, `boolean_structural`, `numeric`, `ordinal`, `nominal`, `multiselect`.
- `feature_names_in_` do preprocessor = **34** (ordem idêntica a `X_MODEL`).
- `get_feature_names_out()` = **96** (ordem idêntica a `resolve_spec().feature_names`).
- Estimador = `RandomForestClassifier`; `classes_ == [0,1]`; classe positiva = índice 1.
- Hiperparâmetros congelados conferidos: `n_estimators=500`, `criterion="gini"`,
  `max_depth=None`, `min_samples_split=2`, `min_samples_leaf=1`,
  `max_features="sqrt"`, `class_weight="balanced_subsample"`, `random_state=42`,
  `n_jobs=-1`.
- **Nenhum** `fit`/`fit_transform` executado (sem retreinamento).

## 5. Estrutura criada (somente `api/`)

```
api/src/meu_bebe_api/
├── config.py                    # + model_artifact_path / model_manifest_path / model_load_on_startup
├── main.py                      # lifespan (asynccontextmanager) + DI + /ready
├── api/{health,ready}.py        # /health (liveness) + /ready (readiness)
├── ml/
│   ├── __init__.py
│   ├── errors.py                # ModelError + subclasses (codes internos)
│   ├── artifact.py              # paths, manifest, SHA-256, compatibilidade
│   ├── adapter.py               # DssPayload -> X_MODEL (1x34)
│   └── runtime.py               # ModelRuntime (estado, load, predict_probability)
└── tests/ (conftest + test_{artifact,adapter,runtime,ready,integration}.py)
```

## 6. Ordem obrigatória do carregamento (implementada em `runtime._do_load`)

1. resolver path → 2. confirmar arquivo regular → 3. validar manifest →
4. validar compatibilidade (versões + schema) → 5. calcular SHA-256 →
6. comparar SHA → 7. **só então** `joblib.load` → 8. validar objeto →
9. marcar READY.

O hash é verificado **antes** de qualquer `joblib.load` (nunca depois).

## 7. Segurança

- Joblib carregado só após integridade + compatibilidade aprovadas.
- FAIL-CLOSED: qualquer divergência de versão crítica ou de hash → `ERROR`, sem "warning e continuar".
- Compatibilidade por **igualdade exata** nas libs críticas (`python`, `scikit_learn`, `joblib`, `numpy`, `pandas`, `scipy`).
- `xgboost`/`matplotlib` estão no manifest mas **não** são necessárias para o RF (registradas, fora do fail-closed).
- `/ready` em falha → `503` com o envelope de erro padronizado
  `{"error":{"code":"MODEL_NOT_READY","message":"Modelo de inferência indisponível.","details":[]}}`
  — **sem** caminho absoluto, hash ou mensagem interna.
- Nenhum log de payload DSS (não há log de corpo; o handler de validação descarta `input`).

## 8. Endpoints

| Endpoint | Tipo | Comportamento |
|---|---|---|
| `GET /health` | liveness | Sempre `200` (não depende do modelo). |
| `GET /ready` | readiness | `200` (ready) / `503` (`MODEL_NOT_READY`). |
| `/api/v1/*` | reservado | Nenhum endpoint registrado (FASE 4C). |

OpenAPI: `paths` = `{"/health", "/ready"}` — **nenhum** `/predict`, `/inference`
ou `/predictions`. `APP_DOCS_ENABLED` preservado.

## 9. Testes (37 novos; total 109)

- `test_artifact.py` (11) — SHA-256, path CWD-independente, manifest obrigatório, integridade, compat fail-closed.
- `test_adapter.py` (6) — flatten 48, shape/ordem 1x34, listas como célula, sem features de sensibilidade.
- `test_runtime.py` (7) — estado inicial, predição sem READY, artefato ausente, hash-antes-do-load (monkeypatch), idempotência, metadados, float [0,1].
- `test_ready.py` (8) — 503 com envelope `{"error":{code,message,details}}` (NOT_LOADED e ERROR), sem vazar detalhes, health independente, 200 real, 404 sob `/api/v1`, OpenAPI.
- `test_integration.py` (5) — smoke, determinismo, adapter vs pipeline direto (≤1e-12), hash do artefato, CWD.

**Smoke real:** `GET /health` 200 · `GET /ready` 200 (`random_forest`, 34/96).
**Smoke de falha:** manifest com hash errado → `GET /health` 200 · `GET /ready` 503.

## 10. Integridade & git

| Item | Valor |
|---|---|
| SHA-256 do joblib | `17db2db0c2b87c2a52c46e953162b3f1509a01857b651370ebcc2b4354ce883b` |
| SHA-256 do manifest | `3d11f26655c96141822aa6d12aab74d36492c76638ec1811e7f5c594619d4eb7` |
| `model_file_hash_sha256` (manifest) | `17db2db0…e883b` (bate com o joblib) |
| Hashes expostos no HTTP | ❌ não (somente no relatório/log) |
| `git diff --check` | ✅ limpo |
| `git status --short` | ✅ somente `api/` |
| Commit | ❌ **não realizado** (aguardando revisão) |

---

**Aguardando revisão.**
