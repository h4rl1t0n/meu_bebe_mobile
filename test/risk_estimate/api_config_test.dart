import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('URL válida com barra final é normalizada', () {
      const config = ApiConfig('http://10.0.2.2:8000/');
      expect(config.normalizedBaseUrl, 'http://10.0.2.2:8000');
      expect(config.isConfigured, isTrue);
    });

    test('URL sem barra final permanece inalterada', () {
      const config = ApiConfig('https://api.example.com');
      expect(config.normalizedBaseUrl, 'https://api.example.com');
      expect(config.isConfigured, isTrue);
    });

    test('URL vazia não está configurada', () {
      const config = ApiConfig('');
      expect(config.normalizedBaseUrl, '');
      expect(config.isConfigured, isFalse);
    });

    test('URL composta só por barra final normaliza para vazio', () {
      const config = ApiConfig('/');
      expect(config.normalizedBaseUrl, '');
      expect(config.isConfigured, isFalse);
    });

    test('fromEnvironment retorna uma configuração sem lançar', () {
      expect(ApiConfig.fromEnvironment(), isA<ApiConfig>());
    });

    test('fromEnvironment lê somente API_BASE_URL (sem fallback)', () {
      final config = ApiConfig.fromEnvironment();
      expect(config.baseUrl, const String.fromEnvironment('API_BASE_URL'));
    });
  });
}
