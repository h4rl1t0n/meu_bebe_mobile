# FASE 8D-PLAN — Plano técnico do núcleo de domínio (GESTANTE + GESTAÇÃO)

> **Natureza:** fase exclusivamente de **auditoria + planejamento**. Nenhuma
> dependência foi instalada, nenhum arquivo de código foi alterado, nenhum model,
> repository, service, endpoint, contrato ou migration foi criado. Este documento
> registra o estado **real** auditado (backend `api/` e módulos Flutter
> `lib/app/`) e propõe a implementação futura de **GESTANTE** (perfil pessoal) e
> **GESTAÇÃO** (episódio gestacional) para a **FASE 8D-IMP**.
>
> **Abreviações de veredito** usadas ao longo do texto:
> - **DECIDIDO** — definido nesta fase (a 8D-IMP não deve reabrir).
> - **RECOMENDADO** — recomendação técnica com justificativa; a 8D-IMP pode
>   adotar diretamente, salvo objeção registrada.
> - **EM ABERTO** — ponto deliberadamente adiado, com decisão de contorno
>   registrada para não bloquear.
> - **FORA DO ESCOPO** — explicitamente excluído desta fase.

---

## 1. Objetivo, natureza, escopo e prioridades

**Objetivo.** Preparar, de forma documental, a **primeira implementação do
núcleo de domínio** do acompanhamento pré-natal no backend FastAPI, criando as
duas primeiras entidades persistentes de domínio — **GESTANTE** (perfil pessoal)
e **GESTAÇÃO** (episódio gestacional) — sobre a infraestrutura de persistência
(FASE 8B) e a identidade/autenticação (FASE 8C) já implementadas. O plano deve
ser preciso o suficiente para que a **FASE 8D-IMP** execute sem decisões
arquiteturais improvisadas.

**Natureza.** Fase de **auditoria + planejamento**. Nada é implementado, nada é
alterado, nada é commitado. A única entrega é este documento
(`docs/GESTANTE_GESTACAO_PLAN.md`).

**Escopo incluído (planejamento).**

- Auditoria do estado real do backend (auth/db persistidos) e do modelo Flutter
  (`pregnant`, `current_pregnancy`, `user`, cálculo de IG/DPP, local/profissional
  do pré-natal).
- Definição dos modelos `GESTANTE` e `GESTAÇÃO` (campos, tipos, cardinalidades,
  ownership).
- Decisão de CPF/CNS e do mecanismo de "gestação atual".
- Regra para impedir duas gestações ativas simultâneas.
- Fluxo de onboarding futuro (CRIAR CONTA: acesso → pessoais → gestação).
- Especificação de endpoints mínimos de `GESTANTE` e `GESTAÇÃO`.
- Dependência `get_current_gestante` e autorização por ownership.
- Validações mínimas; IG/DPP como derivados não persistidos.
- Primeira migration de domínio (0002: `gestantes` + `gestacoes`).
- Contratos Pydantic, repositories/services, transações, erros, matriz de testes.
- Guardas de privacidade/DSS/SQLite e impacto acadêmico.

**Explicitamente excluído desta fase (implementação e planejamento detalhado).**

- `HISTORICO_OBSTETRICO` (FASE 8E) e qualquer dado obstétrico agregado.
- `CONSULTA`, `EXAME`, `MEDICACAO`, `VACINA`, `PLANO_DE_PARTO`, `AVALIACAO_DSS`
  (FASES 8E–8I).
- Alterar o contrato DSS congelado (`POST /api/v1/risk-estimate`).
- Alterar qualquer código de `api/`, `lib/`, `ia/`, `test/` ou documento
  existente.
- Integração Flutter (consumo real dos novos endpoints) — fase posterior.
- Migrar/sincronizar o SQLite legado do Flutter.

### 1.1 Prioridades do projeto (anti-overengineering)

**DECIDIDO.** A complexidade adotada é **proporcional à finalidade do TCC**
(mesma prioridade congelada nas 8B/8C):

1. funcionamento correto;
2. organização suficiente;
3. demonstração clara (para a banca);
4. manutenção simples;
5. segurança essencial;
6. integração com o restante do sistema;
7. compatibilidade com o cronograma.

Não são introduzidos: DDD, CQRS, event sourcing, Redis, mensageria, RBAC, soft
delete genérico, audit trail, generic repository ou mapper framework. O foco
científico do TCC continua sendo DSS → Flutter → API → ML → estimativa
experimental.

---

## 2. Estado atual auditado (respostas A–H)

Fatos **verificados** no repositório (não assumidos).

### 2.1 Backend (verificado)

| Item | Valor auditado |
|---|---|
| Entidades ORM persistentes | **2** — `User` (`users`) e `AuthRefreshSession` (`auth_refresh_sessions`), da 8C-IMP |
| Migration atual | **0001** (`create_users_and_auth_refresh_sessions`); `alembic/versions/` não tem 0002 |
| Modelos de domínio (`GESTANTE`/`GESTAÇÃO`) | **Inexistentes** — não há `models/gestante*.py` nem `models/gestacao*.py` |
| Repositories de domínio | **Inexistentes** — só `user_repository` e `auth_refresh_session_repository` |
| Endpoints de domínio | **Inexistentes** — só `/api/v1/auth/*` e `/api/v1/risk-estimate` |
| Arquitetura em camadas | Router → Service (commit/rollback) → Repository (sem commit) → `Session` síncrona → PostgreSQL |
| Session factory | `autoflush=False`, `expire_on_commit=False`, uma `Session` por request |
| UUID | v4 gerado no **Python** (`uuid.uuid4()` como `default=`), nunca `gen_random_uuid()` |
| Timestamps | `created_at`/`updated_at` `TIMESTAMPTZ` UTC (via `_common.utc_now`) |
| Envelope de erro | `{code, message, details}` (<500) e `{"error": {...}}` (>=500); `ErrorResponse`/`ErrorDetail` |
| Auth | `get_current_user` resolve `USER` a partir do access token (`type=access`), valida `is_active` |
| DSS | `POST /api/v1/risk-estimate` **stateless, sem auth, sem banco, sem persistência** |

### 2.2 Flutter (verificado — somente leitura; NÃO alterar)

