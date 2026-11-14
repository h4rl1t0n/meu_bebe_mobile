# FASE 3G-A — Relatório Final de Revisão

**Análise secundária exploratória do comportamento do threshold do Random Forest
selecionado**, usando exclusivamente predições out-of-fold do conjunto de
treinamento (`cv_oof_predictions_v1.csv`, 4000 registros; somente `row_index`,
`y_true` e `random_forest_probability`).

- Data (UTC): 2026-08-23
- Configuração: `threshold_analysis_v1.yaml` (v1.0)
- Modelo analisado: `random_forest` (selecionado na FASE 3F-B)
- Fonte: OOF do TREINAMENTO (4000 registros)
- Nenhum commit foi realizado. Aguardando revisão.

---

## 1. Escopo e caráter da análise

Esta é uma **análise secundária exploratória**. Ela descreve o *trade-off entre
sensibilidade e precisão* das predições out-of-fold do conjunto de treinamento
em vários pontos de corte **exploratórios**, mantendo **0.50** como threshold
primário de referência (o mesmo do protocolo congelado).

Esta análise **não** seleciona um threshold operacional: não há alvo clínico
validado para recall/precisão definido nesta versão, então nenhum ponto de corte
é promovido a *threshold clínico/validado/ideal*.

---

## 2. Pré-condições

| # | Item | Status |
|---|------|--------|
| 1 | `git status --short` limpo (sem alterações de Dart / schema / DGM / Y / IV-DSS / preprocessing / protocolo)? | ✅ SIM |
| 2 | Suíte de testes `pytest` — 338 esperados anteriormente, sem falhas? | ✅ SIM (359 passed) |
| 3 | Artefatos 3F-B existem (`cv_oof_predictions_v1.csv`, `cv_results_v1.json`, `final_test_results_v1.json`, `selected_model_v1_manifest.json`)? | ✅ SIM |
| 4 | `selected_model == random_forest`? | ✅ SIM |
| 5 | Hashes congelados conferem (OOF `1c08fa73…`, split `55eeaf0f…`, folds `7b3cf1ff…`)? | ✅ SIM |

---

## 3. Conformidade com a regra de ouro (anti-leakage)

| # | Item | Status |
|---|------|--------|
| 6 | Usado exclusivamente o OOF do TREINAMENTO (4000 registros)? | ✅ SIM |
| 7 | Apenas `row_index`, `y_true` e `random_forest_probability` lidos do OOF? | ✅ SIM |
| 8 | TEST **não** aberto; `test_predictions_selected_v1.csv` **não** carregado? | ✅ SIM |
| 9 | Nenhum threshold avaliado no TEST; nenhuma decisão usa o TEST? | ✅ SIM |
| 10 | Nenhum retreino / re-CV / regeneração de OOF / tuning / recalibração / SMOTE / alteração de `class_weight` / feature selection / SHAP? | ✅ SIM |

---

## 4. Validação do OOF

| # | Item | Valor |
|---|------|-------|
| 11 | Registros | 4000 (row_index únicos, sem duplicatas) |
| 12 | Cobertura | exatamente o TRAIN congelado; **nenhum índice do TEST** |
| 13 | `y_true` | binário {0,1}; sem ausentes |
| 14 | Prevalência | **y0 = 3023, y1 = 977** (bate com o protocolo) |
| 15 | Probabilidades | finitas e em [0, 1]; min 0.0500, max 0.5380, média 0.2461, desvio 0.0711 |

---

## 5. Grade de thresholds e coerência

| # | Item | Valor |
|---|------|-------|
| 16 | Grade | 46 thresholds: 0.05, 0.06, …, 0.50 (passo 0.01, inclusive) |
| 17 | Thresholds de referência destacados | 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, **0.50** |
| 18 | Coerência do 0.50 | matriz concatenada = soma dos 5 folds = (TN 3021, FP 2, FN 973, TP 4) |
| 19 | Threshold 0.50 no OOF | recall = **0.004094** (reproduz o resultado auditado: recall muito baixo) |

