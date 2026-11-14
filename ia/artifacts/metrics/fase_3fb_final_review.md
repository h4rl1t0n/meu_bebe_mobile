# FASE 3F-B — Relatório Final de Revisão

**Execução do protocolo congelado da FASE 3F-A** — treinamento, cross-validation,
seleção do modelo e avaliação final no test set.

- Data (UTC): 2026-08-23
- Protocolo de treinamento: `training_protocol_v1.yaml` (v1.0)
- Schema DSS: 1.13
- Preprocessing: v1.0
- Target: `descontinuou_pre_natal`
- Nenhum commit foi realizado. Aguardando revisão.

---

## 1. Conformidade com o protocolo congelado

| # | Item | Status |
|---|------|--------|
| 1 | Hash do dataset confere com o manifest DGM (`36a0e342…`)? | ✅ SIM |
| 2 | Hash do split congelado confere (`55eeaf0f…`)? | ✅ SIM |
| 3 | Hash dos folds congelados confere (`7b3cf1ff…`)? | ✅ SIM |
| 4 | Hash do `preprocessing_v1.yaml` inalterado (`21da57db…`)? | ✅ SIM |
| 5 | Hash do `training_protocol_v1.yaml` inalterado (`0d2c9272…`)? | ✅ SIM |
| 6 | Split usado exatamente 4000/1000 (sem recriar)? | ✅ SIM |
| 7 | TRAIN Y0/Y1 = 3023/977; TEST Y0/Y1 = 756/244? | ✅ SIM |
| 8 | Folds usados exatamente de `cv_folds_v1.csv` (sem `StratifiedKFold`)? | ✅ SIM |
| 9 | Mesmos 5 folds para os 3 modelos? | ✅ SIM |
| 10 | Nenhuma alteração em Dart / schema / DGM / Y / IV-DSS / preprocessing / docs? | ✅ SIM |

## 2. Regras anti-leakage e class imbalance

| # | Item | Status |
|---|------|--------|
| 11 | `scale_pos_weight` do XGBoost calculado só do `y` do fit (folds 3200; final 4000 TRAIN)? | ✅ SIM (folds: 3.092/3.097; final: 3023/977) |
| 12 | `X_raw` contém exatamente as 34 colunas `X_MODEL`? | ✅ SIM |
| 13 | Nenhuma coluna proibida (Z_*/C_*/g_*/IV-DSS/D_*/target/split/fold) entra como feature? | ✅ SIM |
| 14 | TEST não participou de seleção, threshold, features ou calibração? | ✅ SIM |
| 15 | Nenhum SMOTE / oversampling / undersampling / feature selection / tuning? | ✅ SIM |

## 3. Cross-validation (5 folds, threshold 0.50)

| Modelo | mean PR-AUC (±std) | mean Recall (±std) | mean F1 (±std) | mean ROC-AUC (±std) |
|--------|--------------------|--------------------|----------------|---------------------|
| Logistic Regression | 0.336998 (±0.02237) | 0.516907 (±0.03445) | 0.385035 (±0.01543) | 0.608705 (±0.01506) |
| Random Forest | **0.350786 (±0.02536)** | 0.004087 (±0.00427) | 0.008101 (±0.00846) | 0.609831 (±0.01691) |
| XGBoost | 0.334590 (±0.02216) | 0.381821 (±0.02720) | 0.357549 (±0.02260) | 0.605404 (±0.02479) |

## 4. Seleção do modelo

| # | Item | Status |
|---|------|--------|
| 16 | Regra aplicada: 1º mean PR-AUC → 2º mean Recall → 3º mean F1? | ✅ SIM |
| 17 | Houve empate numérico no critério primário? | ✅ NÃO |
| 18 | Modelo selecionado | **Random Forest** (PR-AUC 0.350786 > 0.336998 > 0.334590) |
| 19 | Desempate usado? | Não (sem empate) |
| 20 | Seleção registrada em `cv_results_v1.json` com ranking e razão? | ✅ SIM |

## 5. Avaliação final no TEST (única, modelo selecionado)

| Métrica | Valor |
|---------|-------|
| accuracy | 0.755000 |
| precision | 0.000000 |
| recall | 0.000000 |
| f1 | 0.000000 |
| TN / FP / FN / TP | 755 / 1 / 244 / 0 |
| ROC-AUC | 0.617424 |
| PR-AUC | 0.335621 |
| average_precision (diagnóstico) | 0.337899 |
| Brier score | 0.178717 |

| # | Item | Status |
|---|------|--------|
| 21 | TEST avaliado uma única vez, só do modelo selecionado? | ✅ SIM |
| 22 | Threshold mantido em 0.50 (sem recalibração/ajuste)? | ✅ SIM |

## 6. Artefatos de reprodutibilidade

| Artefato | Caminho | Hash/nota |
|----------|---------|-----------|
| Modelo serializado | `artifacts/models/selected_model_v1.joblib` | `17db2db0…` (RandomForestClassifier, 96 features) |
| Manifest do modelo | `artifacts/models/selected_model_v1_manifest.json` | fit apenas nos 4000 TRAIN |
| Relatório CV | `artifacts/metrics/cv_results_v1.json` | 3 modelos × 5 folds |
| Relatório TEST | `artifacts/metrics/final_test_results_v1.json` | métricas + calibração |
| OOF predictions | `data/processed/cv_oof_predictions_v1.csv` | 4000 linhas |
| Predições TEST | `data/processed/test_predictions_selected_v1.csv` | 1000 linhas |
| Figuras | `artifacts/figures/*_v1.png` | ROC / PR / confusão / calibração |

## 7. Testes

| # | Item | Status |
|---|------|--------|
| 23 | Suíte de testes completa (pytest) | ✅ **335 passed** (315 anteriores + 20 novos) |
| 24 | Novos testes cobrem split/folds/agregação/seleção/OOF/serialização? | ✅ SIM |
| 25 | Inspeção `inspect_training_results.py` (todos os invariantes OK)? | ✅ SIM |

## 8. Observações e limitações

- O **Random Forest foi selecionado pela PR-AUC** (métrica threshold-independente),
  mas com `class_weight="balanced_subsample"` suas probabilidades preditas raramente
  ultrapassam 0.50 — logo, no threshold congelado de 0.50, o recall é ≈ 0 (TP=0 no TEST).
  Este é um resultado **legítimo e fiel ao protocolo congelado**, não um erro a corrigir:
  a seleção usa PR-AUC justamente por ser invariante ao threshold. A baixa calibração
  das probabilidades do RF (Brier 0.179) explica a divergência entre ranking (PR-AUC/ROC-AUC)
  e a decisão binária em 0.50.
- A interpretação correta é: **nenhum dos três modelos demonstra poder preditivo forte**
  (ROC-AUC ≈ 0.61 no TEST, pouco acima de 0.50). O protocolo foi executado sem nenhuma
  tentativa de melhora artificial.

## 9. Conclusão

- ✅ Protocolo congelado executado integralmente, sem alterações pós-observação.
- ✅ Modelo selecionado: **Random Forest** (mean PR-AUC = 0.350786).
- ✅ Avaliação única no TEST concluída e registrada.
- ✅ Todos os artefatos de reprodutibilidade gerados.
- ✅ Nenhum commit realizado.
- ⏸️ **Parado e aguardando revisão.**
