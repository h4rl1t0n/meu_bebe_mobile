# FASE 4D — Consolidação, compatibilidade Flutter ↔ API e congelamento do contrato HTTP (Relatório)

**Status:** concluído (aguardando revisão) · **Commit:** nenhum (aguardando revisão)
**Testes:** 150 passed (126 anteriores + 24 novos) · **Smoke real:** OK
**Smoke real (fixture canônica):** `POST /api/v1/risk-estimate` → `200` · `probability = 0.238`

---

## 0. Objetivo

Auditar (somente leitura) o Flutter contra a API, **testar**, **documentar** e
**congelar** o contrato HTTP que o Flutter consumirá na próxima fase (via
`Dio`). A FASE 4D **não** implementa cliente Flutter, autenticação, banco,
CORS, rate limiting, Docker, deployment, threshold, classificação ou
explicabilidade individual.

## 1. Escopo respeitado (arquitetura congelada)

- **Alterado somente `api/`** (fixture, testes, `API_CONTRACT_V1.md`, este
  relatório). `lib/` e `ia/` **apenas lidos**.
- Nenhuma alteração em: `lib/`, `ia/`, modelo, manifest, schema DSS,
  preprocessing, dataset, DGM, Y, Flutter, `pubspec.yaml`.
- **Nenhuma divergência Flutter ↔ API foi encontrada** → **não houve
  "PARE E REPORTE"**.

## 2. Auditoria Flutter → API (somente leitura) — resultado

Lidos (read-only): `formulario_data.dart`, `dss_schema.dart`,
`formulario_controller.dart`, os 6 modelos de dimensão
(`educacao_model.dart`, `trabalho_model.dart`, `saneamento_model.dart`,
`saude_model.dart`, `habitacao_model.dart`, `alimentacao_model.dart`) e os
testes Flutter `test/formulario/models/*_test.dart` +
`formulario_data_test.dart`.

Constatado (sem divergência):

- `FormularioData.toMap()` produz o payload **aninhado + versionado** com
  `schema_version='1.13'` no topo e as 6 dimensões — idêntico ao `DssPayload`.
- `toFlatMap()` é a visão **interna** `dimensao.campo` (sem `schema_version`)
  — **não** é o contrato HTTP. O Flutter já documenta/testa isso.
- Chaves JSON (snake_case) dos 6 `toMap()` coincidem 1:1 com os `model_fields`
  da API. Contagens: **6 / 10 / 7 / 9 / 9 / 7 = 48**.
- `DssSchema.schemaVersion = '1.13'` (Flutter) == `DSS_SCHEMA_VERSION = '1.13'`
  (API).
- Nulabilidade coincide: booleanos `bool?`, categóricos `String?`,
  multiseleção `List<String>` (default `[]`), `beneficios_trabalho` é o único
  null estrutural (`List<String>?`).
- Testes Flutter existentes confirmam: consolidação aninhada das 6 dimensões,
  `toFlatMap` sem `schema_version`, e round-trip `fromMap/toMap`.

## 3. Entregáveis produzidos (somente `api/`)

```
api/
├── tests/fixtures/flutter_dss_payload_v1_13.json   # fixture canônica
├── tests/test_flutter_contract.py                  # 10 testes (fixture)
├── tests/test_http_contract.py                     # 14 testes (transporte)
├── API_CONTRACT_V1.md                              # contrato formal congelado
└── FASE_4D_REPORT.md                               # este relatório
```

## 4. Fixture canônica

`tests/fixtures/flutter_dss_payload_v1_13.json` é a **fonte de verdade** do
payload que o Flutter envia: 48 variáveis em 6 dimensões + `schema_version`,
todos os códigos canônicos snake_case, nulls estruturais corretos. Distinta do
payload do `conftest.py` (probabilidade real diferente: `0.238` vs `0.222`),
provando que a fixture é genuinamente validada — não copiada.

## 5. Testes novos (24; total 150)

