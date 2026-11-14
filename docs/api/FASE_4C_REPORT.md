# FASE 4C — Endpoint HTTP de estimativa probabilística (Relatório)

**Status:** concluído (aguardando revisão) · **Commit:** nenhum (aguardando revisão)
**Testes:** 126 passed (109 anteriores + 17 novos) · **Smoke real:** OK

---

## 0. Objetivo

Expor, via HTTP, a **estimativa probabilística experimental** já calculada pelo
`ModelRuntime` da FASE 4B. A FASE 4C é engenharia HTTP: **não** refita, não
treina nos 5000, não recalibra, não muda threshold, não recalcula TEST, não gera
modelo novo.

## 1. Escopo respeitado (arquitetura congelada)

- **Alterado somente `api/`** (código, testes, README, relatório).
- `ia/` **apenas lido** (sem nenhuma modificação); `lib/` (Flutter) intocado.
- Schema DSS, modelo, manifest, preprocessing, dataset, DGM, Y, threshold,
  métricas e artefatos **não foram tocados**.
- Nenhuma mudança na IA foi necessária → **não houve "PARE E REPORTE"**.

## 2. Estado congelado da IA (mantido exatamente)

DSS schema = 1.13 · Q_full = 48 · X_model = 34 · preprocessing = 96 ·
modelo = Random Forest (`selected_model_v1.joblib`) · `classes_=[0,1]` ·
classe positiva = 1 · modelo fitado **apenas nos 4000 TRAIN**.

## 3. Natureza do endpoint

Estimativa probabilística **experimental** sobre **dados sintéticos** — não é
diagnóstico médico, prognóstico validado, certeza de abandono, decisão
automática, classificação clínica nem recomendação. A limitação aparece no
OpenAPI (descrição), no README e no campo `notice` da resposta.

## 4. Endpoint

`POST /api/v1/risk-estimate` — **sem aliases** (`/predict`, `/prediction`,
`/predictions`, `/inference`, `/estimate`, `/classify`).

## 5. Request body

`DssPayload` **direto** (sem wrapper `{"questionnaire": ...}`; sem
`schema_version`/`user_id`/`request_id`/`threshold` extras no envelope além do
`schema_version` canônico do próprio `DssPayload`). POST (questionário completo;
nunca query params).

## 6. Fluxo

`HTTP POST` → FastAPI → `DssPayload` validado → `get_model_runtime` (app.state)
→ `runtime.predict_probability(payload)` → `float` → response model → 200.
Sem duplicar adapter, sem chamar pipeline/joblib/preprocessing na rota.

## 7. Resposta (200)

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

- `probability`: `float` finito em [0,1], **sem arredondamento**, sem percentual.
- Metadados sanitizados: sem caminho, SHA, timestamp, versões sklearn/joblib,
  `classes_`, índice da classe positiva ou hiperparâmetros.
- **Sem threshold**, sem classe/predicted_class, sem faixa de risco, sem
  recomendação, sem `questionnaire`/features/X_MODEL ecoados (só contagens 34/96).

## 8. Erros

- **503** `MODEL_NOT_READY` (MESMO contrato do `/ready`):
  `{"error":{"code":"MODEL_NOT_READY","message":"Modelo de inferência indisponível.","details":[]}}`.
- **500** `INFERENCE_ERROR` (falha inesperada com runtime READY):
  `{"error":{"code":"INFERENCE_ERROR","message":"Não foi possível calcular a estimativa.","details":[]}}`.
- **422** `VALIDATION_ERROR` (handler da FASE 4A, mantido intacto, formato
  plano): `{"code":"VALIDATION_ERROR","message":"Requisição inválida","details":[...]}`.

503/500 são sanitizados (sem stack trace, exception original ou payload).

## 9. Estrutura criada (somente `api/`)

```
api/src/meu_bebe_api/
├── contracts/risk_estimate.py    # RiskEstimate* + ErrorEnvelope + constantes
├── api/router.py                 # api_v1_router (prefixo /api/v1)
├── api/risk_estimate.py          # POST /risk-estimate
├── main.py                       # + runtime injetável + include api_v1_router
└── contracts/__init__.py         # exporta o novo contrato
api/tests/
├── test_risk_estimate.py         # 14 testes HTTP (fake runtime)
└── test_risk_estimate_integration.py  # 3 testes end-to-end (modelo real)
```

## 10. Runtime (reutilizado, não recriado)

`ModelRuntime` da 4B **não foi modificado**. A rota usa `Depends(get_model_runtime)`
(reusado de `ready.py`) que lê `app.state.model_runtime`. O `create_app` ganhou um
parâmetro opcional `runtime=` para injetar um fake nos testes HTTP — sem quebrar
o lifespan/DI da 4B (sem `ModelRuntime()` por request, sem recarregar joblib).

## 11. Testes (17 novos; total 126)

- `test_risk_estimate.py` (14, fake runtime): 200 fake, float sem arredondamento,
  determinismo, campos proibidos, sem eco de input, 503, 500 sanitizado, 422
  (4 casos) com runtime NÃO chamado, OpenAPI (request/response/aliases), docs disabled.
- `test_risk_estimate_integration.py` (3, modelo real): end-to-end (probability
  HTTP == runtime direto, tolerância 1e-12), determinismo, sem `joblib.load` por request.

**Smoke real:** `GET /health` 200 · `GET /ready` 200 ·
`POST /api/v1/risk-estimate` (fixture sintética) 200.

## 12. Integridade & git

| Item | Valor |
|---|---|
| `selected_model_v1.joblib` alterado | ❌ não (SHA-256 `17db2db0…e883b` preservado) |
| Manifest alterado | ❌ não |
| `git diff --check` | ✅ limpo |
| `git diff -- ia/` | ✅ sem saída |
| `git diff -- lib/` | ✅ sem saída |
| `git status --short` | ✅ somente `api/` |
| TEST ML (`test_predictions_selected_v1.csv`) | ❌ não utilizado |
| Commit | ❌ **não realizado** (aguardando revisão) |

---

**Aguardando revisão.**
