import 'package:dio/dio.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/config/api_config.dart';
import '../../core/rest_client/risk_estimate_rest_client.dart';
import '../../modules/formulario/models/formulario_data.dart';
import '../../modules/formulario/models/risk_estimate/risk_estimate_response_model.dart';
import 'dio_exception_mapper.dart';
import 'risk_estimate_failure.dart';
import 'risk_estimate_repository.dart';

class RiskEstimateRepositoryImpl implements RiskEstimateRepository {
  /// Caminho único do endpoint de estimativa (contrato congelado).
  static const String endpointPath = '/api/v1/risk-estimate';

  final RiskEstimateRestClient client;
  final ApiConfig config;
  final RiskEstimateDioExceptionMapper _mapper;

  RiskEstimateRepositoryImpl({required this.client, required this.config})
    : _mapper = const RiskEstimateDioExceptionMapper();

  @override
  Future<Result<RiskEstimateResponseModel, RiskEstimateFailure>> estimate(
    FormularioData data,
  ) async {
    if (!config.isConfigured) {
      return Error(const ConfigurationFailure());
    }

    try {
      final response = await client.post(endpointPath, data: data.toMap());

      final model = RiskEstimateResponseModel.tryParse(response.data);
      if (model == null) {
        return Error(const InvalidResponseFailure());
      }

      return Success(model);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }
}