| Item | Valor auditado |
|---|---|
| `PregnantData` → `pregnant` | `id` (int), `name`, `birthDate`, `cpf`, `socialName`, `nationalHealthCard`, `prenatalPlace`, `professionalName`, `prenatalPlaceContact` — **mistura pessoa + logística do pré-natal** |
| `CurrentPregnancyData` → `current_pregnancy` | `id` (int), `lastMenstrualPeriod`, `firstUltrasound`, `createdAt` — **registro único**, sem vínculo |
| `UserData` → `user` | `id` (int), `name`, `email`, `phone` — **sem senha**; `name` é fonte redundante do nome |
| `PreviousPregnancy` → `previous_pregnancy` | GPA (3 contadores) — **não** é gestação individual |
| Cálculo de IG/DPP | Derivados **em exibição** no `PregnantCard`: IG = `now − DUM` (semanas+dias); DPP = `DUM + 280 dias`. **Não persistidos.** |
| "Gestação atual" | Tabela de registro único `current_pregnancy` lida com `limit:1`; a UI assume "1 dispositivo = 1 gestação" |
| Vínculo/ownership | **Nenhum** — não há `FOREIGN KEY` em nenhuma das 13 tabelas; `PRAGMA foreign_keys=ON` sem efeito |
| Datas | `String dd/MM/yyyy`; enums por ordinal; booleanos `0/1`; `created_at` emitido `null` no insert |
| Bugs de ID (registrados na 8A) | `CurrentGestationPage` e `HistoryPage` montam `id:1` → primeira gravação faz `UPDATE` em linha inexistente e **perde dados**; sentinel `id==0` frágil |

### 2.3 Respostas às 8 perguntas de auditoria (A–H)

| # | Pergunta | Resposta (verificada) |
|---|---|---|
| **A** | A API possui entidades de domínio persistentes além de `USER`/sessão? | **Não.** Apenas `users` e `auth_refresh_sessions` (8C). `GESTANTE`/`GESTAÇÃO` não existem. |
| **B** | O Flutter persiste dados de gestante/gestação? Onde e com que modelo? | **Sim**, em SQLite: `pregnant` (pessoa + logística), `current_pregnancy` (DUM + 1ª USG), `user` (identidade sem senha), `previous_pregnancy` (GPA). Sem FK, sem vínculo. |
| **C** | Existe separação identidade (`USER`) × perfil (`GESTANTE`) hoje? | **No backend, parcial** (8C criou `USER` de identidade pura). **No Flutter, não** — `UserData` mistura nome/email/telefone; `PregnantData` mistura pessoa + logística. |
| **D** | Como o Flutter calcula IG e DPP? | **Derivadas em exibição** de `lastMenstrualPeriod` (IG = dias/7; DPP = DUM + 280). Nunca persistidas. |
| **E** | Existe mecanismo de "gestação atual"? | **Sim, implícito** — tabela de registro único `current_pregnancy` (`limit:1`), com o bug de `id:1`. |
| **F** | Há vínculo de ownership entre usuário/gestante/gestação? | **Não.** Nenhuma `FOREIGN KEY`; modelo implicitamente monousuário. |
| **G** | Onde ficam local/profissional do pré-natal? | **Em `PregnantData`** (misturados aos dados pessoais), não na gestação. |
| **H** | Há validação clínica/obstétrica ou DPP manual? | **Não.** Só DUM + 1ª USG; IG/DPP automáticas; sem diagnóstico pela data; sem DPP manual. |

**Conclusão:** a 8D-IMP nasce sobre `USER` (identidade, 8C) e infraestrutura de
persistência (8B) já prontas; o domínio `GESTANTE`/`GESTAÇÃO` precisa ser criado
do zero, separando **pessoa** de **logística do pré-natal** e adicionando
**ownership** (FKs reais) — exatamente o que a FASE 8A §4.2–4.3 e §5 já prescreve.

---

## 3. Regras congeladas e invariantes de domínio

**DECIDIDO** (herdado das 8A/8C; não reabrir).

- **USER = identidade/autenticação** (conta de acesso: e-mail, senha, atividade).
- **GESTANTE = perfil pessoal** (pessoa física).
- **GESTAÇÃO = episódio gestacional** (evento com início/fim próprio).
- **Nunca** misturar e-mail/senha com dados pessoais/obstétricos: nada de nome,
  CPF, CNS, nascimento ou dado obstétrico em `USER`; nada de e-mail/senha/token
  em `GESTANTE`/`GESTAÇÃO`.
- **`USER 1—1 GESTANTE`** (chave estrangeira única `gestantes.user_id`).
- **`GESTANTE 1—N GESTAÇÃO`** (chave estrangeira `gestacoes.gestante_id`).
- **Não** aceitar `user_id`/`gestante_id` vindos livremente do cliente: a
  identidade é sempre resolvida pelo access token; a gestante pelo caminho
  `USER → GESTANTE`; a gestação pelo caminho `GESTANTE → GESTAÇÃO`.
- Trata-se de **controle de propriedade/autorização**, **não** "multi-tenancy".

---

## 4. Modelo de domínio e cardinalidades

**DECIDIDO.** Subconjunto da arquitetura 8A §4, limitado ao que esta fase
implementa:

```
USER 1─1 GESTANTE
GESTANTE 1─N GESTACAO
```

- As demais entidades (`HISTORICO_OBSTETRICO`, `CONSULTA`, `EXAME`, `MEDICACAO`,
  `VACINA`, `PLANO_DE_PARTO`, `AVALIACAO_DSS`) são **FORA DO ESCOPO** desta fase
  (8E–8I) e **não** são criadas agora.
- A regra de ownership dos filhos da gestação (`entidade → GESTAÇÃO → GESTANTE →
  USER`, sem duplicar `gestante_id`/`user_id`) já fica registrada, mas só é
  **aplicada** quando esses filhos forem criados.

---

## 5. GESTANTE — campos e decisões

**DECIDIDO.** `GESTANTE` representa **perfil pessoal** (pessoa), e nada além. A
origem Flutter é `PregnantData`, mas **somente** os campos de pessoa; os campos
de logística migram para `GESTAÇÃO` (seção 7).

Tabela de decisão por campo (as colunas respondem: existe hoje? é exibido? é
editável? é necessário? pertence a quem? obrigatório? UNIQUE? opcional?):

| Campo | Origem atual | Pertence | Obrigatório | UNIQUE | Decisão 8D |
|---|---|---|---|---|---|
| `id` | — (novo) | `GESTANTE` | sim (PK) | sim (PK) | UUID v4, gerado no **servidor** (Python) |
| `user_id` | — (novo) | `GESTANTE` | sim | **sim** (`uq_gestantes_user_id`) | FK → `users.id` `ON DELETE CASCADE`; resolve o ownership 1—1 |
| `nome` | `PregnantData.name` | `GESTANTE` | **sim** | não | `NOT NULL`; fonte de verdade do nome pessoal |
| `nome_social` | `PregnantData.socialName` | `GESTANTE` | não | não | opcional (nullable) |
| `data_nascimento` | `PregnantData.birthDate` | `GESTANTE` | **sim** | não | `DATE NOT NULL`; validação "não futura" (seção 16) |
| `cpf` | `PregnantData.cpf` | `GESTANTE` | não | **não** | opcional; ver seção 6 |
| `cns` | `PregnantData.nationalHealthCard` | `GESTANTE` | não | **não** | opcional; ver seção 6 |
| `telefone` | `UserData.phone` (legado morto — ver abaixo) | — | — | — | **NÃO incluir** (evidência abaixo) |
| `created_at` / `updated_at` | — (novo) | infra | sim | não | `TIMESTAMPTZ` UTC, servidor |

