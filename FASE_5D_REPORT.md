# Relatório FASE 5D — Validação Real Ponta a Ponta (Flutter ↔ FastAPI ↔ IA)

> Fase de **auditoria, execução e smoke test** (sem desenvolvimento de novas
> funcionalidades). Nenhum arquivo de `api/`, `ia/` ou `lib/` foi alterado. A
> validação **HTTP automatizada** e a **validação manual da UI** (Android
> Emulator) foram concluídas com sucesso.

**Classificação final: FASE 5D APROVADA** (validação de integração de software —
não validação clínica/preditiva).

---

## A. BASELINE

| Item | Resultado |
|------|-----------|
| `git status --short` | **vazio** ✅ |
| `git log -5 --oneline` | `ba6b5a7`, `da119d7 feat(flutter): present experimental risk estimate result` (5C), `4a80f4d …connect questionnaire…` (5B), `770e79f …add risk estimate API client` (5A), `dc8ce84 test(api): consolidate Flutter API contract` (4D) ✅ |
| `flutter analyze` | `No issues found! (ran in 23.3s)` ✅ |
| `flutter test` | `+183: All tests passed!` (183/183) ✅ |
| `flutter devices` | Windows (desktop), Chrome (web), Edge (web) — **sem Android** no momento da auditoria; o Android Emulator foi conectado depois para o teste manual ✅ |
| Target real da validação manual | **Android Emulator** — `emulator-5554`, Android 17 / API 37 ✅ |

## B. API

| Item | Valor |
|------|-------|
| Entrypoint | `api/src/meu_bebe_api/main.py` → `app = create_app()` |
| Objeto FastAPI | `app` (instância de `FastAPI`, `create_app()` na fábrica) |
| Comando real (README) | `uvicorn meu_bebe_api.main:app --reload` (a partir de `api/`, venv ativado) |
| Comando usado no smoke test | `python -m uvicorn meu_bebe_api.main:app --host 127.0.0.1 --port 8000` |
| Host / porta | `127.0.0.1` / `8000` (padrão do `Settings`) |
| Python / env | `api/.venv` — Python **3.14.5** (`C:\Python314`) |
| Dependências | `pyproject.toml`: fastapi 0.141.1, uvicorn 0.52.4, pydantic, pydantic-settings; dev: pytest, httpx |
| IA editable | `meu_bebe_ml` **0.1.0** instalado editável → `ia/src/meu_bebe_ml/__init__.py` (sem `sys.path`/cópia) ✅ |
| `/health` | **200** `{"status":"ok","service":"meu-bebe-api","api_version":"0.1.0","dss_schema_version":"1.13"}` ✅ (idêntico ao esperado) |
| `/ready` | **200** `{"status":"ready","service":"meu-bebe-api","model":{"name":"random_forest","raw_feature_count":34,"transformed_feature_count":96}}` ✅ (artifact localizado, hash validado, `joblib.load` ok, pipeline disponível) |

## C. HTTP

| Item | Resultado |
|------|-----------|
| Requisição real | `POST http://127.0.0.1:8000/api/v1/risk-estimate` via `curl`, atravessando **HTTP** (não `ModelRuntime` direto) |
| Fixture usado | `api/tests/fixtures/flutter_dss_payload_v1_13.json` (congelado) |
| Status | **200** ✅ |
| `result.target` | `descontinuou_pre_natal` ✅ |
| `result.probability` | **`0.238`** ✅ — **golden congelado da Fase 4D preservado** (sem drift do artefato) |
| `model.name` / `schema_version` | `random_forest` / `1.13` ✅ |
| `model.raw_feature_count` / `transformed_feature_count` | `34` / `96` ✅ |
| `notice` | presente, texto experimental íntegro ✅ |
| Teste 422 (payload inválido) | **422** `{"code":"VALIDATION_ERROR","message":"Requisição inválida","details":[{"loc":["body","educacao"],"msg":"Field required","type":"missing"},…]}` ✅ (formato plano congelado; `details` só com `loc`/`msg`/`type`, sem valor/body bruto) |
| Suíte da API (`pytest`) | **150 passed** (warnings pré-existentes conhecidos: `httpx`/Starlette e NumPy 2.5 `array.shape`) |

