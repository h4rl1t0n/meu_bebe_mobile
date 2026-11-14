# Integração Flutter ↔ API Backend e DSS

> Documentação técnica da integração do aplicativo Flutter com o backend FastAPI (`meu_bebe_api`).
> Originalmente concebida nas **Fases 5A, 5B e 5C** para o consumo do endpoint experimental
> `POST /api/v1/risk-estimate` via **Dio**, a arquitetura de integração foi posteriormente
> expandida para cobrir **todo o domínio de acompanhamento pré-natal, autenticação e persistência**,
> culminando na completa desativação do legado local SQLite.

---

## 1. Escopo da Integração

### 1.1 Eixo DSS e Estimativa Experimental (Fases 5A–5D)
1. **Configuração centralizada** de URL via `ApiConfig` (`API_BASE_URL`).
2. **Cliente HTTP dedicado e anônimo** (`RiskEstimateRestClient`) para requisições de inferência DSS (`POST /api/v1/risk-estimate`).
3. **Modelos DTO imutáveis** e mapeamento defensivo de respostas e erros padronizados (`ValidationFailure`, `ModelNotReadyFailure`, `InferenceFailure`).
4. **Proteção estrita de privacidade** via `PrivacyLogInterceptor` (sem registro de corpos de requisição/resposta nem cabeçalhos).
5. **Apresentação visual não classificatória** (`RiskEstimateResultSheet`), exibindo percentual e nota metodológica sem rotular risco como baixo/médio/alto.

### 1.2 Eixo de Acompanhamento Pré-natal e Autenticação (Fases 8–10)
1. **Cliente HTTP do Backend** (`RestClient` / `DioForNative`) configurado com a URL unificada `API_BASE_URL`.
2. **Autenticação e Sessão:** Gerenciamento seguro via `AuthInterceptor` com injeção automática de header `Authorization: Bearer <token>` e renovação transparente em HTTP `401`.
3. **Resolução de Privacidade no Backend:** O `RestClient` foi atualizado para utilizar `PrivacyLogInterceptor`, sanando a dívida técnica de logging em rotas autenticadas.
4. **Eliminação do SQLite:** Remoção integral do pacote `sqflite` e da camada `database.dart`. Todas as operações de leitura e escrita agora utilizam repositórios REST conectando-se ao backend PostgreSQL via FastAPI.
5. **Persistência de Avaliações DSS:** As respostas e o score calculado podem ser persistidos e vinculados à gestação ativa via `POST /api/v1/gestacoes/{gestacao_id}/avaliacoes-dss`.

---

## 2. Arquitetura de Comunicação e Clientes HTTP

```
lib/app/core/
├── env.dart                                         → API_BASE_URL
├── config/api_config.dart                           → API_BASE_URL
├── rest_client/
│   ├── rest_client.dart                             → Dio para o backend (Auth, Pré-natal e Avaliações DSS)
│   ├── risk_estimate_rest_client.dart               → Dio dedicado e anônimo para estimativa DSS
│   └── interceptors/
│       ├── privacy_log_interceptor.dart             → Log sem payload nem credenciais
│       └── auth_interceptor.dart                    → Injeção de Bearer token e refresh automático
lib/app/repositories/
├── auth/                                            → AuthRepositoryImpl (/api/v1/auth)
├── perfil/                                          → PerfilRepositoryImpl (/api/v1/gestantes/me)
├── gestacao/                                        → GestacaoRepositoryImpl (/api/v1/gestacoes)
├── historico_obstetrico/                            → HistoricoObstetricoRepositoryImpl (/api/v1/historico-obstetrico)
├── consulta/                                        → ConsultaRepositoryImpl (/api/v1/gestacoes/{id}/consultas)
├── exame/                                           → ExameRepositoryImpl (/api/v1/gestacoes/{id}/exames)
├── medicamento/                                     → MedicamentoRepositoryImpl (/api/v1/gestacoes/{id}/medicamentos)
├── vacina/                                          → VacinaRepositoryImpl (/api/v1/gestacoes/{id}/vacinas)
├── plano_parto/                                     → PlanoPartoRepositoryImpl (/api/v1/gestacoes/{id}/plano-parto)
├── avaliacao_dss/                                   → AvaliacaoDssRepositoryImpl (/api/v1/gestacoes/{id}/avaliacoes-dss)
└── risk_estimate/                                   → RiskEstimateRepositoryImpl (/api/v1/risk-estimate)
```

