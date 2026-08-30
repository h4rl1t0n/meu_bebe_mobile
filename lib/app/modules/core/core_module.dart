import 'package:dio/io.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../core/config/api_config.dart';
import '../../core/rest_client/rest_client.dart';
import '../../core/rest_client/risk_estimate_rest_client.dart';
import '../../repositories/risk_estimate/risk_estimate_repository.dart';
import '../../repositories/risk_estimate/risk_estimate_repository_impl.dart';

class CoreModule extends Module {
  @override
  void exportedBinds(i) {
    i.addSingleton<DioForNative>(RestClient.new);
    i.addSingleton<ApiConfig>(ApiConfig.fromEnvironment);
    i.addSingleton<RiskEstimateRestClient>(RiskEstimateRestClient.new);
    i.addSingleton<RiskEstimateRepository>(RiskEstimateRepositoryImpl.new);
    super.exportedBinds(i);
  }
}
