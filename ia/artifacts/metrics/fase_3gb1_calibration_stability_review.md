# FASE 3G-B1 — Relatório Final de Revisão

**Análise secundária diagnóstica de calibração e estabilidade das
probabilidades out-of-fold do Random Forest selecionado**, usando exclusivamente
as predições out-of-fold do conjunto de treinamento
(`cv_oof_predictions_v1.csv`, 4000 registros; somente `row_index`,
`validation_fold`, `y_true` e `random_forest_probability`).

- Data (UTC): 2026-08-23
- Configuração: `calibration_stability_v1.yaml` (v1.0)
- Modelo analisado: `random_forest` (selecionado na FASE 3F-B)
- Fonte: OOF do TREINAMENTO (4000 registros)
- Nenhum commit foi realizado. Aguardando revisão.

---

## 1. Escopo e caráter da análise

Esta é uma análise **exclusivamente diagnóstica e descritiva**. Ela caracteriza
a **calibração no cenário sintético experimental** e a **estabilidade entre
folds** das probabilidades out-of-fold do Random Forest. É um **diagnóstico de
calibração no cenário sintético experimental**, e não um modelo clinicamente
calibrado.

Esta análise **não** recalibra o modelo (sem Platt, isotonic ou
`CalibratedClassifierCV`), **não** seleciona threshold, **não** usa o TEST e
**não** modifica o modelo selecionado. O experimento principal das FASEs
3F-A / 3F-B e a FASE 3G-A permanecem congelados.

---

## 2. Pré-condições

| # | Item | Status |
|---|------|--------|
| 1 | `git status --short` limpo (sem alterações de Dart / schema / DGM / Y / IV-DSS / preprocessing / protocolo)? | ✅ SIM |
| 2 | Suíte de testes `pytest` — 359 esperados anteriormente, sem falhas? | ✅ SIM (382 passed) |
| 3 | Artefatos 3F-B existem (`cv_oof_predictions_v1.csv`, `cv_folds_v1.csv`, `selected_model_v1_manifest.json`)? | ✅ SIM |
| 4 | `selected_model == random_forest`? | ✅ SIM |
| 5 | Hashes congelados conferem (OOF `1c08fa73…`, split `55eeaf0f…`, folds `7b3cf1ff…`)? | ✅ SIM |

---

## 3. Conformidade com a regra de ouro (anti-leakage)

| # | Item | Status |
|---|------|--------|
| 6 | Usado exclusivamente o OOF do TREINAMENTO (4000 registros)? | ✅ SIM |
| 7 | Lidos do OOF apenas `row_index`, `validation_fold`, `y_true` e `random_forest_probability`? | ✅ SIM |
| 8 | TEST **não** aberto; `test_predictions_selected_v1.csv` **não** carregado? | ✅ SIM |
| 9 | `final_test_results_v1.json` **não** usado para cálculos? | ✅ SIM |
| 10 | Nenhuma recalibração / retreino / re-CV / regeneração de OOF / tuning / SMOTE / alteração de `class_weight` / ajuste de threshold / feature selection / SHAP / API? | ✅ SIM |

---

## 4. Validação do OOF

| # | Item | Valor |
|---|------|-------|
| 11 | Registros | 4000 (row_index únicos, sem duplicatas) |
| 12 | Cobertura | exatamente o TRAIN congelado; **nenhum índice do TEST** |
| 13 | `validation_fold` | exatamente {0, 1, 2, 3, 4} |
| 14 | `y_true` | binário {0,1}; sem ausentes |
| 15 | Prevalência | **y0 = 3023, y1 = 977** (bate com o protocolo) |

---

## 5. Probabilidades e calibração global "in the large"

| # | Item | Valor |
|---|------|-------|
| 16 | Probabilidades OOF | finitas em [0, 1]; min 0.0500, max 0.5380, média 0.246070, desvio 0.071093 |
| 17 | Média prevista | 0.246070 |
| 18 | Taxa observada de positivos | 0.244250 |
| 19 | Diferença de calibração "in the large" | **+0.001820** (leve sobreprevisão global, ≈ 0.18 p.p.) |

---

## 6. Brier e ganho sobre o baseline

| # | Item | Valor |
|---|------|-------|
| 20 | Brier do modelo | 0.178872 |
| 21 | Brier do baseline (prevalência constante) | 0.184592 |
| 22 | Diferença (modelo − baseline) | −0.005720 |
| 23 | Melhoria relativa | **+3.0985 %** (positiva = melhor que o baseline) |

---

## 7. Discriminação OOF — média dos folds × pooled OOF

