/// Configuração central do endpoint da API DSS (estimativa de risco).
///
/// Lê exclusivamente `API_BASE_URL` (nome recomendado pela fase de integração).
/// **Não há fallback** para `BACKEND_BASE_URL`: a API DSS e o backend existente
/// (login) são destinos HTTP independentes. Quando `API_BASE_URL` é vazio, a
/// API de estimativa é considerada **não configurada** (`isConfigured == false`).
///
/// É injetável (construtor explícito) para que os testes forneçam uma URL
/// determinística sem depender de `--dart-define`.
final class ApiConfig {
  final String baseUrl;

  const ApiConfig(this.baseUrl);

  /// Lê apenas `API_BASE_URL`.
  factory ApiConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    return ApiConfig(apiBaseUrl);
  }

  /// Base URL sem a barra final (ex.: `http://host:8000`).
  String get normalizedBaseUrl => baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;

  /// `true` quando há uma base URL utilizável.
  bool get isConfigured => normalizedBaseUrl.isNotEmpty;
}
