# Integração Flutter ↔ API DSS — Fundação (5A), Fluxo do Formulário (5B) e Apresentação Visual (5C)

> Documentação técnica da integração do app Flutter com
> `POST /api/v1/risk-estimate` via **Dio**. A **FASE 5A** entregou a fundação
> (client, modelos, repositório); a **FASE 5B** conectou o fluxo real do
> formulário à estimativa; a **FASE 5C** apresentou a probabilidade visualmente
> de maneira **não classificatória** (bottom sheet de resultado). Nada aqui
> classifica probabilidade, aplica threshold ou persiste a estimativa.

O contrato de referência é `api/API_CONTRACT_V1.md` (congelado). Nada nesta
fase altera `api/` nem `ia/`.

---

## 1. Escopo

**Implementado (FASE 5A):**

1. Configuração central da base URL da API DSS (`ApiConfig`).
2. Cliente HTTP dedicado à API DSS (`RiskEstimateRestClient`).
3. Modelos Dart da resposta `200` (`RiskEstimate*`).
4. Modelos Dart dos corpos de erro (`ApiError*`).
5. Mapeamento de `DioException` → falhas de domínio.
6. Repositório HTTP (`RiskEstimateRepository` / `…Impl`).
7. Testes unitários/de contrato (determinísticos, sem API real).
8. Privacidade de logging (somente no cliente da API DSS).
9. Documentação técnica (este arquivo).

**Implementado (FASE 5C):** apresentação visual da probabilidade em um
`showModalBottomSheet` de resultado (sem rota nova), com o percentual em
destaque, o rótulo semântico e o `notice` metodológico sempre visível. A
apresentação é **não classificatória**: sem threshold, sem cores de severidade e
sem mutação do `double` original.

**Fora de escopo (permanente):** interpretação da probabilidade; classificação
baixo/médio/alto; limiar (threshold); persistência da estimativa; retry
automático; autenticação; mudanças na API.

---

## 2. Arquitetura

```
lib/app/core/env.dart                                → BACKEND_BASE_URL (login)
lib/app/core/config/api_config.dart                  → API_BASE_URL (API DSS)
lib/app/core/rest_client/rest_client.dart            → Dio do backend (login)
lib/app/core/rest_client/risk_estimate_rest_client.dart → Dio dedicado à API DSS
lib/app/core/rest_client/interceptors/
    privacy_log_interceptor.dart                     → log sem payload (só API DSS)
    auth_interceptor.dart                            → (pré-existente, backend)
lib/app/modules/formulario/models/risk_estimate/
    risk_estimate_response_model.dart                → DTOs 200
    api_error_models.dart                            → DTOs de erro
lib/app/repositories/risk_estimate/
    risk_estimate_failure.dart                       → família de falhas
    dio_exception_mapper.dart                        → DioException → falha
    risk_estimate_repository.dart                    → contrato (abstract)
    risk_estimate_repository_impl.dart               → implementação Dio (DSS)
lib/app/modules/core/core_module.dart                → DI (registro)
lib/app/modules/formulario/controllers/formulario_controller.dart → orquestra o envio (FASE 5B)
lib/app/modules/formulario/formulario_module.dart      → importa CoreModule (resolve o repositório)
lib/app/modules/formulario/formulario_page.dart        → botão "Confirmar e Enviar" (FASE 5B)
lib/app/modules/formulario/widgets/
    risk_estimate_result_sheet.dart                    → bottom sheet de resultado (FASE 5C)
```

Há **dois clientes HTTP independentes**:

| Cliente                     | Destino               | Variável de env        | Uso                               |
| --------------------------- | --------------------- | ---------------------- | --------------------------------- |
| `RestClient` (pré-existente)| Backend de login      | `BACKEND_BASE_URL`     | `UserRepositoryImpl` (`/auth`)    |
| `RiskEstimateRestClient`    | API DSS (estimativa)  | `API_BASE_URL`         | `RiskEstimateRepositoryImpl`      |

Isso impede que `--dart-define=API_BASE_URL=…` redirecione acidentalmente o
login (`POST /auth`) para a API DSS: `POST /auth` continua apontando para
`BACKEND_BASE_URL`, exatamente como antes desta fase.

---

## 3. Base URL (sem hardcode)

- A base URL da API DSS **não é hardcoded**: `String.fromEnvironment('API_BASE_URL')`.
- **Sem fallback** para `BACKEND_BASE_URL` — são destinos independentes:
  - `BACKEND_BASE_URL` → backend/login (`Env.backendBaseUrl`).
  - `API_BASE_URL` → API DSS/estimativa (`ApiConfig`).
