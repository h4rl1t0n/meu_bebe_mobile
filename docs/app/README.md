# Documentação do Aplicativo Mobile (Flutter)

Este diretório reúne toda a documentação técnica, especificações de integração e relatórios de auditoria do aplicativo móvel **Meu Bebê** (`meu_bebe_mobile`).

---

## 1. Visão Geral do Aplicativo

O aplicativo móvel foi desenvolvido em **Flutter** e tem como missão apoiar o acompanhamento pré-natal integral de gestantes atendidas pelo SUS, integrando:

1. **Questionário dos Determinantes Sociais da Saúde (DSS):** Coleta estruturada em 6 blocos temáticos (educação, trabalho/renda, habitação, saneamento básico, alimentação e acesso à saúde/transporte).
2. **Estimativa Probabilística de Descontinuidade:** Comunicação segura com a API backend para obter estimativa de propensão à descontinuidade do pré-natal baseada em modelo de Machine Learning, apresentada de forma não alarmista e não classificatória.
3. **Gestão do Pré-Natal:** Registro de consultas, exames, vacinas, medicamentos e construção interativa do Plano de Parto.
4. **Autenticação e Sincronização:** Login, registro, onboarding e sessão autenticada com tokens JWT.

---

## 2. Índice de Documentos

| Documento | Tipo | Descrição |
|---|---|---|
| [FLUTTER_API_INTEGRATION.md](FLUTTER_API_INTEGRATION.md) | **Arquitetura / Integração** | Guia completo da camada de rede (Dio): clientes isolados, interceptors de segurança/privacidade, mappers de erro sanitizados, DTOs e Bottom Sheet visual. |
| [FASE_5A_REPORT.md](FASE_5A_REPORT.md) | **Relatório de Auditoria** | Fundação da integração HTTP no Flutter: configuração do Dio, modelos de dados e repositório DSS. |
| [FASE_5B_REPORT.md](FASE_5B_REPORT.md) | **Relatório de Auditoria** | Conexão do fluxo do formulário de 6 etapas à chamada HTTP `/api/v1/risk-estimate`. |
| [FASE_5C_REPORT.md](FASE_5C_REPORT.md) | **Relatório de Auditoria** | Implementação e validação da apresentação visual da estimativa probabilística (`RiskEstimateResultSheet`). |
| [FASE_5D_REPORT.md](FASE_5D_REPORT.md) | **Relatório de Validação E2E** | Validação ponta a ponta em emulador Android real: Flutter ↔ FastAPI ↔ Modelo de Machine Learning. |
| [FASE_6A_REPORT.md](FASE_6A_REPORT.md) | **Relatório de Auditoria** | Mapeamento das telas pré-natal legadas e especificação dos requisitos para migração cliente-servidor. |

---

## 3. Arquitetura da Camada de Integração

O aplicativo utiliza o pacote **Dio** com separação estrita de responsabilidades:
- **`RestClient` (Autenticado):** Utilizado para endpoints do pré-natal com `AuthInterceptor` (injeção automática do Bearer token e renovação via refresh token).
- **`RiskEstimateRestClient` (Stateless):** Cliente isolado dedicado à estimativa DSS, com `SecurityPrivacyInterceptor` que bloqueia cabeçalhos sensíveis (Authorization, Cookies) para proteger os dados de vulnerabilidade.
- **Envelope de Erro e Mappers:** Todos os erros HTTP são mapeados para `BackendFailure` com mensagens amigáveis em português e tratamento de falhas de conexão/timeout.

Para detalhes completos de implementação e exemplos de código, consulte [FLUTTER_API_INTEGRATION.md](FLUTTER_API_INTEGRATION.md).