> `0.238` foi confirmado **sem** transformação em threshold/classificação. Os
> valores `33,2%` e `34,4%` da validação manual são resultado de **respostas
> reais do usuário** (diferentes do fixture), portanto probabilidades diferentes
> — comportamento esperado, sem drift e sem interpretação clínica.

## D. FLUTTER

| Item | Resultado |
|------|-----------|
| `ApiConfig` | Lê **somente** `API_BASE_URL` (`String.fromEnvironment`); sem fallback para `BACKEND_BASE_URL` ✅ |
| `RiskEstimateRestClient` | `DioForNative` dedicado, `baseUrl = ApiConfig.fromEnvironment().normalizedBaseUrl`; só `PrivacyLogInterceptor` ✅ |
| Cliente DSS separado do backend | Sim — `RestClient` (login, `BACKEND_BASE_URL`) e `RiskEstimateRestClient` (DSS, `API_BASE_URL`) independentes ✅ |
| Ausência de `Authorization` | Confirmado por inspeção: sem `AuthInterceptor` no cliente DSS; headers só `Accept`/`Content-Type` JSON ✅ |
| Privacy logging | `PrivacyLogInterceptor` registra apenas **método, path, status, tipo de erro, duração** — **nunca** body/sensível ✅ |
| Corpo enviado | `data.toMap()` (`risk_estimate_repository_impl.dart:32`), **não** `toFlatMap()` ✅ |
| Endpoint | `POST /api/v1/risk-estimate` (inalterado) ✅ |
| Target real | **Android Emulator** (`emulator-5554`, Android 17 / API 37) |
| `API_BASE_URL` real | `http://10.0.2.2:8000` (host alcançado via alias do emulador) |
| Comando `flutter run` | `flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000` |
| Cleartext HTTP | **Não bloqueou** — a chamada `http://10.0.2.2:8000` no emulador (API 37) chegou à API e retornou 200. O `AndroidManifest.xml` não declara `usesCleartextTraffic="true"`, mas o cliente DSS usa `DioForNative`/`dart:io` (stack de socket próprio, não sujeito à política de cleartext da plataforma Android) — observado empiricamente, sem alteração de código. |

## E. TESTE MANUAL — **CONCLUÍDO (usuário)**

Target: **Android Emulator** (`emulator-5554`), com a FastAPI no host Windows em
`http://127.0.0.1:8000`.

### E.1 Sucesso real

O usuário preencheu o questionário e executou **Resumo → Confirmar e Enviar**:

- a requisição chegou à API e a inferência executou;
- o bottom sheet de resumo **fechou**;
- o bottom sheet **"Estimativa de acompanhamento"** abriu;
- o percentual foi exibido corretamente em pt-BR — primeira execução: **`33,2%`**;
- rótulo exibido: **"Probabilidade estimada de descontinuidade do acompanhamento pré-natal"**;
- `notice` experimental visível;
- botão **"Entendi"** visível;
- **nenhuma** classificação baixo/médio/alto, **nenhum** diagnóstico, **nenhuma** recomendação clínica.

**VALIDADO.**

### E.2 Botão "Entendi"

- o bottom sheet fechou;
- retornou ao formulário;
- as respostas permaneceram preenchidas;
- **não** houve reset automático.

**VALIDADO.**

## F. RESILIÊNCIA — **CONCLUÍDO (usuário)**

### F.1 Falha real — API desligada

A API foi confirmadamente desligada (`Invoke-RestMethod http://127.0.0.1:8000/health`
→ impossibilidade de conexão). Sem fechar o Flutter, o usuário fez nova submissão:

- mensagem exibida: **"Não foi possível conectar ao serviço."**;
- o loading terminou;
- o app permaneceu responsivo;
- as respostas continuaram preenchidas;
- o resultado anterior **não** foi reapresentado;
- **não** houve retry automático;
- o botão voltou a ficar disponível.

**VALIDADO.**

### F.2 Retry manual

A API foi religada com
`python -m uvicorn meu_bebe_api.main:app --host 127.0.0.1 --port 8000`. Sem
reiniciar o app, o usuário fez nova submissão explícita:

- **HTTP 200** / inferência concluída;
- o bottom sheet abriu novamente;
- nesta submissão (após alteração de respostas) foi exibido **`34,4%`**.

Fluxo confirmado: **ERRO → API disponível → retry explícito → SUCESSO**. **VALIDADO.**

### F.3 Observação — um 422 intermediário

Durante a validação ocorreu uma tentativa que retornou **HTTP 422** ("Requisição
inválida"). Antes dessa tentativa o usuário havia **alterado respostas** do
questionário, portanto **não** é falha de retry. Registro como observação:

> "Foi observada uma combinação de respostas que resultou em VALIDATION_ERROR
> 422. Como as respostas haviam sido modificadas e o conjunto exato não foi
> registrado, não foi possível reproduzir nem classificar como defeito. O evento
> não comprometeu a validação do retry manual."

Uma submissão posterior (também após alteração de respostas) retornou HTTP 200 e
exibiu `34,4%`. **Não** foi criado `BUG 5D-1`; uma eventual auditoria futura de
combinações condicionais do formulário pode estudar esse caso separadamente.

### F.4 Evidência automatizada complementar (sem sabotar artefato)

| Cenário | Evidência |
|---------|-----------|
| `API_BASE_URL` ausente → `ConfigurationFailure` | `risk_estimate_repository_impl_test.dart` — `baseUrl vazio → ConfigurationFailure, sem efetuar requisição` |
| `503` `MODEL_NOT_READY` | `risk_estimate_repository_impl_test.dart` — `503 → ModelNotReadyFailure` |
| Falha → `PageStatus.error` + sem resultado + sem retry automático | `formulario_controller_test.dart` |
| Retry explícito após erro | `formulario_controller_test.dart` — `retry explícito após erro (callCount == 2)` |

## G. METODOLOGIA

Confirmado por inspeção e smoke test:

- **Sem threshold** e **sem classificação** — a API e o Flutter expõem apenas a
  probabilidade `[0,1]` (sem `>= 0.5`, `riskLevel`, `highRisk`, `lowRisk`, …).
- **Sem interpretação clínica** — os valores observados (`0.238`, `33,2%`,
  `34,4%`) são apenas integração de software; não se conclui "acertou", "em
  risco" nem "abandonaria".
- **Sem persistência** — API *stateless*; Flutter não persiste a estimativa.
- **Sem identidade** — sem `gestanteId`/`userId`/token no request DSS.

## H. ESCOPO

| Verificação | Resultado |
|-------------|-----------|
| `git diff -- api/` | **vazio** ✅ |
| `git diff -- ia/` | **vazio** ✅ |
| `git diff -- lib/` | **vazio** ✅ |
| `git diff --check` | limpo ✅ |
| `git status --short` | vazio (nenhum arquivo de código alterado) ✅ |
| Arquivo alterado/criado | **somente** `FASE_5D_REPORT.md` |

## I. FINAL

> **FASE 5D APROVADA.**

Validações concluídas:

- HTTP real Flutter → API;
- API → modelo;
- modelo → resposta;
- apresentação visual;
- fechamento via "Entendi";
- preservação do formulário;
- erro real de conexão;
- mensagem amigável;
- ausência de reapresentação de resultado antigo;
- ausência de retry automático;
- retry manual após religar a API;
- nova inferência após alteração de respostas.

**Reforço metodológico:** a Fase 5D valida **integração de software**, **NÃO**
desempenho clínico/preditivo do modelo.

**NÃO foi feito commit** (conforme instrução).