**`telefone` — NÃO incluir em `GESTANTE` (DECIDIDO).** Evidência reauditada:
- `UserData.phone` **existe** no model (`lib/app/model/user_data.dart`) e no
  banco SQLite (`user.phone TEXT`), porém é **código morto/legado**: **não** há
  `phoneEC`/`telefoneEC` no `profile_form_controller.dart` (controllers: nome,
  nome social, nascimento, CPF, CNS, local pré-natal, e-mail, estado civil,
  renda, escolaridade — **nenhum de telefone**); **não** é exibido em nenhuma
  tela; e em `profile_data_page.dart` é apenas repassado (`phone:
  controller.user?.phone`), sempre `null`. Ou seja: **existe no schema mas nunca
  é coletado, editado nem exibido**.
- O único telefone **realmente funcional** no app é
  `PregnantData.prenatalPlaceContact` — rotulado "Contato do local" / "Telefone"
  nas telas de Identificação e Pré-natal — que é **telefone do local do
  pré-natal** (logística), e **não** telefone pessoal da gestante. Esse campo
  migra para `GESTAÇÃO` como `contato_local_pre_natal` (seção 7).

**Conclusão:** não há "telefone pessoal" real para promover a `GESTANTE`. Incluí-
lo seria **inventar** um campo sem consumidor, contrariando o anti-overengineering.
Portanto: **telefone pessoal FORA do `GESTANTE`**; `USER` mantém somente
identidade (sem duplicar telefone). (Se o produto um dia exigir telefone pessoal,
entra como campo opcional em `GESTANTE`, numa migration posterior.)

**Proibido incluir em `GESTANTE` (DECIDIDO):** e-mail, senha, `password_hash`,
token, `is_active`, local/profissional/contato do pré-natal, e qualquer dado
obstétrico — esses pertencem a `USER` (identidade) ou `GESTAÇÃO` (logística/
episódio), nunca à gestante.

---

## 6. CPF e CNS

**DECIDIDO.**

- **CPF não é PK, não é login, não é credencial.** A chave primária é `UUID`; o
  login é `e-mail + senha` (8C). CPF é **dado de perfil**, opcional.
- **Unicidade (`UNIQUE`) de CPF: NÃO aplicar** nesta fase. Não há regra de
  produto que a exija; impor unicidade criaria uma superfície de `409` sem
  benefício para o TCC (a mesma gestante real poderia querer se recadastrar em
  outro `USER`, e o CPF é opcional). Se a regra de produto mudar, adicionar
  `UNIQUE` numa migration posterior — decisão **EM ABERTO**, sem bloqueio.
- **Formato/armazenamento:** armazenar **somente dígitos** (`VARCHAR(11)`),
  sem máscara. Normalizar no service (`strip` + remover não-dígitos). Validação
  mínima: **se informado, deve ter exatamente 11 dígitos**. **NÃO** validar
  dígito verificador (check-digit) — é validação "exagerada" sem ganho para o
  TCC e não agrega à demonstração.
- **CNS (Cartão Nacional de Saúde):** manter como **opcional**, `VARCHAR(15)`,
  dígitos apenas. Validação mínima: **se informado, 15 dígitos**. Necessidade
  real avaliada: o Flutter já coleta o campo (opcional), então preserva-se como
  dado de perfil; **sem** validação clínica, **sem** uso como identificador.
- **Privacidade (seção 24):** CPF/CNS são dados pessoais sensíveis; **nunca**
  logar o valor completo nem o corpo de requisição que os contenha.

---

## 7. GESTAÇÃO — campos e decisões

**DECIDIDO.** `GESTAÇÃO` representa o **episódio gestacional** com identidade
própria (`UUID`), vinculado a `GESTANTE` por `gestante_id`. A origem Flutter é a
junção de `CurrentPregnancyData` (somente o **DUM**) com a parte de **logística**
de `PregnantData` (`prenatalPlace`, `professionalName`, `prenatalPlaceContact`).

| Campo | Origem atual | Tipo | Obrigatório | Decisão 8D |
|---|---|---|---|---|
| `id` | — (novo) | UUID | sim (PK) | UUID v4 servidor |
| `gestante_id` | — (novo) | UUID | sim | FK → `gestantes.id` `ON DELETE CASCADE`, indexado |
| `data_ultima_menstruacao` (DUM) | `CurrentPregnancyData.lastMenstrualPeriod` | `DATE` | não | nullable; base de IG/DPP (seção 8) |
| `local_pre_natal` | `PregnantData.prenatalPlace` | `VARCHAR(255)` | não | nullable; logística do pré-natal |
| `profissional_pre_natal` | `PregnantData.professionalName` | `VARCHAR(255)` | não | nullable |
| `contato_local_pre_natal` | `PregnantData.prenatalPlaceContact` | `VARCHAR(64)` | não | **DECIDIDO** incluir (nullable) — campo real e utilizado (evidência abaixo) |
| `ended_at` | — (novo) | `TIMESTAMPTZ` | não | nullable; **mecanismo de estado** (seção 9) |
| `created_at` / `updated_at` | — (novo) | `TIMESTAMPTZ` | sim | UTC, servidor |

**`data_primeira_ultrassom` — FORA DO ESCOPO (FASE 8F).** Reauditado: o campo
`CurrentPregnancyData.firstUltrasound` é **coletado** (tela "Gestação atual"),
**exibido** ("Data do ultrassom" no card) e **persistido** (`first_ultrasound
TEXT`), **mas não participa do cálculo de IG/DPP** (o Flutter só usa
`lastMenstrualPeriod`). Trata-se, conceitualmente, de um **exame** — pertence ao
futuro domínio `EXAME` (FASE 8F), **não** ao episódio gestacional. Mantê-lo em
`GESTAÇÃO` criaria **duas fontes de verdade** para a mesma informação quando
`EXAME` for criado. Portanto, **NÃO** entra em `GESTAÇÃO` nesta fase; será tratado
na FASE 8F (registro de exames), com migração do valor legado quando apropriado.

