# Documentação do Backend REST (FastAPI)

Este diretório reúne as especificações técnicas, contratos formais, planos arquiteturais e relatórios de auditoria da API backend **Meu Bebê API** (`meu_bebe_api`).

---

## 1. Visão Geral da API

A API é um backend REST construído em **Python 3.12+ (FastAPI)** estruturado para atender:

1. **Autenticação e Sessões (JWT):** Cadastro de gestantes, emissão de Access Token (JWT HS256) e renovação segura de sessões via Refresh Token.
2. **Acompanhamento Pré-Natal Completo:** Persistência relacional em PostgreSQL para gestantes, gestações ativas, histórico obstétrico, consultas, exames, medicamentos, vacinas, plano de parto estruturado e histórico de avaliações DSS vinculadas.
3. **Inferência Probabilística Experimental (DSS):** Endpoint stateless de estimativa probabilística de propensão à descontinuidade do pré-natal baseada no schema congelado v1.13 e modelo Random Forest treinado no pacote de IA.

---

## 2. Índice de Documentos

### Contratos e Planos Arquiteturais
| Documento | Fase | Descrição |
|---|---|---|
| [API_CONTRACT_V1.md](API_CONTRACT_V1.md) | **v1** | **Contrato HTTP formal e congelado** para o endpoint de estimativa de risco DSS (`POST /api/v1/risk-estimate`). Define payloads, enums, validações e respostas. |
| [PRENATAL_API_ARCHITECTURE_PLAN.md](PRENATAL_API_ARCHITECTURE_PLAN.md) | **8A** | Arquitetura-alvo da API REST para o módulo pré-natal: mapeamento de entidades, ownership, isolamento e contratos. |
| [PRENATAL_API_PERSISTENCE_PLAN.md](PRENATAL_API_PERSISTENCE_PLAN.md) | **8B** | Definição da stack de banco de dados (SQLAlchemy 2.x síncrono + psycopg 3 + Alembic migrations + PostgreSQL) com design inerte. |
| [USER_AUTH_PLAN.md](USER_AUTH_PLAN.md) | **8C** | Modelagem de usuários, hashing seguro (Argon2 / bcrypt), emissão stateless de tokens JWT e sessões persistentes de renovação. |
| [GESTANTE_GESTACAO_PLAN.md](GESTANTE_GESTACAO_PLAN.md) | **8D** | Especificação técnica dos recursos REST de gestantes, gestações ativas e histórico obstétrico. |

### Relatórios Históricos de Construção da API
| Documento | Fase | Descrição |
|---|---|---|
| [FASE_4A_REPORT.md](FASE_4A_REPORT.md) | **4A** | Fundação da API FastAPI, health check (`/health`), validação com Pydantic v2 e schema DSS 1.13. |
| [FASE_4B_REPORT.md](FASE_4B_REPORT.md) | **4B** | Carregamento seguro fail-closed do modelo de Machine Learning com validação de hash SHA-256 e endpoint `/ready`. |
| [FASE_4C_REPORT.md](FASE_4C_REPORT.md) | **4C** | Implementação funcional do endpoint `/api/v1/risk-estimate` com inferência probabilística e metadados. |
| [FASE_4D_REPORT.md](FASE_4D_REPORT.md) | **4D** | Consolidação de compatibilidade Flutter ↔ API, suíte de testes HTTP e congelamento do contrato v1. |

---

## 3. Princípios Arquiteturais e Segurança

- **Padrão Fail-Closed e Subsistemas Inertes:**
  - Sem `DATABASE_URL`, a API inicia normalmente, mas recursos relacionais respondem `503 DATABASE_NOT_CONFIGURED`. O endpoint DSS stateless (`/api/v1/risk-estimate`) continua 100% operacional.
  - Sem `JWT_SECRET`, endpoints protegidos respondem `503 AUTH_NOT_CONFIGURED`.
  - Se o arquivo do modelo ML for corrompido ou divergir do hash esperado no manifest, `/ready` responde `503 MODEL_NOT_READY` e `/api/v1/risk-estimate` falha de forma segura sem crash do servidor.
- **Envelope Único de Erro:** Todas as respostas de erro HTTP seguem formato padronizado e sanitizado:
  ```json
  {
    "code": "VALIDATION_ERROR",
    "message": "Requisição inválida",
    "details": [
      { "loc": ["body", "educacao", "escolaridade"], "msg": "Field required", "type": "missing" }
    ]
  }
  ```

---

## 4. Execução da API

Para instruções passo a passo de configuração do ambiente virtual, variáveis de ambiente, execução com Uvicorn e migrações com Alembic, consulte o arquivo de entrada [api/README.md](../../api/README.md).
