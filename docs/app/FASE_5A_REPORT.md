# Relatório FASE 5A — Fundação da Integração Flutter ↔ API com Dio

> Resultado da verificação item a item do escopo da FASE 5A, **após a correção
> do bloqueador apontado na auditoria final**. Estado final:
> **`flutter analyze` sem issues, `flutter test` 164/164, nenhuma alteração em
> `api/` ou `ia/`, nenhum commit.** A fase está **CONCLUÍDA** e **AGUARDANDO
> REVISÃO** (regra de parada).

---

## 0. Correção do bloqueador (auditoria final)

A auditoria final encontrou um **bloqueador real**: um único `DioForNative`
compartilhado por `UserRepositoryImpl` (`POST /auth`) e
`RiskEstimateRepositoryImpl` (`POST /api/v1/risk-estimate`). Como a FASE 5A
alterava o `baseUrl` desse client global, `--dart-define=API_BASE_URL=…`
redirecionava também o login para a API DSS — uma regressão.

**Correção aplicada — dois clientes HTTP independentes:**

| Cliente                      | Destino              | Variável de env        | Uso                                |
| ---------------------------- | -------------------- | ---------------------- | ---------------------------------- |
| `RestClient` (restaurado)    | Backend de login     | `BACKEND_BASE_URL`     | `UserRepositoryImpl` (`/auth`)     |
| `RiskEstimateRestClient`     | API DSS (estimativa) | `API_BASE_URL`         | `RiskEstimateRepositoryImpl`       |

- `rest_client.dart` **restaurado** ao baseline pré-FASE 5A (`Env.backendBaseUrl`,
  `receiveTimeout` 60s, sem `sendTimeout`, interceptors originais
  `[LogInterceptor, AuthInterceptor]`).
- `ApiConfig` lê **somente** `API_BASE_URL`; **sem fallback** para
  `BACKEND_BASE_URL`.
- `RiskEstimateRestClient` dedicado à API DSS, com `PrivacyLogInterceptor` e
  **sem** `AuthInterceptor`.
- `RiskEstimateRepositoryImpl` recebe `RiskEstimateRestClient` (não o
  `DioForNative` global).
- Testes 13–17 (ver §7) provam o isolamento das bases.

---

## 1. Configuração da base URL

| # | Item | Situação |
|---|------|----------|
| 1 | Base URL não é hardcoded (sem URL de produção/`10.0.2.2` embutida) | ✅ CONFORME |
| 2 | Usa `String.fromEnvironment('API_BASE_URL')` (nome recomendado) | ✅ CONFORME |
| 3 | `ApiConfig` lê **somente** `API_BASE_URL` — **sem fallback** para `BACKEND_BASE_URL` | ✅ CONFORME |
| 4 | `BACKEND_BASE_URL` continua servindo o backend/login (`Env.backendBaseUrl`), independente de `API_BASE_URL` | ✅ CONFORME |
| 5 | Centralizada em `ApiConfig` — fora do domínio/repositório | ✅ CONFORME |
| 6 | `normalizedBaseUrl` remove a barra final | ✅ CONFORME |
| 7 | `isConfigured` indica se há URL utilizável | ✅ CONFORME |
| 8 | `API_BASE_URL` vazia ⇒ `ConfigurationFailure` (`"URL da API não configurada."`), **sem** tentar `BACKEND_BASE_URL` | ✅ CONFORME |
| 9 | **Não** adicionado `android:usesCleartextTraffic=true` globalmente | ✅ CONFORME |

---

## 2. Clientes HTTP (Dio)

| # | Item | Situação |
|---|------|----------|
| 10 | `RiskEstimateRestClient` dedicado à API DSS (não reutiliza o `DioForNative` global) | ✅ CONFORME |
| 11 | `RestClient` do backend **restaurado** ao baseline (baseUrl `Env.backendBaseUrl`) | ✅ CONFORME |
| 12 | `RiskEstimateRestClient.baseUrl` = `ApiConfig.fromEnvironment().normalizedBaseUrl` | ✅ CONFORME |
| 13 | `connectTimeout` 10s (DSS) | ✅ CONFORME |
| 14 | `sendTimeout` 15s (DSS) | ✅ CONFORME |
| 15 | `receiveTimeout` 15s (DSS) | ✅ CONFORME |
| 16 | Header `Accept: application/json` (DSS) | ✅ CONFORME |
| 17 | Header `Content-Type: application/json` (DSS) | ✅ CONFORME |
| 18 | `validateStatus` **não** sobrescrito para aceitar tudo (2xx → sucesso) | ✅ CONFORME |
| 19 | **Sem** `AuthInterceptor` no client DSS (nunca envia `Authorization`) | ✅ CONFORME |
| 20 | **Sem** `badCertificateCallback = (_) => true` | ✅ CONFORME |
| 21 | **Sem** retry automático para `POST /api/v1/risk-estimate` | ✅ CONFORME |

