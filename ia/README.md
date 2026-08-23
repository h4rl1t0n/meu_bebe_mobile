# Meu Bebê — Componente de IA/ML (`ia/`)

Componente de **inteligência artificial / aprendizado de máquina** do projeto
**Meu Bebê**, desenvolvido como TCC (Bacharelado em Engenharia de Software,
IFAM). O objetivo é **validar tecnicamente o pipeline de ML** que, a partir dos
Determinantes Sociais da Saúde (DSS) coletados de gestantes, estima o risco de
descontinuidade/insuficiência do pré-natal.

> ⚠️ **Dado sintético não representa dado clínico real.** Este projeto usa
> dataset **sintético** apenas para exercitar o pipeline (preprocessamento,
> treinamento, comparação de modelos e inferência) em cenário controlado. Nada
> aqui constitui evidência de prevalência ou de desempenho clínico.

---

## 1. Separação de responsabilidades

O repositório contém três componentes independentes:

| Componente | Diretório | Papel | Status |
| --- | --- | --- | --- |
| **Flutter** (app) | `lib/` | Coleta dos DSS via formulário (contrato 1.13) | implementado |
| **IA/ML** (Python) | `ia/` | Experimento técnico com dataset sintético | **fase 3 — fundação** |
| **API** | `api/` (futuro) | Serviço de inferência | não criado |

Nenhum arquivo Python deve viver dentro de `lib/`; nenhuma alteração de schema
ou de código Dart faz parte do escopo deste componente.

---

## 2. Contrato de dados — Schema DSS 1.13

O contrato é **congelado** (`schema_version = "1.13"`). Fonte de verdade:
`lib/app/modules/formulario/` (Flutter) e `docs/planejamento_dataset_sintetico.md`.

- **chave JSON** — identificador da variável (ex.: `escolaridade`);
- **código canônico** — valor estável em `snake_case` (ex.: `medio_completo`);
- **label** — texto de UI, **fora** do dataset canônico.

Tipos canônicos:

| Tipo | Semântica |
| --- | --- |
| `String?` (categorical) | código; `null` = não respondido / não aplicável |
| `List<String>` (multiselect) | códigos; `[]` = não respondido |
| `bool?` | `true`=Sim, `false`=Não, `null`=não respondido |
| `int` | numérico (Habitação) |

O schema possui **6 dimensões** e **48 variáveis**.

---

## 3. Nomenclatura conceitual

| Nome | Conteúdo | Cardinalidade |
| --- | --- | --- |
| `Q_full` | conjunto completo de variáveis observadas | **48** |
| `X_model` | features ML-IN (modelo principal) | **34** |
| `X_sens` | `X_model` + 2 SENSIBILIDADE (experimento 34 vs 36) | **36** |
| `OUT_LEAKAGE` | proximidade com acompanhamento/desfecho | 5 |
| `OUT_TEMPORAL` | mistura antecedente × acontecimento na gestação | 5 |
| `DESCRIPTIVE` | caracterização | 2 |
| `SENSITIVITY` | comparação de sensibilidade | 2 |
| `Y` | target binário sintético (externo ao formulário) | — |
| `M_sim` | metadados internos da simulação (`Z_*`, `g_*`, `eta`, `p_true`) | — |

`48 = 34 + 5 + 5 + 2 + 2`.

> Estar em ML-IN **não** significa causalidade comprovada; significa apenas
> admissibilidade metodológica.

---

## 4. Separações metodológicas importantes

- **Dado sintético ≠ dado clínico real.** O dataset é gerado por um mecanismo
  probabilístico (DGM) apenas para testar o pipeline; as relações introduzidas
  pelo simulador **não** são evidência epidemiológica.
- **IV-DSS ≠ probabilidade do modelo.** O IV-DSS é um índice **descritivo
  experimental** de vulnerabilidade; **não** é target, **não** gera Y e **não**
  é feature principal do ML. É calculado de forma **independente**.
- **`M_sim` nunca** é entrada do treinamento.

---

## 5. Estrutura do projeto

```text
ia/
├── pyproject.toml
├── README.md
├── .gitignore
├── configs/
│   ├── schema_v1_13.yaml        # contrato de dados 1.13 (espelho fiel)
│   └── simulation_v1.yaml       # config congelada do cenário principal (DGM)
├── src/meu_bebe_ml/
│   ├── schema/                  # constantes, validador e invariantes
│   ├── features/                # seleção determinística de campos
│   ├── simulation/              # (futuro) geração do dataset sintético
│   ├── iv_dss/                  # (futuro) índice descritivo
│   ├── preprocessing/           # (futuro) one-hot/multi-hot, imputação
│   ├── training/                # (futuro) treinamento dos modelos
│   ├── evaluation/              # (futuro) métricas
│   └── utils/                   # (futuro) utilitários
├── tests/                       # pytest (contrato + invariantes + seleção)
├── data/{raw,processed,audit}/  # dados (não versionados)
├── artifacts/{models,metrics,figures}/  # artefatos (não versionados)
└── scripts/                     # scripts de execução
```

---

## 6. Ambiente, instalação e testes

Requer **Python 3.12+**.

```bash
# (recomendado) criar ambiente virtual
python -m venv .venv
# Windows (PowerShell):
.venv\Scripts\Activate.ps1
# Linux/macOS:
source .venv/bin/activate

# instalar dependências (incluindo dev/pytest)
pip install -e ".[dev]"

# executar os testes
pytest
```

Dependências principais: `numpy`, `pandas`, `scipy`, `scikit-learn`, `xgboost`,
`pyyaml`, `joblib`, `matplotlib`. Dev: `pytest`.

> Não fazem parte desta fase: `fastapi`, `uvicorn`, `sqlalchemy` nem
> `tensorflow`.

---

## 7. O que foi feito nesta fase (fundação estrutural)

- Estrutura de diretórios e empacotamento (`src` layout, `pyproject.toml`);
- `configs/schema_v1_13.yaml` — espelho fiel das 48 variáveis;
- `configs/simulation_v1.yaml` — registro congelado do DGM (seed, Z, 10
  coeficientes);
- `schema/constants.py` — `Q_FULL`, `X_MODEL`, `X_SENS` e classes;
- `schema/validator.py` + `schema/invariants.py` — validação de chaves, tipos,
  categorias, obrigatoriedade, condicionalidades e exclusividades;
- `features/selectors.py` — seleção determinística `Q_full → X_model/X_sens`;
- testes `pytest` cobrindo o contrato e as invariantes.

**Não** foram feitos nesta fase (deliberadamente): geração do dataset, treino de
modelos, implementação do DGM/IV-DSS e criação da API.

---

## 8. Notas de transcrição (dúvidas registradas)

1. **`sem_cuidados` (exclusividade):** o catálogo Flutter
   (`CuidadoVetor`) e o controller confirmam que `sem_cuidados` é mutuamente
   exclusivo em `cuidados_vetores`. A lista explícita de exclusividades do
   `docs/planejamento_dataset_sintetico.md` §15 omite esse caso (mas §1.2 o
   lista como resposta de ausência). **Decisão:** a exclusividade foi incluída,
   seguindo o código Flutter (fonte de verdade).

2. **`problema_saude_agua` × `preocupacao_agua`:** o doc e a especificação usam
   a chave JSON `problema_saude_agua`; o `SaneamentoModel` Flutter usa o nome
   interno `preocupacaoAgua` mas **serializa** como `problema_saude_agua`
   (`toMap`). **Não há divergência no contrato de dados** — apenas no nome do
   campo interno Dart. A chave canônica é `problema_saude_agua`.