O threshold **0.50** reproduz fielmente o resultado auditado da FASE 3F-B (recall
≈ 0.004, decorrente da compressão das probabilidades do Random Forest em torno
da média 0.246, com raríssimas probabilidades ≥ 0.50).

---

## 6. Métricas nos thresholds de referência (descritivo, OOF TREINAMENTO)

| threshold | recall | precision | f1 | specificity | taxa pred+ |
|-----------|--------|-----------|-----|-------------|-----------|
| 0.10 | 0.9969 | 0.2453 | 0.3938 | 0.0089 | 0.9925 |
| 0.15 | 0.9591 | 0.2511 | 0.3980 | 0.0754 | 0.9330 |
| 0.20 | 0.8240 | 0.2733 | **0.4105** | 0.2921 | 0.7362 |
| 0.25 | 0.5578 | 0.3062 | 0.3954 | 0.5915 | 0.4450 |
| 0.30 | 0.3234 | 0.3595 | 0.3405 | 0.8138 | 0.2198 |
| 0.35 | 0.1494 | 0.4384 | 0.2229 | 0.9381 | 0.0833 |
| 0.40 | 0.0532 | 0.4906 | 0.0960 | 0.9821 | 0.0265 |
| 0.45 | 0.0164 | 0.6154 | 0.0319 | 0.9967 | 0.0065 |
| **0.50** | 0.0041 | 0.6667 | 0.0081 | 0.9993 | 0.0015 |

- **Prevalência de referência (baseline):** 977/4000 = **0.244250**.
- **Maior F1 observado no grid (exploratório):** threshold **0.20**, F1 = 0.410505.
  Este valor é meramente descritivo e **não** constitui seleção de threshold.

---

## 7. Artefatos gerados

| Artefato | Caminho | Nota |
|----------|---------|------|
| Config | `configs/threshold_analysis_v1.yaml` | v1.0, `selection.enabled: false` |
| Módulo | `src/meu_bebe_ml/evaluation/threshold_analysis.py` | funções puras (grid, métricas, resumo) |
| Script principal | `scripts/analyze_oof_thresholds.py` | gera CSV/JSON/figuras, sem TEST |
| Script de inspeção | `scripts/inspect_threshold_analysis.py` | invariantes, somente leitura |
| CSV de métricas | `artifacts/metrics/threshold_metrics_oof_v1.csv` | 46 linhas × 16 colunas |
| JSON de resumo | `artifacts/metrics/threshold_analysis_v1.json` | `selected_new_threshold = null` |
| Figuras (5) | `artifacts/figures/oof_*_v1.png` | recall, precision, f1, trade-off, taxa pred+ |

---

## 8. Testes

| # | Item | Status |
|---|------|--------|
| 20 | 21 novos testes (`tests/test_threshold_analysis.py`) — threshold inválido, prob fora de [0,1], mismatch de tamanho, matriz conhecida, definições de recall/specificity/precision/NPV/F1/balanced accuracy/taxa pred+, grade 46, ordem determinística, referências no intervalo, max-F1 não altera primário, `selected_new_threshold` nulo, guarda anti-TEST, reprodutibilidade sem RNG, monotonicidade | ✅ 21 passed |
| 21 | Suíte completa | ✅ **359 passed** (338 anteriores + 21 novos) |

---

## 9. Confirmações explícitas

- ✅ **Threshold primário permanece 0.50.** Nenhum threshold operacional foi
  selecionado nesta análise.
- ✅ **O resultado do TEST não foi alterado.** A avaliação única da FASE 3F-B
  (accuracy 0.755000, ROC-AUC 0.617424, PR-AUC 0.335621, TP=0 no threshold 0.50)
  permanece inalterada.
- ✅ **Esta análise não substitui a avaliação principal.** É uma análise
  secundária, exploratória e descritiva, baseada exclusivamente em predições
  out-of-fold do treinamento; ela não reavalia o TEST nem redefine o resultado
  oficial.
- ✅ **Nenhum commit foi realizado.**
- ⏸️ **Parado e aguardando revisão.**
