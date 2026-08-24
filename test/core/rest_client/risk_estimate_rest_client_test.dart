import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/config/api_config.dart';
import 'package:meu_bebe/app/core/rest_client/interceptors/auth_interceptor.dart';
import 'package:meu_bebe/app/core/rest_client/interceptors/privacy_log_interceptor.dart';
import 'package:meu_bebe/app/core/rest_client/risk_estimate_rest_client.dart';

void main() {
  group('RiskEstimateRestClient (API DSS dedicada)', () {
    test(
      'baseUrl vem de ApiConfig (API_BASE_URL), não de BACKEND_BASE_URL',
      () {
        final client = RiskEstimateRestClient();
        expect(
          client.options.baseUrl,
          ApiConfig.fromEnvironment().normalizedBaseUrl,
        );
      },
    );

    test('timeouts configurados (conexão 10s / envio 15s / recepção 15s)', () {
      final client = RiskEstimateRestClient();
      expect(client.options.connectTimeout, const Duration(seconds: 10));
      expect(client.options.sendTimeout, const Duration(seconds: 15));
      expect(client.options.receiveTimeout, const Duration(seconds: 15));
    });

    test('headers padrão são JSON', () {
      final client = RiskEstimateRestClient();
      expect(
        client.options.headers[Headers.acceptHeader],
        Headers.jsonContentType,
      );
      expect(
        client.options.headers[Headers.contentTypeHeader],
        Headers.jsonContentType,
      );
    });

    test(
      'registra PrivacyLogInterceptor, sem LogInterceptor(body) e sem AuthInterceptor',
      () {
        final client = RiskEstimateRestClient();
        final types = client.interceptors.map((i) => i.runtimeType).toList();

        expect(types, contains(PrivacyLogInterceptor));
        expect(types, isNot(contains(LogInterceptor)));
        expect(types, isNot(contains(AuthInterceptor)));
      },
    );

    test('não aceita todos os status como sucesso (validateStatus 2xx)', () {
      final client = RiskEstimateRestClient();
      final validate = client.options.validateStatus;
      expect(validate(200), isTrue);
      expect(validate(201), isTrue);
      expect(validate(422), isFalse);
      expect(validate(500), isFalse);
      expect(validate(503), isFalse);
    });
  });
}
