# Relatório FASE 5B — Integração do Fluxo Real do Formulário com a API de Estimativa

> Resultado da verificação item a item do escopo da FASE 5B, **após a auditoria
> do fluxo real do formulário**. Estado final:
> **`flutter analyze` sem issues, `flutter test` 172/172 (164 + 8 novos),
> nenhuma alteração em `api/` ou `ia/`, nenhum commit.** A fase está
> **CONCLUÍDA** e **AGUARDANDO REVISÃO** (regra de parada).

A FASE 5B conecta o botão **"Confirmar e Enviar"** do questionário à chamada
real de `POST /api/v1/risk-estimate`, usando a arquitetura
Controller → Repository já existente. O resultado é armazenado em estado (MobX)
para a FASE 5C; **nenhuma apresentação visual da probabilidade** foi criada.

---

## 0. Auditoria do fluxo real (pré-implementação)

| # | Item | Situação |
|---|------|----------|
| 1 | Auditoria do fluxo real feita **antes** de implementar (`FormularioPage` → botão "Confirmar e Enviar" → `controller.enviarFormulario`) | ✅ CONFORME |
| 2 | **Não** criado um segundo controller — `FormularioController` existente foi adaptado | ✅ CONFORME |
| 3 | Adaptado à arquitetura **real** (Controller → Repository direto; `login` é o único caso com Service, por persistir token) | ✅ CONFORME |
| 4 | **Não** criado Service artificial para o formulário | ✅ CONFORME |
| 5 | `RiskEstimateRepository` congelado da 5A reutilizado; **sem** reimplementar HTTP | ✅ CONFORME |

---

## 1. Arquitetura e injeção de dependências

| # | Item | Situação |
|---|------|----------|
| 6 | `FormularioController` injeta `RiskEstimateRepository` (construtor, `required`) | ✅ CONFORME |
| 7 | `FormularioModule` importa `CoreModule` (resolve o repositório exportado) | ✅ CONFORME |
| 8 | **Nenhuma** chamada `Dio` no controller/UI; **nenhum** import de `RiskEstimateRestClient` na UI/controller | ✅ CONFORME |
| 9 | `FormularioPage` usa `Observer` para reagir a `loading`/resultado (substitui `StatefulBuilder`) | ✅ CONFORME |
| 10 | Seis submodule controllers mantidos; `consolidatedData` preservado | ✅ CONFORME |

---

## 2. Estado MobX no `FormularioController`

| # | Item | Situação |
|---|------|----------|
| 11 | `status` reutiliza o `PageStatus` existente (`initial/loading/success/error`) | ✅ CONFORME |
| 12 | `riskEstimate` tipado como `RiskEstimateResponseModel?` (**não** apenas `double`) | ✅ CONFORME |
| 13 | `error` tipado como `String?` (mensagem amigável) | ✅ CONFORME |
| 14 | `loading` como `@computed` (`status == PageStatus.loading`) — retrocompatibilidade da UI | ✅ CONFORME |
| 15 | `setLoading(bool)` removido (estado derivado de `status`) | ✅ CONFORME |
| 16 | Mecanismo de estado existente reutilizado (`PageStatus`), **sem** novo mecanismo | ✅ CONFORME |
| 17 | Codegen regenerado via `build_runner` (`.g.dart` com `status`/`riskEstimate`/`error`/`enviarFormularioAsyncAction`) | ✅ CONFORME |

---

## 3. Submissão (`enviarFormulario`)

| # | Item | Situação |
|---|------|----------|
| 18 | `enviarFormulario` retorna `Future<void>` (não o antigo `bool` fake) | ✅ CONFORME |
| 19 | Bloqueia submissão concorrente (`if (loading) return;`) | ✅ CONFORME |
| 20 | Define `status = PageStatus.loading` no início | ✅ CONFORME |
| 21 | Limpa o erro anterior (`error = null`) antes de nova submissão | ✅ CONFORME |
| 22 | Usa `consolidatedData` (`FormularioData` atual) como corpo | ✅ CONFORME |
| 23 | Chama `estimate` **exatamente uma vez** | ✅ CONFORME |
| 24 | Sucesso → armazena `riskEstimate` e `status = success` | ✅ CONFORME |
| 25 | Falha → armazena `error` e `status = error` | ✅ CONFORME |
| 26 | Sai do `loading` em todos os caminhos (sem loading preso) | ✅ CONFORME |
| 27 | **Sem** `catch (Exception)` indiscriminado — usa `switch` sobre `Result` | ✅ CONFORME |

---

## 4. Semântica de resultado

| # | Item | Situação |
|---|------|----------|
| 28 | Sucesso armazena a **resposta completa** (target/probability/model/notice) para a 5C | ✅ CONFORME |
| 29 | **Sem** navegação/dialog de resultado no controller | ✅ CONFORME |
| 30 | **Sem** classificação (baixo/médio/alto) | ✅ CONFORME |
| 31 | **Sem** threshold — `>= 0.5`, `> 0.5`, `riskLevel`, `highRisk`, `lowRisk`, `abandona` **ausentes** | ✅ CONFORME |
| 32 | `notice` **preservada** sem interpretação | ✅ CONFORME |
| 33 | Falha exposta como `Failure.message` / `PageStatus.error` — **nunca** `DioException`, stack, `response.data` ou status bruto | ✅ CONFORME |