---

## 3. Modelos da resposta `200`

| # | Item | Situação |
|---|------|----------|
| 22 | `RiskEstimateResponseModel` implementado | ✅ CONFORME |
| 23 | `RiskEstimateResultModel` (`target`, `probability`) implementado | ✅ CONFORME |
| 24 | `RiskEstimateModelMetadata` (`name`, `schema_version`, contagens) implementado | ✅ CONFORME |
| 25 | Serialização manual (`fromMap`/`tryParse`), **sem** code generation | ✅ CONFORME |
| 26 | `probability` converte `(num).toDouble()` **sem arredondamento** | ✅ CONFORME |
| 27 | `probability` rejeita NaN/Infinity | ✅ CONFORME |
| 28 | `probability` rejeita fora de `[0, 1]` (ex.: `-0.1`, `1.1`) | ✅ CONFORME |
| 29 | `notice` da API é **preservada** (sem interpretação) | ✅ CONFORME |
| 30 | **Não** classifica (baixo/médio/alto) nem aplica threshold no Flutter | ✅ CONFORME |

---

## 4. Modelos de erro HTTP

| # | Item | Situação |
|---|------|----------|
| 31 | `ApiErrorModel` (`code`, `message`, `details`) implementado | ✅ CONFORME |
| 32 | `ApiErrorDetailModel` (`loc`, `msg`, `type`) implementado | ✅ CONFORME |
| 33 | `ApiErrorEnvelopeModel` (`error`) para 500/503 implementado | ✅ CONFORME |
| 34 | `422` tratado como **plano** `{code, message, details}` | ✅ CONFORME |
| 35 | `500`/`503` tratados como **envelope** `{error: {…}}` | ✅ CONFORME |
| 36 | Parsing defensivo (`tryParse` retorna `null`; ignora details malformados) | ✅ CONFORME |

---

## 5. Mapeamento de `DioException`

| # | Item | Situação |
|---|------|----------|
| 37 | `422` → `ValidationFailure` (`"Requisição inválida"`) | ✅ CONFORME |
| 38 | `503` → `ModelNotReadyFailure` (`"Modelo de inferência indisponível."`) | ✅ CONFORME |
| 39 | `500` → `InferenceFailure` (`"Não foi possível calcular a estimativa."`) | ✅ CONFORME |
| 40 | demais `5xx` → `ServiceUnavailableFailure` (`"Serviço temporariamente indisponível."`) | ✅ CONFORME |
| 41 | timeouts → `TimeoutFailure` (`"Tempo de conexão com o serviço excedido."`) | ✅ CONFORME |
| 42 | `connectionError` → `ConnectionFailure` (`"Não foi possível conectar ao serviço."`, **não** "Sem internet") | ✅ CONFORME |
| 43 | `badCertificate` → falha genérica (nunca aceita certificado) | ✅ CONFORME |
| 44 | `cancel` → `RequestCancelledFailure` (não é erro de servidor) | ✅ CONFORME |
| 45 | `200` malformado → `InvalidResponseFailure` (`"Resposta inválida do serviço."`, sem TypeError na UI) | ✅ CONFORME |
| 46 | fallback genérico (`CommunicationFailure`), nunca `e.toString()` | ✅ CONFORME |

---

## 6. Repositório HTTP

| # | Item | Situação |
|---|------|----------|
| 47 | `RiskEstimateRepository` (contrato abstrato) definido | ✅ CONFORME |
| 48 | `RiskEstimateRepositoryImpl` implementa o contrato | ✅ CONFORME |
| 49 | Recebe `RiskEstimateRestClient` (não o `DioForNative` global) | ✅ CONFORME |
| 50 | Envia `POST /api/v1/risk-estimate` (endpoint congelado) | ✅ CONFORME |
| 51 | Corpo = `FormularioData.toMap()` (não `toFlatMap()`) | ✅ CONFORME |
| 52 | Preserva `schema_version: "1.13"` | ✅ CONFORME |
| 53 | Retorna `Result<RiskEstimateResponseModel, RiskEstimateFailure>` | ✅ CONFORME |
| 54 | `DioException` capturado e mapeado (não propaga exceção crua) | ✅ CONFORME |
| 55 | Não persiste resultado | ✅ CONFORME |
| 56 | Não envia device id/user id/token/timestamp/nome/CPF/e-mail/localização | ✅ CONFORME |

---

## 7. Testes unitários / de contrato