**`contato_local_pre_natal` — DECIDIDO incluir (nullable).** Evidência reauditada:
o campo é **real e utilizado** no Flutter — exibido ("Contato do local" em
`pregnant_card.dart`; "Telefone" em `identification_card.dart`), **editável**
(campo "Contato do local" em `identification_page.dart`, com `TelefoneInputFormatter`)
e **persistido** (`pregnant_place_contact`/`prenatal_place_contact TEXT`). É
**telefone do local do pré-natal** (logística), distinto do telefone pessoal
(seção 5). Por ser dado real consumido pela UI, é mantido como **opcional** em
`GESTAÇÃO` — não é campo especulativo.

**`data_provavel_parto` (DPP) — NÃO persistir (DECIDIDO).** É **derivado** de
DUM + 280 dias (seção 8). Não há campo persistido de DPP.

**`maternidade_referencia` distinto de `local_pre_natal` — FORA DO ESCOPO.** A
UI atual reusa `prenatalPlace` sob dois rótulos ("Local que realiza o pré-natal"
e "Maternidade de referência"), mas é **um único** dado. A separação
`local_pre_natal` × `maternidade_referencia` (prescrita na 8A §4.3) é adiada;
nesta fase há apenas `local_pre_natal`.

---

## 8. IG e DPP (derivados, não persistidos)

**DECIDIDO.**

- **Persistir apenas `data_ultima_menstruacao` (DUM).** IG e DPP são **derivados
  calculados**, nunca armazenados como colunas (coerente com 8A §10.1 e com o
  Flutter, que já os calcula em exibição).
- **IG** (idade gestacional) = `now − DUM` em dias → semanas + dias.
- **DPP** (data provável do parto) = `DUM + 280 dias`.
- **Quando DUM ausente** (`NULL`), IG e DPP são **indeterminados** — a API não
  retorna valores inventados (não diagnostica a gestação pela data).
- **DPP manual:** o Flutter atual **não** coleta DPP manual (só DUM; a 1ª USG é
  tratada na FASE 8F — seção 7), portanto **não** há campo de "diferença/override
  de DPP". **FORA DO ESCOPO.** Se um dia o produto permitir informar DPP
  manualmente, adiciona-se um campo opcional `data_provavel_parto_manual` (e
  registra-se a diferença) numa migration posterior — não agora.
- **Onde calcular:** **DECIDIDO** — IG/DPP **não** são persistidos **nem** expostos
  na resposta da 8D (campos derivados ficam **fora do contrato** no primeiro
  corte). O Flutter já calcula em exibição a partir de DUM; a API mantém o
  contrato mínimo. Se futuramente a API expuser derivados, devem ser campos
  somente-leitura rotulados como "estimados", nunca diagnóstico — decisão futura.

---

## 9. Gestação atual — mecanismo mais simples

**DECIDIDO — `ended_at TIMESTAMPTZ NULL`.**

- **"Gestação ativa"** = `ended_at IS NULL`.
- **"Gestação concluída"** = `ended_at IS NOT NULL`.
- **"Qual é a gestação atual?"** = a gestação do usuário autenticado cujo
  `ended_at IS NULL` (no máximo uma, garantido pela seção 10).

**Justificativa (solução MAIS simples, sem state machine):**

1. Uma única coluna nullable — **sem** enum, **sem** string `status`, **sem**
   máquina de estados, **sem** coluna `completed_at` separada (a data de fim é a
   própria `ended_at`).
2. A consulta da "atual" é trivial (`WHERE gestante_id = ? AND ended_at IS NULL`).
3. Registrar a conclusão futura é só preencher `ended_at` (não exige mudança de
   schema).

**Como encerrar (DECIDIDO):** a conclusão de uma gestação é feita **pelo próprio
`PUT /gestacoes/{id}`** — o payload de escrita pode levar `ended_at` de `null`
para um `timestamp` (transição **ATIVA → ENCERRADA**). **Não** há endpoint
dedicado `/encerrar`, **não** há máquina de estados, **não** há coluna `status`
enum, e **não** há encerramento/reabertura automática. Não é um recurso separado:
é só um campo no contrato de escrita.

**Nota de escopo (DECIDIDO):** na 8D a escrita de `ended_at` é **opcional** e
todo `POST` nasce ativo (`ended_at = NULL`). A **capacidade de encerrar** (enviar
`ended_at` não-nulo via `PUT`) fica **disponível** na 8D porque o campo já existe
no contrato — sem custo adicional e sem migração posterior. A regra "uma única
ativa" (seção 10) continua valendo desde já.

**Reabertura (ENCERRADA → ATIVA) — PROIBIDA na 8D (DECIDIDO).** Uma vez que
`ended_at` é preenchido, **não** é permitido reverter para `NULL` (voltar a
"ativa") nesta fase. Isso mantém a semântica simples e irreversível (o término é
fato histórico) e evita reabertura acidental. Se o produto um dia exigir
reabertura (correção de erro), isso será um recurso explícito e deliberado numa
fase posterior — **não** um efeito colateral do `PUT`. O `PUT` pode **editar**
os demais campos de uma gestação encerrada, mas **não** reabri-la (não pode
voltar `ended_at` a `NULL`).

> Alternativas descartadas: `status VARCHAR('active'|'completed')` (exige
> enum/literal + validação, sem ganho) e state machine (overengineering).

---

## 10. Regra de "uma única gestação ativa"

**DECIDIDO.** Uma gestante **não** pode ter duas gestações com `ended_at IS NULL`
simultaneamente. Ao criar uma segunda gestação ativa, a API responde erro
**sem** encerrar automaticamente a anterior.

**Garantia em dois níveis (DECIDIDO):**

1. **Backstop no banco — índice único parcial** do PostgreSQL:
   `CREATE UNIQUE INDEX uq_gestacoes_active_per_gestante ON gestacoes
   (gestante_id) WHERE ended_at IS NULL;` — garante a invariante contra corrida
   (dois `POST` simultâneos) de forma barata e nativa. **DECIDIDO** (não é
   overengineering: é um único índice declarativo; mantém a integridade no lugar
   certo).
2. **Guarda no service** — antes de inserir, busca a gestação ativa existente;
   se houver, responde `409 ACTIVE_PREGNANCY_ALREADY_EXISTS` com mensagem
   amigável (o índice único serve de rede de segurança e dispara o mesmo 409 em
   caso de corrida via captura de `IntegrityError`).

**DECIDIDO — service + índice único parcial** (ambos, não um ou outro). O índice
é a fonte de verdade da invariante (imune a corrida); a guarda no service existe
para produzir a mensagem amigável de `409` sem depender do `IntegrityError`.
Não há decisão em aberto aqui.