---

## 5. Restrições de escopo (o que **NÃO** foi feito)

| # | Item | Situação |
|---|------|----------|
| 34 | **Não** reimplementado HTTP | ✅ CONFORME |
| 35 | **Não** chamado `Dio` diretamente do controller | ✅ CONFORME |
| 36 | **Não** importado `RiskEstimateRestClient` na UI/controller | ✅ CONFORME |
| 37 | **Não** reconstruído `FormularioData` (`toMap`/`toFlatMap` intactos) | ✅ CONFORME |
| 38 | **Não** usado `toFlatMap()` para HTTP (corpo = `toMap()`) | ✅ CONFORME |
| 39 | **Sem** retry automático / fila; retry explícito permitido | ✅ CONFORME |
| 40 | **Sem** persistência (SQLite/SharedPreferences/arquivo/storage) | ✅ CONFORME |
| 41 | **Sem** alterar a gestão pré-natal | ✅ CONFORME |
| 42 | **Sem** `gestanteId`/`userId`/`login`/`token` no request DSS | ✅ CONFORME |
| 43 | **Sem** exigir login para finalizar o formulário | ✅ CONFORME |
| 44 | **Sem** `UserRepository`/`AuthInterceptor` | ✅ CONFORME |
| 45 | **Sem** novas dependências (`pubspec.yaml` inalterado) | ✅ CONFORME |

---

## 6. Testes (`test/formulario/controllers/formulario_controller_test.dart`)

| # | Item | Situação |
|---|------|----------|
| 46 | Estado inicial (idle, sem resultado, sem erro, sem loading) | ✅ CONFORME |
| 47 | Loading (via `Completer`; encerra ao concluir) | ✅ CONFORME |
| 48 | Sucesso com `probability 0.321987654321` **preservada** sem arredondamento | ✅ CONFORME |
| 49 | Resposta completa preservada (target/name/schemaVersion/rawFeatureCount/transformedFeatureCount/notice) | ✅ CONFORME |
| 50 | Falha (mensagem amigável, sem resultado, loading encerrado) | ✅ CONFORME |
| 51 | Duplo envio (segunda chamada ignorada, `callCount == 1`) | ✅ CONFORME |
| 52 | Retry explícito após erro (`callCount == 2`, erro limpo, sucesso) | ✅ CONFORME |
| 53 | Sem retry automático (`callCount == 1` após falha) | ✅ CONFORME |
| 54 | Entrega `FormularioData` (não `toFlatMap`) ao repositório | ✅ CONFORME |
| 55 | `FormularioData` sintético via submodule controllers; **sem** API real; determinístico | ✅ CONFORME |

---

## 7. Documentação e verificação final

| # | Item | Situação |
|---|------|----------|
| 56 | `FLUTTER_API_INTEGRATION.md` atualizado (fluxo conectado, resultado em estado, visual deferido para 5C) | ✅ CONFORME |
| 57 | `FASE_5B_REPORT.md` criado | ✅ CONFORME |
| 58 | `FASE_5A_REPORT.md` **não** alterado | ✅ CONFORME |
| 59 | `dart format` aplicado **apenas** nos arquivos alterados | ✅ CONFORME |
| 60 | `flutter analyze` — `No issues found!` | ✅ CONFORME |
| 61 | `flutter test` — **172/172** (164 existentes + 8 novos) | ✅ CONFORME |
| 62 | `git diff -- api/` e `git diff -- ia/` **vazios** | ✅ CONFORME |
| 63 | `git diff --check` limpo; `git status` apenas Flutter/test/docs | ✅ CONFORME |

---

## Confirmações finais

- **Fluxo real conectado:** `FormularioPage` → `FormularioController` →
  `RiskEstimateRepository` → `POST /api/v1/risk-estimate`, na arquitetura real
  (Controller → Repository, **sem** Service).
- **Resultado tipado preservado:** `RiskEstimateResponseModel? riskEstimate`
  mantém `target`/`probability`/`model`/`notice` para a FASE 5C — **não** um
  simples `double` nem qualquer classificação/threshold.
- **Sem vazamento de erro:** a UI nunca recebe `DioException`/stack/status bruto;
  apenas `Failure.message` amigável.
- **Proteção contra duplo envio:** botão desabilitado + guarda `if (loading) return`;
  uma submissão = uma requisição (testado).
- **Sem retry automático, sem persistência, sem login, sem token, sem novas
  dependências.**
- **Arquivos protegidos:** NENHUMA alteração em `api/` ou `ia/`; `toMap`/`toFlatMap`/
  `FormularioData` intactos.
- **Commit:** NÃO realizado (conforme instrução).

---

## Estado

> **FASE 5B CONCLUÍDA. PARAR E AGUARDAR REVISÃO.**
