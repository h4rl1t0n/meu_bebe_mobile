import '../../core/fp/failure.dart';
import '../../modules/formulario/models/risk_estimate/api_error_models.dart';

/// Família de falhas do `RiskEstimateRepository`.
///
/// Cada mensagem é amigável e NUNCA expõe status bruto, corpo, HTML ou stack
/// trace da API. `ValidationFailure` preserva os `details` (já sanitizados
/// pela API) para depuração, mas sem exibi-los automaticamente ao usuário.
sealed class RiskEstimateFailure extends Failure {
  const RiskEstimateFailure({super.message});
}

final class ConfigurationFailure extends RiskEstimateFailure {
  const ConfigurationFailure() : super(message: 'URL da API não configurada.');
}

final class ValidationFailure extends RiskEstimateFailure {
  final List<ApiErrorDetailModel> details;

  const ValidationFailure({this.details = const []})
    : super(message: 'Requisição inválida');
}

final class ModelNotReadyFailure extends RiskEstimateFailure {
  const ModelNotReadyFailure()
    : super(message: 'Modelo de inferência indisponível.');
}

final class InferenceFailure extends RiskEstimateFailure {
  const InferenceFailure()
    : super(message: 'Não foi possível calcular a estimativa.');
}

final class ServiceUnavailableFailure extends RiskEstimateFailure {
  const ServiceUnavailableFailure()
    : super(message: 'Serviço temporariamente indisponível.');
}

final class TimeoutFailure extends RiskEstimateFailure {
  const TimeoutFailure()
    : super(message: 'Tempo de conexão com o serviço excedido.');
}

final class ConnectionFailure extends RiskEstimateFailure {
  const ConnectionFailure()
    : super(message: 'Não foi possível conectar ao serviço.');
}

final class RequestCancelledFailure extends RiskEstimateFailure {
  const RequestCancelledFailure() : super(message: 'Requisição cancelada.');
}

final class InvalidResponseFailure extends RiskEstimateFailure {
  const InvalidResponseFailure()
    : super(message: 'Resposta inválida do serviço.');
}

final class CommunicationFailure extends RiskEstimateFailure {
  const CommunicationFailure({
    super.message = 'Falha de comunicação com o serviço.',
  });
}