- Centralizada em `ApiConfig` — **fora** do domínio/repositório.
- `normalizedBaseUrl` remove a barra final; `isConfigured` indica se há URL.
- `API_BASE_URL` vazio ⇒ API DSS **não configurada** ⇒ `ConfigurationFailure`
  (`"URL da API não configurada."`) **sem** tentar `BACKEND_BASE_URL`.
- **Não** foi embutido `10.0.2.2` nem adicionado
  `android:usesCleartextTraffic=true` global.

**Exemplo de uso (build/run):**

```bash
flutter run \
  --dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

---

## 4. Cliente HTTP (Dio)

### 4.1 `RiskEstimateRestClient` — API DSS

`RiskEstimateRestClient extends DioForNative` com:

| Propriedade        | Valor                                             |
| ------------------ | ------------------------------------------------- |
| `baseUrl`          | `ApiConfig.fromEnvironment().normalizedBaseUrl`   |
| `connectTimeout`   | `10s`                                             |
| `sendTimeout`      | `15s`                                             |
| `receiveTimeout`   | `15s`                                             |
| `Accept`           | `application/json`                                |
| `Content-Type`     | `application/json`                                |

- `validateStatus` **não** foi sobrescrito para aceitar tudo: só `2xx` é sucesso.
- **Sem retry automático** (o endpoint é um `POST` não idempotente).
- **Sem** `badCertificateCallback` que aceite qualquer certificado.
- **Não** recebe `AuthInterceptor` (a API DSS das Fases 4A–4D não exige
  autenticação); **nunca** envia `Authorization` para a API DSS.

### 4.2 `RestClient` — backend (pré-existente, inalterado)

`RestClient extends DioForNative` mantém o **baseline** anterior a esta fase:

- `baseUrl = Env.backendBaseUrl` (`BACKEND_BASE_URL`).
- `connectTimeout` `10s`, `receiveTimeout` `60s` (sem `sendTimeout`).
- Interceptors: `LogInterceptor(requestBody: true, responseBody: true)` +
  `AuthInterceptor`.

> **Dívida técnica (separada, fora do escopo desta fase):** o `RestClient` do
> backend ainda usa `LogInterceptor(requestBody: true, responseBody: true)`.
> **Não** foi alterado nesta fase — registrar como dívida técnica de privacidade
> do login e resolver em etapa própria, sem misturar com a integração DSS.

---

## 5. Contrato de dados

### Requisição

`POST /api/v1/risk-estimate` com o corpo **exato** de `FormularioData.toMap()`
(aninhado, `schema_version: "1.13"`, 6 dimensões). Não se usa `toFlatMap()`.

### Resposta `200`

```json
{
  "result": { "target": "descontinuou_pre_natal", "probability": 0.3219 },
  "model": {
    "name": "random_forest",
    "schema_version": "1.13",
    "raw_feature_count": 34,
    "transformed_feature_count": 96
  },
  "notice": "Estimativa estatística experimental…"
}
```

- `probability` é validada: `num` finito, `0 ≤ p ≤ 1`, convertida para `double`
  **sem arredondamento**. NaN/Infinity/fora do intervalo ⇒ resposta inválida.
- `notice` é **preservada** na íntegra (sem interpretação/classificação).
- **Não** há classificação baixo/médio/alto nem aplicação de threshold no Flutter.

### Erros

| Status | Formato                                   |
| ------ | ----------------------------------------- |
| `422`  | plano: `{code, message, details}`         |
| `500`  | envelope: `{error: {code, message, details}}` |
| `503`  | envelope: `{error: {code, message, details}}` |

---

## 6. Mapeamento de falhas

`RiskEstimateDioExceptionMapper.map(DioException)` produz uma
`RiskEstimateFailure` (família `sealed`). Mensagens amigáveis; **nunca** vaza
status bruto, corpo, HTML, stack trace ou `e.toString()`.

| Condição                                   | Falha                          | Mensagem                                   |
| ------------------------------------------ | ------------------------------ | ------------------------------------------ |
| base URL vazia                             | `ConfigurationFailure`         | URL da API não configurada.                |
| HTTP `422`                                 | `ValidationFailure`            | Requisição inválida                        |
| HTTP `503`                                 | `ModelNotReadyFailure`          | Modelo de inferência indisponível.         |
| HTTP `500`                                 | `InferenceFailure`              | Não foi possível calcular a estimativa.    |
| HTTP `5xx` (demais)                        | `ServiceUnavailableFailure`     | Serviço temporariamente indisponível.      |
| timeout (connect/send/receive/transform)   | `TimeoutFailure`                | Tempo de conexão com o serviço excedido.   |
| `connectionError`                          | `ConnectionFailure`             | Não foi possível conectar ao serviço.      |
| `badCertificate`                           | `ConnectionFailure`             | Não foi possível conectar ao serviço.      |
| `cancel`                                   | `RequestCancelledFailure`       | Requisição cancelada. (não é erro de servidor) |
| `200` malformado                           | `InvalidResponseFailure`        | Resposta inválida do serviço.              |
| demais (`badResponse`/`unknown`/4xx-else)  | `CommunicationFailure`          | Falha de comunicação com o serviço.        |

---

## 7. Privacidade

O questionário transporta dados sociais e de saúde sensíveis. Por isso, **no
cliente da API DSS**:

- `PrivacyLogInterceptor` registra **apenas**: método, caminho, status, duração
  e o tipo genérico do erro (`DioExceptionType`).
- **Nunca** são registrados: corpo de requisição, corpo de resposta, cabeçalhos
  sensíveis (ex.: `Authorization`).
- O `LogInterceptor(requestBody: true, responseBody: true)` **não** é usado no
  cliente DSS.
- O repositório **não** envia device id, user id, token, timestamp, nome, CPF,
  e-mail ou localização — apenas o `toMap()` do formulário.

> O `RestClient` do backend mantém seu `LogInterceptor` original (pré-existente);
> ver §4.2 — tratado como dívida técnica separada.

---

## 8. Injeção de dependências

Registrado em `CoreModule.exportedBinds`:

```dart
i.addSingleton<DioForNative>(RestClient.new);                        // backend (login)
i.addSingleton<ApiConfig>(ApiConfig.fromEnvironment);                // API_BASE_URL
i.addSingleton<RiskEstimateRestClient>(RiskEstimateRestClient.new);  // API DSS
i.addSingleton<RiskEstimateRepository>(RiskEstimateRepositoryImpl.new);
```

`RiskEstimateRepositoryImpl` recebe `client` (`RiskEstimateRestClient`) e
`config` (`ApiConfig`) por injeção de construtor — **não** o `DioForNative`
global. O `DioForNative` global continua servindo apenas o backend/login.

---

## 9. Fluxo do formulário (FASE 5B)

O botão **"Confirmar e Enviar"** (última etapa do `FormularioPage`) agora dispara
a estimativa real, por meio da arquitetura Controller → Repository (sem camada
de Service — `login` é o único caso que usa Service, por persistir o token):

```
FormularioPage (botão)            → valida, mostra resumo
   └─ FormularioController        → guarda estado (MobX) e orquestra
        └─ RiskEstimateRepository → POST /api/v1/risk-estimate (Dio)
             └─ RiskEstimateResponseModel | RiskEstimateFailure