---

## 11. Fluxo de onboarding (CRIAR CONTA)

**DECIDIDO (nota de arquitetura; NÃO implementar Flutter agora).**

O aplicativo final apresentará à usuária um único processo percebido como
**"Criar conta"**, composto por três etapas:

```
(1) DADOS DE ACESSO   POST /api/v1/auth/register  → USER + tokens
(2) DADOS PESSOAIS    POST /api/v1/gestantes/me   → GESTANTE (perfil)
(3) GESTAÇÃO          POST /api/v1/gestacoes      → GESTAÇÃO (episódio)
(4) ENTRAR            → tela principal (home/tabs)
```

- Internamente são **recursos distintos**, mas a UI pode encadeá-los numa única
  jornada.
- A ordem é rígida no backend por dependência de FK: **USER antes de GESTANTE**
  (gestante exige `user_id`), **GESTANTE antes de GESTAÇÃO** (gestação exige
  `gestante_id`).
- A etapa (3) é **opcional** no backend (uma gestante pode existir sem gestação),
  embora a jornada de onboarding a colete para o MVP.
- Esta seção **não** autoriza alteração de `lib/` na 8D-IMP; é apenas o contrato
  futuro (integração na fase 8J+).

---

## 12. Endpoints GESTANTE

**DECIDIDO — três rotas, todas sob `gestantes/me`.**

| Método | Path | Auth | Papel |
|---|---|---|---|
| `POST` | `/api/v1/gestantes/me` | access token | Cria o perfil `GESTANTE` do usuário autenticado |
| `GET` | `/api/v1/gestantes/me` | access token | Retorna o perfil `GESTANTE` |
| `PUT` | `/api/v1/gestantes/me` | access token | Atualiza o perfil (full update) |

**Decisões:**

- **`/me` é suficiente** (DECIDIDO): a gestante só acessa o próprio perfil; não
  há admin nem acesso a outra usuária. **NÃO** criar `GET /gestantes/{id}` nem
  qualquer rota com `{id}` de gestante — a identidade vem exclusivamente do
  token.
- **Criação idempotente controlada:** `POST` cria; se o `USER` já possui
  `GESTANTE` → `409 PROFILE_ALREADY_EXISTS` (seção 15). Não há upsert implícito.
- **`PUT` exige perfil existente** (`get_current_gestante` → `404
  PROFILE_NOT_FOUND` se ausente).
- `GET`/`PUT` retornam o `GESTANTE` do próprio usuário; **nunca** expõem
  `user_id` de outro `USER`, senha ou tokens.

---

## 13. Endpoints GESTAÇÃO

**DECIDIDO — cinco rotas.**

| Método | Path | Auth | Papel |
|---|---|---|---|
| `POST` | `/api/v1/gestacoes` | access token | Cria uma gestação (ativa) para a gestante autenticada |
| `GET` | `/api/v1/gestacoes` | access token | Lista as gestações da gestante (ordem por `created_at`) |
| `GET` | `/api/v1/gestacoes/atual` | access token | Retorna a gestação ativa (ou 404) |
| `GET` | `/api/v1/gestacoes/{gestacao_id}` | access token | Detalha uma gestação (ownership-checked) |
| `PUT` | `/api/v1/gestacoes/{gestacao_id}` | access token | Atualiza a gestação (full update, ownership-checked) |

**Decisões:**

- **`GET /gestacoes/atual`** (DECIDIDO): conveniência para o Flutter obter a
  gestação ativa sem filtrar a lista; `404 PREGNANCY_NOT_FOUND` se não houver
  ativa.
- **`GET /gestacoes/{id}`** e **`PUT /gestacoes/{id}`** (DECIDIDO): necessários
  para editar uma gestação específica (ex.: corrigir DUM/local) e para
  **concluir** (encerrar) a gestação via `ended_at` (seção 9); a autorização
  valida ownership (seção 14).
- **`DELETE /gestacoes/{id}`** — **FORA DO ESCOPO** (seção 18).
- **Não** criar sub-recursos (`consultas`, `exames`, etc.) — FASES 8E+.

---

## 14. Ownership e dependências

**DECIDIDO.** A autorização segue **somente** o caminho
`access token → USER → GESTANTE → GESTAÇÃO`. Nenhum `user_id`/`gestante_id` é
aceito do corpo da requisição.

### 14.1 Dependência `get_current_gestante`

```
get_current_user (8C) → USER autenticado (is_active)
        ↓
busca GESTANTE por user_id (gestante.user_id == user.id)
        ↓
se ausente → 404 PROFILE_NOT_FOUND
se presente → retorna GESTANTE
```

- Reutiliza `get_current_user` (já implementada); **não** duplica decodificação
  de token.
- É a dependência de todas as rotas de `gestantes/me` (GET/PUT) e de `gestacoes`
  (todas).

### 14.2 Ownership de gestação

- Para `GET/PUT /gestacoes/{id}`: carrega a `GESTAÇÃO` por `id`; **se não
  existir OU se `gestacao.gestante_id != gestante.id`** → `404 PREGNANCY_NOT_FOUND`
  (mensagem idêntica para "não existe" e "é de outra usuária" — **não revelar
  existência** de recurso alheio).
- **Não** usar `403` para ownership: `404` evita vazar existência (recomendação
  8A §6.7).
- **Nunca** confiar em `gestante_id`/`user_id` do request; o vínculo é sempre
  derivado do token.

---

## 15. Criação e conflitos

**DECIDIDO.**

### 15.1 Criação de GESTANTE (`POST /gestantes/me`)

1. `get_current_user` → `USER`.
2. Busca `GESTANTE` por `user_id`.
3. **Já existe** → `409 PROFILE_ALREADY_EXISTS`.
4. **Não existe** → cria `GESTANTE` (com `user_id = user.id`); `flush` para obter
   `id`; `commit`; retorna `201` com o `GestanteResponse`.

- A unicidade é garantida por `uq_gestantes_user_id` (backstop contra corrida:
  `IntegrityError` → `rollback` → `409 PROFILE_ALREADY_EXISTS`).

### 15.2 Criação de GESTAÇÃO (`POST /gestacoes`)

1. `get_current_gestante` → `GESTANTE` (ausente → `404 PROFILE_NOT_FOUND`).
2. Busca gestação ativa (`ended_at IS NULL`) da gestante.
3. **Já existe ativa** → `409 ACTIVE_PREGNANCY_ALREADY_EXISTS` (**sem**
   encerramento automático da anterior).
4. **Não existe ativa** → cria `GESTAÇÃO` (`gestante_id = gestante.id`,
   `ended_at = NULL`); `commit`; retorna `201`.

