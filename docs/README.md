# Guia Central de Documentação — Projeto Meu Bebê

Este diretório reúne toda a documentação técnica, acadêmica, arquitetural e relatórios de auditoria do ecossistema **Meu Bebê**, estruturada e organizada por projetos e componentes da solução.

O projeto é composto por três frentes de engenharia e uma frente acadêmica:
1. **[Aplicativo Mobile (Flutter)](app/README.md):** Interface da gestante para acompanhamento do pré-natal e preenchimento dos Determinantes Sociais da Saúde (DSS).
2. **[Backend REST (FastAPI)](api/README.md):** Serviços de autenticação JWT, persistência relacional do pré-natal no PostgreSQL e inferência probabilística DSS.
3. **[Pipeline de IA e Machine Learning (Python)](ia/README.md):** Geração do dataset sintético (DGM), cálculo do IV-DSS, treinamento de modelos e agrupamento não supervisionado via SOM.
4. **[Documentação Acadêmica (TCC2)](tcc/README.md):** Monografia completa, capítulos expandidos, matriz bibliográfica, planos ABNT e slides de defesa.

---

## Estrutura da Pasta de Documentação

```
docs/
├── README.md                      # Este hub de navegação central
│
├── app/                           # PROJETO 1: APLICATIVO MOBILE (FLUTTER)
│   ├── README.md                  # Visão geral da arquitetura mobile
│   ├── FLUTTER_API_INTEGRATION.md # Integração Dio, repositórios, interceptors e mappers
│   ├── FASE_5A_REPORT.md          # Fundação da integração HTTP Dio e modelos
│   ├── FASE_5B_REPORT.md          # Conexão do formulário DSS à chamada de API
│   ├── FASE_5C_REPORT.md          # Apresentação visual da estimativa probabilística
│   ├── FASE_5D_REPORT.md          # Validação real ponta a ponta (E2E)
│   └── FASE_6A_REPORT.md          # Auditoria do módulo pré-natal e domínio
│
├── api/                           # PROJETO 2: BACKEND REST (FASTAPI)
│   ├── README.md                  # Manual da API, endpoints, banco e segurança
│   ├── API_CONTRACT_V1.md         # Contrato HTTP v1 formal e congelado (DSS)
│   ├── PRENATAL_API_ARCHITECTURE_PLAN.md # Arquitetura da API do pré-natal (Fase 8A)
│   ├── PRENATAL_API_PERSISTENCE_PLAN.md  # Infraestrutura PostgreSQL/Alembic (Fase 8B)
│   ├── USER_AUTH_PLAN.md          # Especificação de autenticação JWT e sessões (Fase 8C)
│   ├── GESTANTE_GESTACAO_PLAN.md  # Especificação técnica Gestante/Gestação (Fase 8D)
│   ├── FASE_4A_REPORT.md          # Fundação FastAPI, health check e schema DSS
│   ├── FASE_4B_REPORT.md          # Carregamento fail-closed e runtime seguro de ML
│   ├── FASE_4C_REPORT.md          # Implementação funcional do /api/v1/risk-estimate
│   └── FASE_4D_REPORT.md          # Consolidação de compatibilidade e testes HTTP
│
├── ia/                            # PROJETO 3: PIPELINE DE IA / MACHINE LEARNING
│   ├── README.md                  # Especificação metodológica, DGM, modelos e SOM
│   └── planejamento_dataset_sintetico.md # Formulação matemática do DGM
│
├── tcc/                           # PROJETO 4: DOCUMENTAÇÃO ACADÊMICA (TCC2)
│   ├── README.md                  # Guia e sumário da monografia e artigos
│   ├── tcc2.md                    # Monografia completa do TCC2 (documento principal)
│   ├── TCC2_CHAPTER_1_INTRODUCTION.md # Capítulo 1 expandido (Introdução)
│   ├── TCC2_BIBLIOGRAPHY_MATRIX.md    # Matriz bibliográfica categorizada
│   ├── TCC2_DOCX_PLAN.md              # Diretrizes de compilação DOCX ABNT
│   ├── TCC2_UPDATE_PLAN.md            # Plano de sincronização texto-código
│   ├── TCC2_VISUAL_CONTINUITY_PLAN.md # Catálogo de figuras e continuidade visual
│   ├── RELATORIO_F04C_R2.md           # Revisão editorial R2
│   ├── RELATORIO_F04C_R3.md           # Revisão editorial R3
│   ├── RELATORIO_F04C_R3_R1.md        # Revisão editorial R3-R1
│   └── slides/
│       └── RELATORIO_TCC_BANCA_01.md  # Roteiro de slides para banca examinadora
│
├── figures/                       # Figuras e diagramas de apoio à monografia
└── slides/                        # Apresentações de slides e imagens compiladas
```