### `test_flutter_contract.py` (10)

- Fixture válida como `DssPayload` (schema 1.13).
- Exatamente 6 dimensões + contagem 6/10/7/9/9/7 + total 48.
- Nomes de campo idênticos aos `model_fields` por dimensão.
- Ausência de chaves flat (`.`) no topo.
- Round-trip Pydantic (dump == fixture) e round-trip na forma Flutter.
- Fixture sobre HTTP (fake runtime) → 200 com contrato exato.
- **Fixture sobre o modelo REAL** → probability HTTP == runtime direto
  (tolerância `1e-12`).

### `test_http_contract.py` (14)

- Content-Type `application/json` em **200 / 422 / 500 / 503**.
- Método: `GET`/`PUT`/`DELETE` → `405` (runtime **não** chamado).
- Corpo ausente → `422`; JSON malformado → `422` (runtime **não** chamado).
- Estatelessness: dois requests independentes repassados intactos.
- **Matriz consolidada** 200 / 422 (plano) / 500 (envelope) / 503 (envelope)
  com corpos exatos e sanitização do 500.

## 6. Matriz de respostas (congelada)

| Situação | Status | Formato |
|---|---|---|
| payload válido + modelo READY | `200` | `{result, model, notice}` |
| payload inválido / ausente / malformado | `422` | **plano** `{code, message, details}` |
| modelo não carregado | `503` | **envelope** `{error:{code, message, details}}` |
| falha inesperada de inferência | `500` | **envelope** `{error:{code, message, details}}` |

> A diferença deliberada entre o `422` (plano) e `500`/`503` (envelope) foi
> **mantida** e documentada — não uniformizada.

## 7. Documentação do contrato

`API_CONTRACT_V1.md` formaliza: paths, método, content-type, request
(`DssPayload` direto), as 6 dimensões (tabela completa dos 48 campos com
tipos), respostas 200/422/500/503, `/health`, `/ready`, semântica da
`probability` (float `[0,1]`, sem threshold/classe), limitações (dados
sintéticos, não-diagnóstico, sem persistência, privacidade), matriz HTTP e
**guia futuro para o Flutter/Dio** (sem base URL, sem CORS, sem auth; usar
`toMap()`, nunca `toFlatMap()`).

## 8. OpenAPI (consolidação)

- Paths exatos: `["/health", "/ready", "/api/v1/risk-estimate"]`.
- Request body = `DssPayload` (direto, sem wrapper).
- Responses documentadas: `200` (`RiskEstimateResponse`), `422`
  (`ErrorResponse` plano), `500`/`503` (`ErrorEnvelope`).
- Sem aliases (`/predict`, `/inference`, `/classify`, etc.).
- Docs `/docs`/`/redoc`/`/openapi.json` somente com `APP_DOCS_ENABLED=true`.

## 9. Integridade & git

| Item | Valor |
|---|---|
| `git diff --check` | ✅ limpo |
| `git diff -- ia/` | ✅ sem saída |
| `git diff -- lib/` | ✅ sem saída |
| `git status --short` | ✅ somente `api/` (4 arquivos novos, nenhum modificado) |
| `selected_model_v1.joblib` alterado | ❌ não |
| Manifest / schema DSS / dataset alterados | ❌ não |
| TEST ML (`test_predictions_selected_v1.csv`) lido | ❌ não |
| `compileall` | ✅ OK |
| `pip check` | ✅ "No broken requirements found." |
| Commit | ❌ **não realizado** (aguardando revisão) |

## 10. Estado congelado mantido

DSS schema = 1.13 · Q_full = 48 · X_model = 34 · preprocessing = 96 ·
Random Forest (`selected_model_v1.joblib`) · `classes_=[0,1]` · classe
positiva = 1 · modelo fitado apenas nos 4000 TRAIN · **sem** threshold
operacional · API_VERSION = `0.1.0`.

---

**Aguardando revisão. Nenhum commit foi realizado.**