- Backstop: índice único parcial (seção 10) converte corrida em `409`.

---

## 16. Validações mínimas

**DECIDIDO** (sem exagero; sem validação clínica/obstétrica).

- `nome` obrigatório (não vazio/em branco) — Pydantic `min_length=1` + `strip`.
- `data_nascimento` **não futura** (rejeita `> hoje`). **Sem** validação de idade
  mínima/máxima, **sem** faixa etária gestacional.
- `data_ultima_menstruacao` **não futura**. **Sem** inferência de duração, **sem**
  "diagnosticar gestação pela data" (a 1ª USG é tratada na FASE 8F — seção 7).
- `cpf`: se informado, **11 dígitos** (sem check-digit).
- `cns`: se informado, **15 dígitos**.
- `telefone`: **não existe** nesta fase (seção 5) — **sem regex de telefone**.
- Datas em **ISO 8601** (`YYYY-MM-DD`), nunca `dd/MM/yyyy`.
- **Não** validar nada de obstetrícia/GPA/plano de parto (fora do escopo).

---

## 17. Migration 0002 (gestantes + gestacoes)

**DECIDIDO (schema real; NÃO criar o revision nesta fase).**
`down_revision = "0001"`.

### 17.1 Tabela `gestantes`

| Coluna | Tipo PostgreSQL | Constraints/defaults |
|---|---|---|
| `id` | `UUID` | PK `pk_gestantes`; default servidor (`uuid.uuid4()`) |
| `user_id` | `UUID` | `NOT NULL`, `UNIQUE` → `uq_gestantes_user_id`, FK `fk_gestantes_user_id_users` → `users.id` `ON DELETE CASCADE` |
| `nome` | `VARCHAR(255)` | `NOT NULL` |
| `nome_social` | `VARCHAR(255)` | `NULL` |
| `data_nascimento` | `DATE` | `NOT NULL` |
| `cpf` | `VARCHAR(11)` | `NULL` |
| `cns` | `VARCHAR(15)` | `NULL` |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, default `now()` UTC |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, default `now()` UTC + `onupdate` |

### 17.2 Tabela `gestacoes`

| Coluna | Tipo PostgreSQL | Constraints/defaults |
|---|---|---|
| `id` | `UUID` | PK `pk_gestacoes`; default servidor |
| `gestante_id` | `UUID` | `NOT NULL`, FK `fk_gestacoes_gestante_id_gestantes` → `gestantes.id` `ON DELETE CASCADE` |
| `data_ultima_menstruacao` | `DATE` | `NULL` |
| `local_pre_natal` | `VARCHAR(255)` | `NULL` |
| `profissional_pre_natal` | `VARCHAR(255)` | `NULL` |
| `contato_local_pre_natal` | `VARCHAR(64)` | `NULL` |
| `ended_at` | `TIMESTAMPTZ` | `NULL` (`NULL` = ativa) |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, default `now()` UTC |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, default `now()` UTC + `onupdate` |

### 17.3 Índices

- `ix_gestacoes_gestante_id` — lookup por gestante (listagem).
- `uq_gestacoes_active_per_gestante` — **índice único parcial**
  `(gestante_id) WHERE ended_at IS NULL` (seção 10).

### 17.4 Regras de migration

- UUID v4 **Python** (`uuid.uuid4()` default), nunca `gen_random_uuid()`.
- Timestamps **UTC** (`DateTime(timezone=True)`).
- `upgrade()`: cria `gestantes` e depois `gestacoes` (ordem respeita a FK).
- `downgrade()`: drop em ordem inversa.
- Nomes de constraints vêm da `naming_convention` única de `Base.metadata`.
- Revisar o revision manualmente antes de `alembic upgrade head` (política 8B).
- **NÃO criar migration nesta fase** (proibido).

### 17.5 Tipos de data congelados (DECIDIDO)

- `GESTANTE.data_nascimento` → **`DATE`**.
- `GESTAÇÃO.data_ultima_menstruacao` → **`DATE`**.
- `GESTAÇÃO.ended_at` → **`TIMESTAMPTZ`** (instante de encerramento).
- `created_at` / `updated_at` (ambas as tabelas) → **`TIMESTAMPTZ`** UTC.
- **DPP e IG não são persistidos** (derivados de DUM — seção 8); não há coluna de
  data para eles.

---

## 18. Delete e soft delete

**DECIDIDO.**

- **NÃO implementar `DELETE`** de `GESTANTE` nem de `GESTAÇÃO` nesta fase — não
  há requisito real de exclusão no MVP (evita perda acidental, coerente com 8A).
- **NÃO soft delete.** As colunas são deletadas fisicamente **somente** via
  `ON DELETE CASCADE` quando o `USER` raiz for removido (não há rota para isso
  no MVP) — o `CASCADE` é integridade referencial, **não** um recurso de produto.
- Sem colunas `deleted_at`, sem `is_deleted`, sem "arquivar". A conclusão de uma
  gestação é **semântica** (`ended_at`), não exclusão.

---

## 19. PUT vs PATCH

**DECIDIDO — PUT (full update).**

**Justificativa:**

1. **Uma única semântica simples:** o cliente envia o objeto completo de
   escrita; a API substitui os campos editáveis. Sem ambiguidade "campo ausente
   vs `null`" (que o PATCH exigiria).
2. **Objetos pequenos:** `GESTANTE` e `GESTAÇÃO` têm poucos campos; o Flutter
   sempre carrega o objeto inteiro (via `GET`) antes de editar e o reenvia.
3. **Menos contrato:** um único payload de escrita por entidade (seção 20), sem
   lógica de *merge* parcial.
4. **Consistência com o Flutter atual:** os forms já fazem `copyWith` do modelo
   completo e salvam integralmente.

> PATCH (partial) só se justificaria se houvesse campos pesados/editados
> independentemente; não é o caso. **FORA DO ESCOPO.**

---

## 20. Contratos Pydantic

**DECIDIDO — um payload de escrita + um response por entidade.**

- **Não** são necessários `Create`/`Update` separados: com **PUT** (full update),
  o conjunto de campos editáveis é **idêntico** no criar e no atualizar; separar
  duplicaria contratos sem ganho (a instrução "separar só se facilitar" não se
  aplica).
- Todos com `model_config = ConfigDict(extra="forbid")`; `*Response` com
  `from_attributes=True`.

### 20.1 `GestantePayload` (POST e PUT)

```
{ "nome": str (obrigatório), "data_nascimento": date (obrigatório),
  "nome_social": str | null, "cpf": str | null, "cns": str | null }
```

- **Nunca** aceita `user_id` (derivado do token), `id`, timestamps ou `email`.

