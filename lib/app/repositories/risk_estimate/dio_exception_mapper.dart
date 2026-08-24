import 'package:dio/dio.dart';

import '../../modules/formulario/models/risk_estimate/api_error_models.dart';
import 'risk_estimate_failure.dart';

/// Converte um [DioException] numa [RiskEstimateFailure] específica.
///
/// O mapeamento segue o contrato congelado e NUNCA vaza status bruto, corpo,
/// HTML ou stack trace para a mensagem exibida.
final class RiskEstimateDioExceptionMapper {
  const RiskEstimateDioExceptionMapper();

  RiskEstimateFailure map(DioException exception) {
    final response = exception.response;
    if (response != null) {
      return _mapByStatus(response);
    }

    return switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const TimeoutFailure(),
      DioExceptionType.connectionError => const ConnectionFailure(),
      DioExceptionType.badCertificate => const ConnectionFailure(),
      DioExceptionType.cancel => const RequestCancelledFailure(),
      DioExceptionType.badResponse ||
      DioExceptionType.unknown => const CommunicationFailure(),
    };
  }

  RiskEstimateFailure _mapByStatus(Response<dynamic> response) {
    final status = response.statusCode ?? 0;

    if (status == 422) {
      final details =
          ApiErrorModel.tryParse(response.data)?.details ??
          const <ApiErrorDetailModel>[];
      return ValidationFailure(details: details);
    }

    if (status == 503) return const ModelNotReadyFailure();

    if (status == 500) return const InferenceFailure();

    if (status >= 500 && status < 600) return const ServiceUnavailableFailure();

    // 3xx, 4xx (exceto 422) e demais: erro remoto genérico, sem expor o corpo.
    return const CommunicationFailure();
  }
}
