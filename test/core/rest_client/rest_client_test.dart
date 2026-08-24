import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/env.dart';
import 'package:meu_bebe/app/core/rest_client/interceptors/auth_interceptor.dart';
import 'package:meu_bebe/app/core/rest_client/rest_client.dart';

void main() {
  group('RestClient (backend — baseline restaurado)', () {
    test(
      'baseUrl vem de Env.backendBaseUrl (BACKEND_BASE_URL), não de API_BASE_URL',
      () {
        final client = RestClient();
        expect(client.options.baseUrl, Env.backendBaseUrl);
      },
    );

    test(
      'timeouts do baseline restaurados (conexão 10s / recepção 60s / sem envio)',
      () {
        final client = RestClient();
        expect(client.options.connectTimeout, const Duration(seconds: 10));
        expect(client.options.receiveTimeout, const Duration(seconds: 60));
        expect(client.options.sendTimeout, isNull);
      },
    );

    test(
      'interceptors do baseline restaurados (LogInterceptor + AuthInterceptor)',
      () {
        final client = RestClient();
        final types = client.interceptors.map((i) => i.runtimeType).toList();

        expect(types, contains(LogInterceptor));
        expect(types, contains(AuthInterceptor));
      },
    );

    test('sem headers JSON globais da integração DSS', () {
      final client = RestClient();
      expect(client.options.headers.containsKey(Headers.acceptHeader), isFalse);
      expect(
        client.options.headers.containsKey(Headers.contentTypeHeader),
        isFalse,
      );
    });

    test('não aceita todos os status como sucesso (validateStatus 2xx)', () {
      final client = RestClient();
      final validate = client.options.validateStatus;
      expect(validate(200), isTrue);
      expect(validate(201), isTrue);
      expect(validate(422), isFalse);
      expect(validate(500), isFalse);
      expect(validate(503), isFalse);
    });
  });
}