### 20.2 `GestanteResponse`

```
{ "id": UUID, "user_id": UUID, "nome": str, "nome_social": str|null,
  "data_nascimento": date, "cpf": str|null, "cns": str|null,
  "created_at": datetime, "updated_at": datetime }
```

- Nunca expõe `password_hash`/senha/token (não pertencem à gestante).

### 20.3 `GestacaoPayload` (POST e PUT)

```
{ "data_ultima_menstruacao": date|null,
  "local_pre_natal": str|null, "profissional_pre_natal": str|null,
  "contato_local_pre_natal": str|null, "ended_at": datetime|null }
```

- **Nunca** aceita `gestante_id` (derivado), `id`, timestamps.
- `ended_at` é **campo de escrita** (mecanismo de conclusão, seção 9):
  - **POST**: `ended_at` deve ser `null` (ou é ignorado/forçado a `null`) — toda
    gestação **nasce ativa**.
  - **PUT**: `ended_at` pode ir de `null` → `timestamp` (**ATIVA → ENCERRADA**),
    ou permanecer `timestamp` ao editar uma encerrada. **PROIBIDO**
    `timestamp → null` (reabertura) — respondido com `422 VALIDATION_ERROR`
    (ou `409`), sem alterar o registro.

### 20.4 `GestacaoResponse`

```
{ "id": UUID, "gestante_id": UUID, "data_ultima_menstruacao": date|null,
  "local_pre_natal": str|null, "profissional_pre_natal": str|null,
  "contato_local_pre_natal": str|null,
  "ended_at": datetime|null, "created_at": datetime, "updated_at": datetime }
```

- Campos derivados (IG/DPP) **não** são incluídos (seção 8).
- **Não** expõe `data_primeira_ultrassom` (FORA DO ESCOPO, FASE 8F — seção 7).

---

## 21. Repositories, Services e transações

**DECIDIDO** (preserva a arquitetura 8B/8C):

```
Router (contracts/) → Service (regra/ownership/commit/rollback)
        → Repository (query/add/update, sem commit)
        → SQLAlchemy Session (síncrona) → PostgreSQL
```

### 21.1 Repositories (sem commit)

- `gestante_repository.py`: `find_by_user_id`, `add` (flush), `update` (flush).
- `gestacao_repository.py`: `find_active_by_gestante_id`, `list_by_gestante_id`,
  `find_by_id`, `add` (flush), `update` (flush).

### 21.2 Services (dono da transação)

- `gestante_service.py`: `get_profile`, `create_profile`, `update_profile`.
- `gestacao_service.py`: `list_gestacoes`, `get_atual`, `get_by_id` (ownership),
  `create`, `update`.

**Regras obrigatórias (herdadas da 8B §14):**

- Repository **não** faz `commit` (apenas queries/ORM e `flush` para obter o
  `id` UUID gerado no Python).
- Service controla **`commit`/`rollback`** — uma escrita = uma unidade de
  trabalho atômica.
- `get_session` dependency fornece/fecha a `Session` (`yield` + `finally`).
- Nenhum `autocommit` implícito; transação explícita.
- Em exceção de domínio → `rollback` + resposta sanitizada; inesperada →
  `rollback` + `500` sanitizado.

---

## 22. Erros HTTP

**DECIDIDO.** Reutilizar o envelope `ErrorResponse {code, message, details}`
existente. Novos códigos estáveis (sem expor stack/SQL/URL do banco/dados
pessoais):

| Código | HTTP | Contexto |
|---|---|---|
| `PROFILE_NOT_FOUND` | `404` | `USER` sem `GESTANTE` (GET/PUT `gestantes/me`, rotas `gestacoes`) |
| `PROFILE_ALREADY_EXISTS` | `409` | `POST /gestantes/me` com perfil já existente |
| `PREGNANCY_NOT_FOUND` | `404` | Gestação inexistente **ou** de outra usuária (idêntico, não revela existência) |
| `ACTIVE_PREGNANCY_ALREADY_EXISTS` | `409` | Segunda gestação ativa (sem encerramento automático) |
| `VALIDATION_ERROR` | `422` | Payload inválido (Pydantic) — já existente |
| `DATABASE_UNAVAILABLE` | `503` | Banco indisponível/não configurado — já existente (8C) |

**Implementação (RECOMENDADO):** criar `meu_bebe_api/gestante/errors.py` (ou
`domain/errors.py`) com uma `DomainError(Exception)` de `{code, message,
status_code}` no mesmo padrão de `AuthError` (8C), registrada no handler de
exceções existente. **Não** criar envelope novo.

---

## 23. Testes, banco de teste e guardas finais

### 23.1 Matriz de testes (banco de teste = PostgreSQL REAL)

| Grupo | Casos representativos |
|---|---|
| **GESTANTE — criação** | `POST /gestantes/me` sem token → `401`; com token e sem perfil → `201`; perfil criado com `user_id` do token; segundo `POST` → `409 PROFILE_ALREADY_EXISTS`; validação (`nome` vazio, `data_nascimento` futura, CPF/CNS malformados) → `422` |
| **GESTANTE — leitura/edição** | `GET /gestantes/me` sem perfil → `404 PROFILE_NOT_FOUND`; com perfil → `200`; `PUT` atualiza e reflete no `GET`; resposta **sem** `user_id` alheio/senha/token |
| **GESTANTE — ownership** | `USER` A não enxerga perfil de `USER` B (não há rota `/{id}`; `me` é sempre o próprio) |
| **GESTAÇÃO — criação** | sem `GESTANTE` → `404 PROFILE_NOT_FOUND`; com gestante → `201`; `gestante_id` derivado do token (ignora qualquer valor do body) |
| **GESTAÇÃO — segunda ativa** | uma ativa existente → `POST` → `409 ACTIVE_PREGNANCY_ALREADY_EXISTS`; a anterior **não** é encerrada automaticamente |
| **GESTAÇÃO — listagem/atual** | `GET /gestacoes` lista só as próprias; `GET /gestacoes/atual` retorna a ativa ou `404`; `PUT /{id}` edita |
| **GESTAÇÃO — encerramento (ended_at)** | `POST` nasce com `ended_at = null`; `PUT` com `ended_at null→timestamp` encerra (ATIVA→ENCERRADA) e libera uma nova ativa; `PUT` com `ended_at timestamp→null` (reabertura) → `422`/`409` sem alterar o registro; editar demais campos de uma encerrada **não** a reabre |
| **GESTAÇÃO — ownership** | `GET/PUT /gestacoes/{id}` de gestação de outra usuária → `404 PREGNANCY_NOT_FOUND` (indistinto de inexistente) |
| **DERIVADOS** | `IG`/`DPP` **não** são colunas persistidas; DUM ausente → sem valores inventados |
| **BANCO/migration** | `alembic upgrade head` cria `gestantes`+`gestacoes`; `downgrade` reversível; FK `CASCADE`, `UNIQUE user_id`, índice parcial único conferidos |
| **TRANSAÇÃO** | falha simulada → `rollback` (sem gestante/gestação órfã); repository não commita; service commita/rollback |
| **REGRESSÃO** | suíte de auth (8C) e DSS permanecem verdes; `/health`, `/ready`, `POST /api/v1/risk-estimate` inalterados |

