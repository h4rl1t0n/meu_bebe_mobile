# Meu Bebê — Componente de IA/ML (`ia/`)

> 💡 **Documentação Metodológica Central:** Para a formulação matemática do DGM, especificação de variáveis e catálogo de experimentos, consulte [`docs/ia/`](../docs/ia/README.md).

Componente de **inteligência artificial / aprendizado de máquina** do projeto **Meu Bebê**, desenvolvido no âmbito do Trabalho de Conclusão de Curso (Bacharelado em Engenharia de Software, IFAM).

O módulo implementa o pipeline analítico e experimental completo que, a partir dos **Determinantes Sociais da Saúde (DSS)** coletados de gestantes, calcula índices de vulnerabilidade, estima a propensão à descontinuidade do acompanhamento pré-natal e realiza agrupamento não supervisionado via mapas auto-organizáveis (SOM).

> ⚠️ **Metodologia e Dados Sintéticos:** O projeto utiliza um gerador de dados
> sintéticos baseado em mecanismos probabilísticos (DGM) concebido para validar
> formalmente o pipeline de engenharia de software e ciência de dados
> (pré-processamento, calibração, treinamento, inferência e clusterização).
> Os dados **não** representam dados clínicos reais nem prevalências populacionais.
> A estimativa do modelo é uma **probabilidade experimental**, não constituindo
> diagnóstico clínico ou certeza de abandono. Consulte [`docs/tcc2.md`](../docs/tcc2.md).

---

## 1. Organização e Responsabilidades

| Componente | Diretório | Função | Status |
| --- | --- | --- | --- |
| **Flutter App** | `lib/` | Coleta dos DSS via formulário e interface de acompanhamento | Concluído |
| **Backend API** | `api/` | Serviço de inferência stateless e persistência relacional | Concluído |
| **IA / ML** | `ia/` | Geração DGM, cálculo do IV-DSS, treinamento, calibração e SOM | Concluído |

O componente `ia/` é empacotado como a biblioteca Python `meu_bebe_ml`. Nenhuma dependência de interface gráfica ou web reside neste pacote.

---

## 2. Contrato de Dados — Schema DSS 1.13

O contrato de dados é **estritamente congelado** (`schema_version = "1.13"`). Sua definição normativa está em `configs/schema_v1_13.yaml` e nos modelos do aplicativo móvel:

- **6 Dimensões de DSS:** Educação, Trabalho e Renda, Saneamento, Acesso a Serviços de Saúde, Habitação e Alimentação.
- **48 Variáveis observadas ($Q_{full}$):**
  - **34 Features ML-IN ($X_{model}$):** Variáveis admitidas no modelo principal de inferência.
  - **2 Features de Sensibilidade ($X_{sens}$):** Usadas em experimentos de sensibilidade metodológica ($34 \times 36$).
  - **5 Variáveis de Risco de Leakage:** Relacionadas à proximidade do desfecho/frequência de consultas (excluídas do modelo para evitar vazamento).
  - **5 Variáveis de Risco Temporal:** Misturam antecedentes com acontecimentos durante a gestação (excluídas do modelo basal).
  - **2 Variáveis Descritivas:** Caracterização geral.

---

## 3. Módulos do Pacote `meu_bebe_ml`

```text
ia/src/meu_bebe_ml/
├── schema/          # Definição de constantes, invariantes de domínio e validação de schema
├── features/        # Seleção determinística de campos (Q_full -> X_model) e prevenção de leakage
├── simulation/      # Mecanismo Gerador de Dados (DGM) com variáveis latentes Z_* e target sintético Y
├── iv_dss/          # Cálculo determinístico do Índice de Vulnerabilidade Social (escala [0, 1])
├── preprocessing/   # Pipelines de transformação de features categóricas/multiselect (34 -> 96 colunas)
├── training/        # Protocolo de treino, validação cruzada estratificada (5-folds) e hiperparametrização
├── evaluation/      # Métricas de avaliação (PR-AUC, ROC-AUC, Brier score), calibração e SHAP
├── som/             # Mapas Auto-Organizáveis de Kohonen (SOM), cálculo de U-Matrix e PCA
└── utils/           # Serialização, hash criptográfico e utilitários auxiliares
```

---

## 4. Pipeline Analítico e Experimental