| # | Item | Situação |
|---|------|----------|
| 57 | `api_config_test.dart` (normalização, vazio, `fromEnvironment` lê só `API_BASE_URL`) | ✅ CONFORME |
| 58 | `risk_estimate_response_model_test.dart` (200 + validação de `probability`) | ✅ CONFORME |
| 59 | `api_error_models_test.dart` (422 plano / envelope / defensivo) | ✅ CONFORME |
| 60 | `dio_exception_mapper_test.dart` (cada condição → falha) | ✅ CONFORME |
| 61 | `risk_estimate_repository_impl_test.dart` (via `HttpClientAdapter` fake; base vazia sem request) | ✅ CONFORME |
| 62 | `rest_client_test.dart` (backend baseline: `BACKEND_BASE_URL`, timeouts 10/60, interceptors originais) | ✅ CONFORME |
| 63 | `risk_estimate_rest_client_test.dart` (DSS: timeouts, headers, `PrivacyLogInterceptor`, sem `LogInterceptor`/`AuthInterceptor`) | ✅ CONFORME |
| 64 | **13** — bases independentes (`BACKEND_BASE_URL=A`, `API_BASE_URL=B` → destinos distintos) | ✅ CONFORME |
| 65 | **14** — `API_BASE_URL` não altera `RestClient.baseUrl` | ✅ CONFORME |
| 66 | **15** — `API_BASE_URL` vazia → `ConfigurationFailure`, sem request, sem tentar `BACKEND_BASE_URL` | ✅ CONFORME |
| 67 | **16** — sem `API_BASE_URL`, `RestClient` usa `BACKEND_BASE_URL` | ✅ CONFORME |
| 68 | **17** — interceptors de cada client (`[LogInterceptor, AuthInterceptor]` vs `[PrivacyLogInterceptor]`) | ✅ CONFORME |
| 69 | **Não** testa com API real (`localhost`/`10.0.2.2`) — determinístico | ✅ CONFORME |
| 70 | Todos os testes passam (`flutter test` = 164) | ✅ CONFORME |

---

## 8. Privacidade

| # | Item | Situação |
|---|------|----------|
| 71 | `RiskEstimateRestClient` (DSS) **não** usa `LogInterceptor(requestBody: true, responseBody: true)` | ✅ CONFORME |
| 72 | `PrivacyLogInterceptor` registra só método/caminho/status/duração/tipo de erro | ✅ CONFORME |
| 73 | **Não** usa `print(response.data)` nem loga payload no client DSS | ✅ CONFORME |
| 74 | **Não** loga cabeçalhos sensíveis (ex.: `Authorization`) | ✅ CONFORME |
| 75 | Nenhum dado social/saúde vaza para log no client DSS | ✅ CONFORME |
| 76 | `RestClient` (backend) mantém `LogInterceptor` original — **dívida técnica separada, fora do escopo** | ✅ CONFORME |

---

## 9. Documentação e verificação final

| # | Item | Situação |
|---|------|----------|
| 77 | `FLUTTER_API_INTEGRATION.md` criado/atualizado (dois clients, sem fallback) | ✅ CONFORME |
| 78 | `api/API_CONTRACT_V1.md` **não** alterado | ✅ CONFORME |
| 79 | `flutter analyze` sem novos issues (`No issues found!`) | ✅ CONFORME |
| 80 | `dart format` aplicado **apenas** nos arquivos criados/alterados | ✅ CONFORME |
| 81 | `git diff -- api/` e `git diff -- ia/` vazios; `git status` só Flutter/doc | ✅ CONFORME |

---

## Confirmações finais

- **Dois clientes independentes:** `RestClient` (backend/login) e
  `RiskEstimateRestClient` (API DSS/estimativa) — sem redirecionar o login.
- **`toFlatMap()`:** NÃO usado no HTTP — o corpo usa `FormularioData.toMap()`.
- **Domínio/repository:** NÃO contêm URL embutida (centralizada em `ApiConfig`).
- **Arquivos protegidos:** NENHUMA alteração em `api/` ou `ia/`.
- **Regra de parada:** nenhuma divergência entre `FormularioData.toMap()` e
  `api/API_CONTRACT_V1.md` foi encontrada; nenhuma mudança na API foi necessária.
- **Controller/telas/rotas:** NÃO modificados. `FormularioData`/`toMap`/
  `fromMap`/`toFlatMap` NÃO alterados.
- **DTOs, mapper, probability, endpoint:** NÃO alterados — apenas o client
  injetado foi trocado.
- **health/ready client, auth, resultado, classificação, persistência, retry:**
  NÃO implementados (deferidos para FASE 5B+).
- **Dívida técnica registrada (fora do escopo):** `RestClient` do backend ainda
  usa `LogInterceptor(requestBody: true, responseBody: true)`.
- **Commit:** NÃO realizado (conforme instrução).

---

## Estado

> **FASE 5A CONCLUÍDA (com correção do bloqueador). PARAR E AGUARDAR REVISÃO.**