### Isolamento dos Clientes HTTP

| Cliente | Destino HTTP | Variável de Ambiente | Interceptors Ativos | Finalidade |
| --- | --- | --- | --- | --- |
| `RestClient` | Backend API | `API_BASE_URL` | `PrivacyLogInterceptor`, `AuthInterceptor` | Autenticação, dados de saúde e histórico |
| `RiskEstimateRestClient` | Backend API (DSS) | `API_BASE_URL` | `PrivacyLogInterceptor` (sem Auth) | Estimativa probabilística anônima |

> Ambos os clientes utilizam a URL unificada `API_BASE_URL` (definida em `env-meu-bebe.json`). A segregação de clientes garante que o endpoint DSS continue desacoplado e anônimo, sem transportar tokens nem credenciais.

---

## 3. Configuração de Base URL (Sem Hardcode)

A URL unificada é obtida em tempo de execução via `String.fromEnvironment('API_BASE_URL')` ou lida do arquivo `env-meu-bebe.json`:

```bash
flutter run --dart-define-from-file=env-meu-bebe.json
```

- **Normalização:** `ApiConfig.normalizedBaseUrl` remove barras finais automaticamente.
- **Ambientes prontos:** O arquivo `.vscode/launch.json` disponibiliza atalhos para Emulador (`10.0.2.2`) e Dispositivo Físico (`192.168.x.x`), ambos consumindo `env-meu-bebe.json`.

---

## 4. Tratamento de Erros e Padrão Funcional

Todos os repositórios utilizam o tipo `Result<T, BackendFailure>` (pacote `multiple_result`), evitando exceções não tratadas na interface:

```dart
Future<Result<List<ConsultaModel>, BackendFailure>> listConsultas(String gestacaoId);
```

### Mapeamento de Falhas (`BackendDioExceptionMapper`)
- HTTP `401`: `SessionExpiredFailure` (dispara redirecionamento ou aviso de login expirado);
- HTTP `422`: `ValidationFailure` com detalhes dos campos inconsistentes;
- HTTP `503`: `ServiceUnavailableFailure` amigável;
- Falhas de conexão / timeout: `ConnectionFailure` ou `TimeoutFailure`;
- **Nenhum** stack trace ou corpo HTTP bruto é apresentado diretamente para a usuária.

---

## 5. Fluxo do Formulário DSS e Apresentação Visual

### 5.1 Envio
No `FormularioPage`, a submissão aciona o `FormularioController.enviarFormulario()`:
1. Valida o preenchimento obrigatório das 6 dimensões;
2. Converte as respostas via `FormularioData.toMap()` (formato canônico aninhado v1.13 com 48 variáveis);
3. Desabilita o botão para impedir disparos concorrentes;
4. Envia payload ao `POST /api/v1/risk-estimate` através de `RiskEstimateRepositoryImpl`.

### 5.2 Apresentação não classificatória (`RiskEstimateResultSheet`)
A probabilidade retornada é renderizada visualmente em um `showModalBottomSheet`:
- Percentual exibido com 1 casa decimal (ex.: `23,8%`);
- Cor fixa primária (`primary500`), sem semáforo (vermelho/amarelo/verde);
- Mensagem informativa de cautela metodológica (`notice`) preservada integralmente;
- Ausência de termos como "alto risco", "médio risco" ou "diagnóstico clínico".

---

## 6. Verificação e Testes de Integração

```bash
# Análise estática
flutter analyze

# Execução dos testes unitários e de integração mockada
flutter test
```

A suíte cobre:
- Parsing e validação dos modelos de DTOs e erros;
- Mapeamento determinístico de `DioException` para falhas do domínio;
- Isolamento estrito entre `RestClient` e `RiskEstimateRestClient`;
- Formatação e invariantes da apresentação da estimativa visual;
- Injeção e ciclo de vida dos módulos do Flutter Modular.
