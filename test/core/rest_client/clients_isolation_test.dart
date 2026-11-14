import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/config/api_config.dart';
import 'package:meu_bebe/app/core/env.dart';
import 'package:meu_bebe/app/core/rest_client/rest_client.dart';
import 'package:meu_bebe/app/core/rest_client/risk_estimate_rest_client.dart';

void main() {
  group('Isolamento e configuração dos clientes HTTP', () {
    test(
      'RestClient e RiskEstimateRestClient compartilham API_BASE_URL unificada',
      () {
        final backend = RestClient();
        final risk = RiskEstimateRestClient();

        expect(backend.options.baseUrl, Env.apiBaseUrl);
        expect(
          risk.options.baseUrl,
          ApiConfig.fromEnvironment().normalizedBaseUrl,
        );
      },
    );

    test('são classes distintas (dois clients especializados)', () {
      expect(
        RiskEstimateRestClient().runtimeType,
        isNot(RestClient().runtimeType),
      );
    });

    test('ApiConfig lê unicamente API_BASE_URL', () {
      const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
      final config = ApiConfig.fromEnvironment();

      expect(config.baseUrl, apiBaseUrl);
      expect(config.isConfigured, apiBaseUrl.isNotEmpty);
    });

    test('Env utiliza unicamente API_BASE_URL', () {
      const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

      expect(Env.apiBaseUrl, apiBaseUrl);
      expect(Env.backendBaseUrl, apiBaseUrl);
    });

    test(
      'API_BASE_URL vazio ⇒ API DSS não configurada (isConfigured false)',
      () {
        expect(const ApiConfig('').isConfigured, isFalse);
      },
    );
  });
}