A AUC calculada sobre todas as predições OOF concatenadas não precisa coincidir
com a média aritmética das AUCs calculadas separadamente nos cinco folds. Ambas
são reportadas para transparência, mas possuem papéis distintos.

| # | Item | Valor |
|---|------|-------|
| 24 | mean_fold_roc_auc (média dos 5 folds) | **0.609831** |
| 25 | mean_fold_pr_auc (média dos 5 folds) | **0.350786** ← métrica canônica da seleção (FASE 3F-B) |
| 26 | pooled_oof_roc_auc (4000 concatenados) | 0.609684 |
| 27 | pooled_oof_pr_auc (4000 concatenados) | 0.344891 |

A seleção original do Random Forest na FASE 3F-B permanece baseada em
**mean_fold_pr_auc = 0.350786**. Os valores pooled OOF são reportados apenas
para transparência e **não** substituem o resultado histórico.

---

## 8. Diagrama de confiabilidade global (10 bins quantile)

Gap de calibração = fração de positivos − média prevista (positivo = subprevisão).

| bin | n | média prevista | fração de positivos | gap |
|-----|---|----------------|---------------------|-----|
| 0 | 409 | 0.1358 | 0.1638 | +0.0280 |
| 1 | 404 | 0.1753 | 0.1584 | −0.0169 |
| 2 | 404 | 0.1966 | 0.1782 | −0.0183 |
| 3 | 415 | 0.2142 | 0.2217 | +0.0074 |
| 4 | 391 | 0.2305 | 0.2251 | −0.0054 |
| 5 | 392 | 0.2491 | 0.2398 | −0.0093 |
| 6 | 387 | 0.2690 | 0.2481 | −0.0209 |
| 7 | 421 | 0.2922 | 0.2827 | −0.0095 |
| 8 | 392 | 0.3228 | 0.3163 | −0.0064 |
| 9 | 385 | 0.3850 | 0.4182 | +0.0332 |

- **mean absolute bin gap** = 0.015538; **weighted mean absolute bin gap** = 0.015478.
- **maior gap observado** ≈ 0.033 (bin 9), onde a probabilidade média é ~0.385 e
  a fração de positivos é ~0.418. As probabilidades cobrem a faixa 0.05–0.54.
  Não há cutoffs de calibração validados nesta versão; os valores são reportados
  de forma quantitativa.

---

## 9. Diagnóstico por fold (5 bins quantile por fold)

| fold | n | prevalência | média p | Brier | Brier baseline | ROC-AUC | PR-AUC | diff in-the-large |
|------|---|-------------|---------|-------|----------------|---------|--------|-------------------|
| 0 | 800 | 0.2437 | 0.2458 | 0.1765 | 0.1843 | 0.6273 | 0.3900 | +0.0020 |
| 1 | 800 | 0.2437 | 0.2438 | 0.1795 | 0.1843 | 0.6066 | 0.3277 | +0.0001 |
| 2 | 800 | 0.2437 | 0.2473 | 0.1803 | 0.1843 | 0.5851 | 0.3407 | +0.0036 |
| 3 | 800 | 0.2450 | 0.2452 | 0.1778 | 0.1850 | 0.6241 | 0.3615 | +0.0002 |
| 4 | 800 | 0.2450 | 0.2482 | 0.1802 | 0.1850 | 0.6060 | 0.3340 | +0.0032 |

- O baseline Brier de cada fold usa a **prevalência da training portion**
  (os outros 4 folds): 0.244375 para os folds 0–2 e 0.2440625 para os folds 3–4.

---

## 10. Estabilidade entre folds

| métrica | média | desvio | min | max | range |
|---------|-------|--------|-----|-----|-------|
| Brier | 0.178872 | 0.001659 | 0.176545 | 0.180348 | 0.003803 |
| ROC-AUC | 0.609831 | 0.016912 | 0.585145 | 0.627311 | 0.042166 |
| PR-AUC | 0.350786 | 0.025356 | 0.327662 | 0.390024 | 0.062362 |
| média da probabilidade | 0.246070 | 0.001726 | 0.243815 | 0.248187 | 0.004372 |
| taxa observada de positivos | 0.244250 | 0.000685 | 0.243750 | 0.245000 | 0.001250 |
| diff in-the-large | 0.001820 | 0.001624 | 0.000065 | 0.003575 | 0.003510 |

- O **Brier** apresentou range observado de aproximadamente 0.0038 entre os
  cinco folds.
- A **ROC-AUC** apresentou range observado de aproximadamente 0.042 (0.585–0.627).
- A **PR-AUC** apresentou range observado de aproximadamente 0.062 (0.328–0.390),
  com prevalência de 24.4 %.

