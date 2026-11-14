final class Env {
  /// Base URL unificada da API (autenticação, serviços e estimativa de risco).
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Mantido como alias de [apiBaseUrl] para compatibilidade com consumidores existentes.
  static const backendBaseUrl = apiBaseUrl;
}
