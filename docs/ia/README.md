# Documentação do Pipeline de IA e Machine Learning

Este diretório reúne as especificações metodológicas, planejamento estatístico e documentação técnica do pacote de aprendizado de máquina **Meu Bebê ML** (`meu_bebe_ml`).

---

## 1. Visão Geral do Pipeline

O módulo de IA do projeto Meu Bebê é responsável por:

1. **Geração de Dados Sintéticos (DGM):** Mecanismo gerador de dados fundamentado epidemiologicamente nos Determinantes Sociais da Saúde (DSS), simulando 5.000 registros sintéticos com variáveis latentes $Z_*$, ruído aleatório e probabilidade sigmoide calibrada.
2. **Índice de Vulnerabilidade Social (IV-DSS):** Métrica contínua e normalizada $[0, 1]$ que sintetiza o acúmulo de privações e barreiras sociais enfrentadas pela gestante.
3. **Modelos Preditivos Supervisionados:** Avaliação comparativa sob validação cruzada estratificada de 5 folds entre Regressão Logística, Random Forest e XGBoost.
4. **Modelo Selecionado e Limiar Operacional:** Random Forest selecionado com métrica primária PR-AUC ($0.3023$ no teste vs prevalência base de $0.2440$) e limiar operacional congelado em **$\tau = 0.218$** (otimizado para F1-score balanceando sensibilidade e valor preditivo positivo).
5. **Perfilamento Não Supervisionado (SOM):** Mapas Auto-Organizáveis de Kohonen ($8 \times 8$, topologia hexagonal) combinados a agrupamento hierárquico aglomerativo, consolidando **4 grupos estruturais** de vulnerabilidade com separação nítida em U-Matrix e PCA.

---

## 2. Índice de Documentos

| Documento | Tipo | Descrição |
|---|---|---|
| [planejamento_dataset_sintetico.md](planejamento_dataset_sintetico.md) | **Planejamento Metodológico** | Especificação matemática do DGM: modelagem de variáveis exógenas e endógenas, fatores latentes $Z_{socio}$, $Z_{san}$, $Z_{bio}$, pesos empíricos e injeção controlada de ruído. |

---

## 3. Artefatos e Resultados Consolidados (v1)

Os artefatos produzidos e congelados residem em `ia/artifacts/`:

- **Modelo Congelado:** [selected_model_v1.joblib](../../ia/artifacts/models/selected_model_v1.joblib) (Random Forest validado por hash SHA-256 e consumido em modo somente-leitura pela API).
- **Manifests e Métricas:**
  - `selected_model_v1_manifest.json`: Metadados do modelo, hiperparâmetros, hashes e métricas no teste.
  - `final_test_results_v1.json`: Métricas formais de avaliação no conjunto de teste independente (1.000 exemplos).
  - `som_manifest_v1.json`: Metadados e métricas de qualidade do SOM (Erro de Quantização $0.3444$, Erro Topográfico $0.0038$).
- **Figuras e Gráficos Oficiais (29 figuras regeradas):**
  - `ia/artifacts/figures/`: Curvas ROC, PR, Calibração, Matriz de Confusão, Análise de Limiares OOF, Permutation Importance e Sensibilidade Metodológica.
  - `ia/artifacts/som/figures/`: U-Matrix hexagonal, mapa de clusters, boxplots de IV-DSS e probabilidade por grupo e projeção PCA no holdout.

Para comandos de execução, ativação do ambiente virtual (`ia/.venv`) e reprodução dos experimentos, consulte o arquivo de entrada [ia/README.md](../../ia/README.md).