### 4.1 Geração de Dados Sintéticos (DGM)
- Gera $N = 5.000$ amostras reproduzíveis (`seed=42`).
- Aplica um modelo de variáveis latentes $Z_*$ para introduzir correlações realistas entre dimensões sociais.
- Define o desfecho sintético $Y \in \{0, 1\}$ (descontinuidade) por processo logístico Bernoulli com taxa de evento aproximada em ~25%.

### 4.2 Índice de Vulnerabilidade Social (IV-DSS)
- Índice descritivo calculado de forma puramente aritmética e transparente (pesos homogêneos $1/6$ por dimensão).
- Produz escore contínuo em $[0, 1]$ indicando o nível de carência ou vulnerabilidade social.
- **Princípio:** O IV-DSS **não** é o target, **não** gera $Y$ e **não** é uma feature do modelo de ML, servindo como métrica comparativa independente.

### 4.3 Treinamento e Seleção de Modelos
- Protocolo sob **Validação Cruzada Estratificada em 5 Folds** e Holdout de Teste ($N=1.000$).
- Modelos comparados:
  1. **Regressão Logística** (L2 penalizada) — Baseline linear;
  2. **Random Forest** — Modelo baseado em comitê de árvores;
  3. **XGBoost** — Gradient boosted trees.
- **Critério de Seleção:** O modelo **Random Forest** foi selecionado pelo critério formal de maior **PR-AUC média** na validação cruzada, apresentando excelente calibração e estabilidade.
- O artefato final é congelado e serializado com verificação de integridade SHA-256 em `ia/artifacts/models/selected_model_v1.joblib`.

### 4.4 Agrupamento Não Supervisionado via SOM
- Implementação de **Self-Organizing Maps (Kohonen)** sobre as 34 variáveis normalizadas.
- Identificação de clusters naturais de gestantes com diferentes perfis de vulnerabilidade.
- Produção de mapas de ativação, **U-Matrix**, projeção 2D por PCA e análise cruzada: correlação entre os grupos do SOM, o índice IV-DSS e a propensão predita pelo Random Forest.

---

## 5. Scripts de Execução (`ia/scripts/`)

Os scripts executáveis permitem reproduzir do zero todos os experimentos e artefatos:

| Script | Função |
| --- | --- |
| `generate_q_full.py` | Gera o dataset de questionários sintéticos ($Q_{full}$, $N=5.000$) |
| `generate_target.py` | Gera o desfecho sintético de descontinuidade $Y$ via DGM |
| `generate_iv_dss.py` | Calcula os escores de vulnerabilidade IV-DSS para o dataset |
| `prepare_training_protocol.py` | Prepara os splits de treino/teste e folds estratificados |
| `run_training_experiment.py` | Executa o treinamento comparativo (LR, RF, XGB) e salva o modelo vencedor |
| `run_som_analysis.py` | Executa o agrupamento não supervisionado via SOM e gera figuras |
| `run_interpretability_analysis.py` | Extrai valores de importância de features e SHAP values |
| `run_methodological_sensitivity.py`| Executa a análise de sensibilidade metodológica ($X_{model}$ vs $X_{sens}$) |
| `analyze_oof_calibration.py` | Analisa a calibração de probabilidades out-of-fold e curva de confiabilidade |

---

## 6. Instalação e Testes

Requer **Python 3.12+** (mesmo ambiente utilizado na API).

```powershell
cd ia

# 1. Ativar ambiente virtual (ou utilizar o venv compartilhado)
py -3.14 -m venv .venv
.\.venv\Scripts\Activate.ps1

# 2. Instalar dependências em modo editável com ferramentas de desenvolvimento
pip install -e ".[dev]"

# 3. Executar testes automatizados (testes de schema, invariantes, DGM, IV-DSS e pipelines)
pytest
```

---

## 7. Integração com o Backend (`api/`)

O artefato congelado do modelo e seu respectivo manifesto residem em:
- Modelo: `ia/artifacts/models/selected_model_v1.joblib`
- Manifest: `ia/artifacts/models/selected_model_v1_manifest.json`

O backend `api/` importa `meu_bebe_ml` como dependência e carrega o arquivo `.joblib` em modo seguro fail-closed no endpoint `/ready`, disponibilizando a inferência no endpoint `POST /api/v1/risk-estimate`.
