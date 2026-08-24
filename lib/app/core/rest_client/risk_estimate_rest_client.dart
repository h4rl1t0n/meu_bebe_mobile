import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/api_config.dart';
import 'interceptors/privacy_log_interceptor.dart';

/// Cliente HTTP dedicado à API DSS (`POST /api/v1/risk-estimate`).
///
/// O destino é configurado por `API_BASE_URL` (via [ApiConfig]) — independente
/// do [RestClient] do backend existente, que usa `BACKEND_BASE_URL`.
///
/// Não registra [AuthInterceptor] (a API DSS das Fases 4A–4D não exige
/// autenticação) nem [LogInterceptor] com body (o questionário transporta
/// dados sociais e de saúde sensíveis). Usa apenas [PrivacyLogInterceptor].
final class RiskEstimateRestClient extends DioForNative {
  RiskEstimateRestClient()
    : super(
        BaseOptions(
          baseUrl: ApiConfig.fromEnvironment().normalizedBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {
            Headers.acceptHeader: Headers.jsonContentType,
            Headers.contentTypeHeader: Headers.jsonContentType,
          },
        ),
      ) {
    interceptors.add(PrivacyLogInterceptor());
  }
}