---

## 1. Documentação do Aplicativo Mobile (`docs/app/`)

Reúne a documentação da camada de apresentação e rede do Flutter:
- **[Guia do App (app/README.md)](app/README.md):** Apresentação geral das responsabilidades do aplicativo móvel.
- **[Integração Flutter ↔ API (app/FLUTTER_API_INTEGRATION.md)](app/FLUTTER_API_INTEGRATION.md):** Detalhamento da arquitetura com Dio, clientes autenticado (`RestClient`) e stateless (`RiskEstimateRestClient`), interceptor de privacidade e mappers de erro.
- **Relatórios de Fases Mobile:** [FASE 5A](app/FASE_5A_REPORT.md) (fundação HTTP), [FASE 5B](app/FASE_5B_REPORT.md) (fluxo do formulário), [FASE 5C](app/FASE_5C_REPORT.md) (Bottom Sheet visual), [FASE 5D](app/FASE_5D_REPORT.md) (teste E2E) e [FASE 6A](app/FASE_6A_REPORT.md) (auditoria de pré-natal).

---

## 2. Documentação da API Backend (`docs/api/`)

Reúne especificações e contratos do backend em FastAPI e PostgreSQL:
- **[Manual da API (api/README.md)](api/README.md):** Arquitetura geral, princípios fail-closed, envelope de erro e guia de execução.
- **[Contrato HTTP Congelado (api/API_CONTRACT_V1.md)](api/API_CONTRACT_V1.md):** Especificação formal do endpoint `/api/v1/risk-estimate`.
- **Planos Arquiteturais e Persistência:** [Arquitetura Pré-natal (8A)](api/PRENATAL_API_ARCHITECTURE_PLAN.md), [Persistência PostgreSQL/Alembic (8B)](api/PRENATAL_API_PERSISTENCE_PLAN.md), [Autenticação JWT (8C)](api/USER_AUTH_PLAN.md) e [Domínio Gestante/Gestação (8D)](api/GESTANTE_GESTACAO_PLAN.md).
- **Relatórios de Construção da API:** [FASE 4A](api/FASE_4A_REPORT.md), [FASE 4B](api/FASE_4B_REPORT.md), [FASE 4C](api/FASE_4C_REPORT.md) e [FASE 4D](api/FASE_4D_REPORT.md).

---

## 3. Documentação de Inteligência Artificial (`docs/ia/`)

Reúne a especificação matemática e metodológica de Machine Learning:
- **[Guia Metodológico de IA (ia/README.md)](ia/README.md):** DGM v1, IV-DSS, avaliação dos modelos supervisionados (Random Forest com limiar $\tau = 0.218$, PR-AUC $0.3023$) e agrupamento não supervisionado via SOM (4 clusters).
- **[Planejamento do Dataset Sintético (ia/planejamento_dataset_sintetico.md)](ia/planejamento_dataset_sintetico.md):** Definição formal do DGM, equações das variáveis latentes e coeficientes epidemiológicos.

---

## 4. Documentação Acadêmica do TCC2 (`docs/tcc/`)

Reúne os artefatos de pesquisa e texto da monografia:
- **[Sumário Acadêmico (tcc/README.md)](tcc/README.md):** Visão geral da monografia e artigos de defesa.
- **[Texto Principal do TCC2 (tcc/tcc2.md)](tcc/tcc2.md):** Monografia completa formatada para o TCC2.
- **[Capítulo 1 — Introdução (tcc/TCC2_CHAPTER_1_INTRODUCTION.md)](tcc/TCC2_CHAPTER_1_INTRODUCTION.md):** Contextualização, objetivos e justificativa detalhados.
- **Apoio Editorial:** [Matriz Bibliográfica](tcc/TCC2_BIBLIOGRAPHY_MATRIX.md), [Plano DOCX ABNT](tcc/TCC2_DOCX_PLAN.md), [Plano de Atualização](tcc/TCC2_UPDATE_PLAN.md) e [Continuidade Visual](tcc/TCC2_VISUAL_CONTINUITY_PLAN.md).
- **Auditorias Editoriais:** [Relatório R2](tcc/RELATORIO_F04C_R2.md), [Relatório R3](tcc/RELATORIO_F04C_R3.md) e [Relatório R3-R1](tcc/RELATORIO_F04C_R3_R1.md).
- **Apresentação:** [Roteiro de Slides da Banca](tcc/slides/RELATORIO_TCC_BANCA_01.md).