### 23.2 Banco de teste

**DECIDIDO.** `TEST_DATABASE_URL` apontando para **PostgreSQL real** dedicado
(`meu_bebe_test`), **sem fallback** e **sem** SQLite in-memory — mesmo princípio
congelado nas 8B §19 e 8C §20.1. Isolamento por rollback de transação externa;
schema criado uma vez via `alembic upgrade head` no banco de teste. Testes
dependentes de banco pulam explicitamente se `TEST_DATABASE_URL` indisponível.

### 23.3 Guarda absoluta do DSS — FORA DO ESCOPO de alteração

**DECIDIDO.** `POST /api/v1/risk-estimate` permanece **stateless, sem auth, sem
banco, sem `USER`, sem `GESTANTE`, sem `GESTAÇÃO`, sem persistência**. Nenhum
middleware global de auth; auth só nas rotas que a exigem. A indisponibilidade
de auth/banco nunca afeta o DSS. `AVALIACAO_DSS` é da FASE 8I, sem tocar o
endpoint congelado.

### 23.4 SQLite

**DECIDIDO.** O SQLite **continua** sendo a fonte local do Flutter para as
features **não migradas**; **não** migrar, **não** sincronizar, **não** remover
nesta fase. `GESTANTE`/`GESTAÇÃO` passam a ter a API como nova fonte de verdade
em fases posteriores (8J+), feature por feature, sem escrever nas duas ao mesmo
tempo.

### 23.5 Privacidade

**DECIDIDO.**

- **Nunca** logar CPF/CNS completos, nome, corpo de requisição com dados
  pessoais, `Authorization`, senha ou `DATABASE_URL` com credenciais.
- **Ownership obrigatório** em toda rota de domínio.
- **Senha** existe **somente** em `USER.password_hash` (domínio de auth, 8C);
  `GESTANTE`/`GESTAÇÃO` **nunca** carregam credencial.

### 23.6 Simplicidade (anti-overengineering)

**DECIDIDO.** Não adicionar: DDD, CQRS, event sourcing, Redis, mensageria, RBAC,
soft delete genérico, audit trail, generic repository, mapper framework. Manter
`Router → Service → Repository → Session → PostgreSQL`. Toda decisão que não
contribua para funcionamento/clareza/demonstração/manutenção/segurança essencial
é descartada.

### 23.7 Impacto no TCC — somente planejamento documental futuro

**DECIDIDO.** Nenhuma alteração em `DOCX`/`tcc2.md` nesta fase. Impacto futuro
previsto (a registrar na 8D-DOC, **não agora**): Capítulo 4 (4.7 — implementação
das entidades de domínio; 4.3/4.4/4.5 — ownership e autenticação já existentes),
Capítulo 5 (5.9 — validação dos novos endpoints), diagrama ER (USER/GESTANTE/
GESTAÇÃO) e diagrama de arquitetura. Reafirmar sempre: persistência operacional
**não** autoriza uso científico dos dados reais.

---

## 24. Plano de implementação da FASE 8D-IMP e critérios de aceite

Ordem proposta (nenhum passo executado agora):

1. **8D-IMP.1 — Modelos ORM** — `models/gestante.py` (`Gestante`) e
   `models/gestacao.py` (`Gestacao`), herdando de `Base`, UUID v4 Python,
   timestamps UTC; registrar no `models/__init__.py`.
2. **8D-IMP.2 — Migration 0002** — gerar e revisar manualmente o revision que
   cria `gestantes` + `gestacoes`; `alembic upgrade head` no dev/teste.
3. **8D-IMP.3 — Repositories** — `gestante_repository` e `gestacao_repository`,
   sem commit.
4. **8D-IMP.4 — Contratos** — `GestantePayload`/`GestanteResponse`/
   `GestacaoPayload`/`GestacaoResponse`.
5. **8D-IMP.5 — Erros** — `DomainError` + códigos novos; registrar no handler.
6. **8D-IMP.6 — Services** — `gestante_service` e `gestacao_service`, com
   ownership/commit/rollback.
7. **8D-IMP.7 — Dependência e rotas** — `get_current_gestante`;
   `gestantes/me` (3 rotas) e `gestacoes` (5 rotas); incluir no `api_v1_router`.
8. **8D-IMP.8 — Testes** — matriz da seção 23.1 (PostgreSQL real).
9. **8D-IMP.9 — Auditoria final** — `git diff --check` limpo, suíte verde, DSS
   inalterado, critérios verificados.

### 24.1 Critérios de aceite da 8D-IMP

- [ ] `GESTANTE` e `GESTAÇÃO` criadas com UUID v4 Python, FK `CASCADE`,
      `UNIQUE gestantes.user_id` e índice único parcial de gestação ativa.
- [ ] `USER 1—1 GESTANTE 1—N GESTAÇÃO` respeitada; ownership via token, nunca
      via `user_id`/`gestante_id` do cliente.
- [ ] `POST /gestantes/me` cria; duplicado → `409`; sem perfil → `404`.
- [ ] Segunda gestação ativa → `409`, **sem** encerramento automático.
- [ ] `GET /gestacoes/atual` retorna a ativa (`ended_at IS NULL`) ou `404`.
- [ ] Encerramento via `PUT` (`ended_at` null→timestamp) funciona; reabertura
      (timestamp→null) é **rejeitada** sem alterar o registro.
- [ ] Ownership: gestação de outra usuária → `404` indistinto.
- [ ] IG/DPP **não** persistidos; derivados só em exibição/leitura.
- [ ] Erros sanitizados (sem CPF/CNS/stack/SQL); envelope reutilizado.
- [ ] Repository sem commit; service commit/rollback; session por request.
- [ ] Testes verdes contra **PostgreSQL real**; auth (8C) e DSS intactos.
- [ ] `git diff --check` limpo.

---

> **Fim do plano da FASE 8D-PLAN.** Este documento é a única entrega desta fase.
> A implementação (FASE 8D-IMP) e o registro acadêmico serão realizados em fases
> posteriores, com autorização explícita. **NÃO COMMITAR.**