---

## 11. Distribuição das probabilidades por classe

| classe | n | média p | desvio p | mediana | q05 | q95 |
|--------|---|---------|----------|---------|-----|-----|
| y_true=0 | 3023 | 0.238941 | 0.067664 | 0.232 | 0.136 | 0.356 |
| y_true=1 | 977 | 0.268129 | 0.076734 | 0.262 | 0.152 | 0.406 |

- As probabilidades das duas classes se sobrepõem, mas o centro da classe
  positiva (média 0.268) está deslocado acima da classe negativa (média 0.239),
  coerente com mean_fold_roc_auc ≈ 0.61.

---

## 12. Artefatos gerados

| Artefato | Caminho | Nota |
|----------|---------|------|
| Config | `configs/calibration_stability_v1.yaml` | v1.0, `recalibration.enabled: false`, `test_usage.allowed: false` |
| Módulo | `src/meu_bebe_ml/evaluation/calibration_stability.py` | funções puras (bins, Brier, folds, estabilidade, resumo) |
| Script principal | `scripts/analyze_oof_calibration.py` | gera CSV/JSON/5 figuras, sem TEST |
| Script de inspeção | `scripts/inspect_calibration_stability.py` | invariantes, somente leitura |
| CSV de bins | `artifacts/metrics/oof_calibration_bins_v1.csv` | 35 linhas (10 global + 25 fold) |
| JSON de resumo | `artifacts/metrics/calibration_stability_v1.json` | flags `recalibration_performed/test_used/model_modified = false` |
| Figuras (5) | `artifacts/figures/oof_calibration_*_v1.png`, `oof_brier_by_fold_v1.png`, `oof_probability_*_v1.png` | diagrama global, por fold, Brier, distribuição por classe, probabilidade por fold |

---

## 13. Testes

| # | Item | Status |
|---|------|--------|
| 28 | 23 novos testes (`tests/test_calibration_stability.py`) — prob inválida, NaN, tamanhos divergentes, classe única (ROC-AUC indefinido/NaN), Brier e baseline conhecidos, gap de calibração, mean/weighted mean abs bin gap, resumos por classe e por fold, `validate_folds_present`, fold desconhecido, `training_prevalence` usa só a training portion, estabilidade, determinismo, guarda anti-TEST, consistência com ~0.609831/~0.350786 | ✅ 23 passed |
| 29 | Suíte completa | ✅ **382 passed** (359 anteriores + 23 novos) |
| 30 | Inspeção (`inspect_calibration_stability.py`) | ✅ todos os invariantes OK |

---

## 14. Confirmações explícitas

- ✅ **Nenhuma recalibração foi realizada.** `recalibration_performed = false`.
  Não há Platt, isotonic nem `CalibratedClassifierCV`; nenhum modelo recalibrado
  foi gerado.
- ✅ **O TEST não foi usado.** `test_used = false`; `test_predictions_selected_v1.csv`
  e `final_test_results_v1.json` não foram abertos para cálculos.
- ✅ **O modelo selecionado permanece inalterado.** `model_modified = false`;
  `selected_model_v1.joblib` tem hash idêntico ao manifest
  (`17db2db0…48ce883b`).
- ✅ **O threshold primário permanece 0.50.** Nenhum threshold foi selecionado.
- ✅ **Os resultados oficiais da FASE 3F-B não foram alterados** (accuracy
  0.755000, ROC-AUC 0.617424, PR-AUC 0.335621 no TEST).
- ✅ **Os resultados da FASE 3G-A permanecem congelados e inalterados.**
- ✅ **Linguagem adotada:** "diagnóstico de calibração no cenário sintético
  experimental" — nunca "modelo clinicamente calibrado" nem "probabilidade real".
- ✅ **Nenhum valor analítico foi modificado.** Continuam exatamente iguais:
  N = 4000; Y0 = 3023; Y1 = 977; mean probability = 0.246070;
  observed rate = 0.244250; Brier RF = 0.178872; Brier baseline = 0.184592;
  mean abs bin gap = 0.015538; weighted mean abs bin gap = 0.015478;
  pooled_oof_roc_auc ≈ 0.609684; pooled_oof_pr_auc ≈ 0.344891;
  mean_fold_roc_auc ≈ 0.609831; mean_fold_pr_auc ≈ 0.350786;
  recalibration_performed = false; test_used = false; model_modified = false.
- ✅ **Nenhum commit foi realizado.**
- ⏸️ **Parado e aguardando revisão.**
