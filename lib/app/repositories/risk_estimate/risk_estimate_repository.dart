import 'package:multiple_result/multiple_result.dart';

import '../../modules/formulario/models/formulario_data.dart';
import '../../modules/formulario/models/risk_estimate/risk_estimate_response_model.dart';
import 'risk_estimate_failure.dart';

/// Contrato do repositório de estimativa de risco (DSS).
abstract class RiskEstimateRepository {
  /// Envia o [data] (já consolidado) para `POST /api/v1/risk-estimate` e
  /// devolve a estimativa ou uma [RiskEstimateFailure].
  Future<Result<RiskEstimateResponseModel, RiskEstimateFailure>> estimate(
    FormularioData data,
  );
}