```

**Estado MobX no `FormularioController`** (reusa o `PageStatus` já existente):

| Membro           | Tipo                        | Papel                                          |
| ---------------- | --------------------------- | ---------------------------------------------- |
| `status`         | `PageStatus`                | `initial / loading / success / error`          |
| `loading`        | `bool` (computed)           | `status == PageStatus.loading` (retro-compat UI) |
| `riskEstimate`   | `RiskEstimateResponseModel?`| resultado **tipado** (target/model/notice) p/ 5C |
| `error`          | `String?`                   | mensagem amigável (nunca `DioException`)       |

`enviarFormulario()`: bloqueia submissão concorrente (`if (loading) return`),
define `loading`, **limpa o erro anterior**, usa `consolidatedData`
(`FormularioData`, **não** `toFlatMap()`), chama o repositório **uma única vez**
e armazena `riskEstimate` (sucesso) ou `error` (falha). **Sem** navegação,
**sem** dialog de resultado, **sem** classificação, **sem** threshold, **sem**
retry automático, **sem** persistência. Nova tentativa explícita é permitida.

A UI desabilita o botão durante `loading` (proteção contra duplo envio) e
reage ao resultado via `Observer`: em **sucesso**, fecha o sheet de resumo e
abre o sheet de resultado (FASE 5C); em **falha**, mantém a mensagem amigável de
erro (sem apresentar resultado anterior). O resultado fica em estado no
controller; **não** há reset do formulário nem persistência.

---

## 10. Apresentação visual da estimativa (FASE 5C)

O resultado é apresentado em um `showModalBottomSheet` de resultado
(`lib/app/modules/formulario/widgets/risk_estimate_result_sheet.dart`), sem rota
nova e sem dois sheets simultâneos: o sheet de resumo fecha e o de resultado
abre na sequência. O conteúdo é **não classificatório**:

- Título **"Estimativa de acompanhamento"** (nunca "diagnóstico" nem "risco").
- `probability * 100` formatada como percentual pt-BR com **1 casa decimal**
  (ex.: `0.238` → `"23,8%"`), em cor **constante** (`primary500`) — sem variação
  de cor por valor.
- Rótulo semântico: **"Probabilidade estimada de descontinuidade do
  acompanhamento pré-natal"**.
- `notice` exibida **na íntegra** em um card informativo sempre visível.
- Botão **"Entendi"** fecha apenas o sheet de resultado (sem reset do
  formulário; o resultado permanece em estado no controller).

Não há classificação (baixo/médio/alto), threshold (`>= 0.5` / `> 0.5`), cor de
severidade, diagnóstico ou afirmação de certeza: `0,0%` não é "sem risco" e
`100,0%` não é "certeza". A formatação é **somente visual** — o `double`
original em `result.probability` permanece intacto.

## 11. Testes (determinísticos, sem API real)

Cobertura em `test/risk_estimate/` e `test/core/rest_client/`:

| Arquivo                                   | Cobre                                        |
| ----------------------------------------- | -------------------------------------------- |
| `api_config_test.dart`                    | normalização, `isConfigured`, `fromEnvironment` lê só `API_BASE_URL` |
| `risk_estimate_response_model_test.dart`  | parse 200, validação de `probability`        |
| `api_error_models_test.dart`              | parse 422 plano / 500-503 envelope, defensivo |
| `dio_exception_mapper_test.dart`          | cada condição → falha e mensagem corretas    |
| `risk_estimate_repository_impl_test.dart` | 200/422/503/500/malformado/config; corpo enviado; sem retry; base vazia sem request (via `HttpClientAdapter` fake) |
| `rest_client_test.dart`                   | backend baseline: `BACKEND_BASE_URL`, timeouts 10/60, `LogInterceptor`+`AuthInterceptor`, `validateStatus` 2xx |
| `risk_estimate_rest_client_test.dart`     | DSS: `API_BASE_URL`, timeouts 10/15/15, headers JSON, `PrivacyLogInterceptor` (sem `LogInterceptor`/`AuthInterceptor`), `validateStatus` 2xx |
| `clients_isolation_test.dart`             | bases independentes; `API_BASE_URL` não altera `RestClient`; `API_BASE_URL` vazia sem fallback |

Cobertura da FASE 5B em `test/formulario/controllers/`:

| Arquivo                          | Cobre                                                              |
| -------------------------------- | ------------------------------------------------------------------ |
| `formulario_controller_test.dart` | estado inicial; loading; sucesso (probability preservada); resposta completa; falha; duplo envio (`callCount == 1`); retry explícito após erro; sem retry automático; entrega `FormularioData` (não `toFlatMap`) |

Cobertura da FASE 5C em `test/formulario/widgets/`:

| Arquivo                                  | Cobre                                                              |
| ---------------------------------------- | ------------------------------------------------------------------ |
| `risk_estimate_result_sheet_test.dart`   | formatação (`0.238→"23,8%"`, `0.0→"0,0%"`, `1.0→"100,0%"`, arredondamento só visual); não mutação do `double`; percentual + rótulo semântico; `notice` não hardcoded; ausência de classificação; `0,0%` sem "sem risco"; `100,0%` sem "certeza"; botão "Entendi" fecha o sheet |

Nenhum teste usa `localhost`/`10.0.2.2` ou a API real.

---

## 12. Como executar a verificação

```bash
flutter analyze                                   # sem novos issues
flutter test                                      # todos passam
dart format <arquivos alterados>                  # apenas arquivos criados/alterados
git diff -- api/ && git diff -- ia/               # devem ser vazios
```

---

## 13. Notas de segurança / conformidade

- `ApiConfig` pode ser sobrescrito em testes para uma URL determinística.
- A ausência de `--dart-define=API_BASE_URL` deixa a base URL vazia ⇒ o
  repositório retorna `ConfigurationFailure` **sem** disparar requisição e **sem**
  tentar `BACKEND_BASE_URL`.
- `BACKEND_BASE_URL` continua servindo o login, independente de `API_BASE_URL`.
- Nenhuma mudança em `api/` ou `ia/` foi realizada nesta fase.
