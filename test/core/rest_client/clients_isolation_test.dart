import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/config/api_config.dart';
import 'package:meu_bebe/app/core/env.dart';
import 'package:meu_bebe/app/core/rest_client/rest_client.dart';
import 'package:meu_bebe/app/core/rest_client/risk_estimate_rest_client.dart';

void main() {
  group('Isolamento de destinos HTTP (backend vs API DSS)', () {
    test(
      'RestClient lê BACKEND_BASE_URL; RiskEstimateRestClient lê API_BASE_URL',
      () {
        final backend = RestClient();
        final risk = RiskEstimateRestClient();

        expect(backend.options.baseUrl, Env.backendBaseUrl);
        expect(
          risk.options.baseUrl,
          ApiConfig.fromEnvironment().normalizedBaseUrl,
        );
      },
    );

    test('são classes distintas (dois clients independentes)', () {
      expect(
        RiskEstimateRestClient().runtimeType,
        isNot(RestClient().runtimeType),
      );
    });

    test(
      'ApiConfig lê somente API_BASE_URL (sem fallback para BACKEND_BASE_URL)',
      () {
        const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
        final config = ApiConfig.fromEnvironment();

        expect(config.baseUrl, apiBaseUrl);

        if (apiBaseUrl.isNotEmpty) {
          expect(config.baseUrl, isNot(Env.backendBaseUrl));
        } else {
          expect(config.baseUrl, isEmpty);
        }
      },
    );

    test(
      'API_BASE_URL vazio ⇒ API DSS não configurada (isConfigured false)',
      () {
        expect(const ApiConfig('').isConfigured, isFalse);
      },
    );
  });
}
