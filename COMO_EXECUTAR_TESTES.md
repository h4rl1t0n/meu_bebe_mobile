# Guia de Execução de Testes — Meu Bebê (API e Aplicativo Móvel)

Este documento apresenta o passo a passo prático para configurar o ambiente e executar as suítes de testes automatizados da **API Backend (Python / FastAPI)** e do **Aplicativo Móvel (Flutter / Dart)** do projeto **Meu Bebê**.

---

## 📁 Estrutura de Testes do Projeto

| Componente | Diretório de Testes | Framework | Descrição |
| :--- | :--- | :--- | :--- |
| **API Backend** | [api/tests/](file:///C:/Users/antonio.harliton/Documents/Faculdade/meu_bebe_mobile/api/tests) | `pytest` | Testes unitários, contratos HTTP/DSS, integração de rotas e persistência |
| **Aplicativo Móvel** | [test/](file:///C:/Users/antonio.harliton/Documents/Faculdade/meu_bebe_mobile/test) | `flutter test` | Testes de unidade, repositórios, clientes HTTP, formulários DSS, MobX e widgets |

---

## 1. Testes da API Backend (FastAPI / pytest)

Os testes da API cobrem o contrato HTTP e DSS 1.13, health check (`/health`), readiness com modelo ML (`/ready`), endpoint probabilístico experimental (`/api/v1/risk-estimate`), autenticação JWT e rotas de domínio do pré-natal.

### 1.1. Pré-requisitos
- Python 3.12 ou superior instalado (recomendado **Python 3.13** ou **3.14**).
- Terminal PowerShell aberto.

### 1.2. Passo a Passo

#### Passo 1: Acessar a pasta da API
```powershell
cd C:\Users\antonio.harliton\Documents\Faculdade\meu_bebe_mobile\api
```

#### Passo 2: Criar e ativar o ambiente virtual (`.venv`)
Caso o ambiente virtual `api/.venv` ainda não exista, crie-o:
```powershell
# Usando o executável python padrão:
python -m venv .venv

# Ou utilizando o py launcher:
py -3.13 -m venv .venv
```

Ative o ambiente virtual:
```powershell
.\.venv\Scripts\Activate.ps1
```

> **Dica PowerShell:** Se o Windows impedir a execução do script de ativação por política de restrição, execute na sessão atual:
> ```powershell
> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
> ```

#### Passo 3: Instalar as dependências da API e o pacote de IA
Com o `.venv` ativado, instale as dependências de desenvolvimento da API e conecte o módulo de IA congelado de forma editável:
```powershell
pip install -e ".[dev]"
pip install -e ..\ia
```

#### Passo 4: Verificar o arquivo de configuração `.env`
Se o arquivo [api/.env](file:///C:/Users/antonio.harliton/Documents/Faculdade/meu_bebe_mobile/api/.env) ainda não existir, copie o modelo:
```powershell
Copy-Item .env.example .env
```

> **Nota sobre o Banco de Dados:**  
> - Os testes unitários, de contratos HTTP (`test_dss_contract.py`, `test_http_contract.py`) e de inferência (`test_risk_estimate.py`) **não exigem** PostgreSQL ativo.
> - Os testes de migração e persistência utilizam a variável `TEST_DATABASE_URL`. Se ela estiver vazia ou o banco inacessível, esses testes são pulados (*skipped*) automaticamente e com segurança, sem quebrar a suíte.

#### Passo 5: Comandos de Execução do `pytest`

- **Executar todos os testes:**
  ```powershell
  pytest
  ```

- **Executar com detalhes verbosos (nome de cada teste e status):**
  ```powershell
  pytest -v
  ```

- **Executar suíte rápida de contratos e prontidão (sem necessidade de banco):**
  ```powershell
  pytest tests/test_dss_contract.py tests/test_health.py tests/test_ready.py tests/test_runtime.py -v
  ```

- **Executar testes do serviço de estimativa de risco DSS:**
  ```powershell
  pytest tests/test_risk_estimate.py tests/test_avaliacoes_dss_http.py -v
  ```

- **Executar testes de autenticação e segurança:**
  ```powershell
  pytest tests/test_auth_http.py tests/test_auth_security.py -v
  ```

- **Filtrar testes por termo ou palavra-chave:**
  ```powershell
  pytest -k "auth"
  pytest -k "dss"
  ```

- **Exibir saídas de log e prints no terminal:**
  ```powershell
  pytest -s
  ```

---

## 2. Testes do Aplicativo Móvel (Flutter)

A suíte do aplicativo Flutter valida o isolamento de clientes REST, persistência segura de tokens, mapeamento de falhas funcionais, formulário DSS em 6 etapas, controllers MobX e os repositórios de dados.

### 2.1. Pré-requisitos
- Flutter SDK instalado e adicionado ao `PATH` (`flutter --version`).
- Arquivo de configuração de ambiente unificado [env-meu-bebe.json](file:///C:/Users/antonio.harliton/Documents/Faculdade/meu_bebe_mobile/env-meu-bebe.json) na raiz do projeto.

### 2.2. Passo a Passo

#### Passo 1: Acessar a raiz do projeto móvel
```powershell
cd C:\Users\antonio.harliton\Documents\Faculdade\meu_bebe_mobile
```

#### Passo 2: Atualizar dependências e gerar código (se necessário)
Caso tenha feito alterações em stores MobX ou modelos com geradores de código:
```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

#### Passo 3: Comandos de Execução do `flutter test`

- **Executar todos os testes com a configuração unificada:**
  ```powershell
  flutter test --dart-define-from-file=env-meu-bebe.json
  ```

- **Executar suítes específicas por camada (Recomendado para agilidade):**

  1. **Camada Core (Ambiente, Autenticação, Clientes REST e Helpers):**
     ```powershell
     flutter test test/core/
     ```

  2. **Camada de Estimativa de Risco e Contrato da API:**
     ```powershell
     flutter test test/risk_estimate/
     ```

  3. **Camada de Repositórios de Dados (Gestação, Consultas, Vacinas, etc.):**
     ```powershell
     flutter test test/repositories/
     ```

  4. **Camada do Formulário DSS (Controllers MobX, Validações e Opções):**
     ```powershell
     flutter test test/formulario/
     ```

  5. **Camada de Módulos e Telas (Login, Registro, etc.):**
     ```powershell
     flutter test test/modules/
     ```

- **Executar arquivos de teste específicos:**
  ```powershell
  # Teste de leitura de variáveis de ambiente e URL única:
  flutter test test/core/env_test.dart

  # Teste de isolamento de headers e clientes REST:
  flutter test test/core/rest_client/clients_isolation_test.dart

  # Teste do repositório de estimativa de risco:
  flutter test test/risk_estimate/risk_estimate_repository_impl_test.dart
  ```

- **Executar testes gerando relatório de cobertura de código:**
  ```powershell
  flutter test --coverage
  ```
  *(O relatório será gerado no diretório `coverage/lcov.info`)*.

- **Executar análise estática de código:**
  ```powershell
  flutter analyze
  ```

---

## 3. Tabela Resumo dos Comandos

| Objetivo | Onde Executar | Comando |
| :--- | :--- | :--- |
| **API: Todos os testes** | `api/` | `pytest` |
| **API: Testes verbosos** | `api/` | `pytest -v` |
| **API: Contrato DSS e Health** | `api/` | `pytest tests/test_dss_contract.py tests/test_health.py -v` |
| **API: Filtrar por palavra** | `api/` | `pytest -k "<palavra>"` |
| **APP: Todos os testes** | Raiz (`meu_bebe_mobile`) | `flutter test --dart-define-from-file=env-meu-bebe.json` |
| **APP: Core e HTTP Clients** | Raiz (`meu_bebe_mobile`) | `flutter test test/core/` |
| **APP: Estimativa de Risco** | Raiz (`meu_bebe_mobile`) | `flutter test test/risk_estimate/` |
| **APP: Repositórios** | Raiz (`meu_bebe_mobile`) | `flutter test test/repositories/` |
| **APP: Formulário DSS** | Raiz (`meu_bebe_mobile`) | `flutter test test/formulario/` |
| **APP: Análise Estática** | Raiz (`meu_bebe_mobile`) | `flutter analyze` |

---

## 4. Solução de Problemas Comuns (Troubleshooting)

### PowerShell bloqueia a ativação do `.venv`
- **Sintoma:** Erro `File Activate.ps1 cannot be loaded because running scripts is disabled on this system`.
- **Solução:** No terminal PowerShell atual, rode:
  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  ```
  Em seguida, execute novamente `.\.venv\Scripts\Activate.ps1`.

### Erro `ModuleNotFoundError: No module named 'meu_bebe_ml'` na API
- **Sintoma:** Falha ao importar módulos da IA durante o `pytest`.
- **Solução:** Na pasta `api/` com o `.venv` ativado, execute:
  ```powershell
  pip install -e ..\ia
  ```

### Erro de compilação ou arquivos MobX ausentes no Flutter
- **Sintoma:** Erros indicando classes `*.g.dart` não encontradas.
- **Solução:** Na raiz do projeto, force a regeneração com o build runner:
  ```powershell
  dart run build_runner build --delete-conflicting-outputs
  ```

### Testes de banco de dados pulados (*skipped*) na API
- **Sintoma:** O relatório do `pytest` mostra `s` (skipped) em arquivos como `test_auth_migration.py`.
- **Comportamento normal:** Caso não haja um banco PostgreSQL configurado em `TEST_DATABASE_URL`, a suíte pula intencionalmente os testes que dependem de conexão real, preservando a integridade dos testes de regras de negócio e contratos.
