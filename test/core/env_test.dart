import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/env.dart';

void main() {
  group('Env', () {
    test('apiBaseUrl e backendBaseUrl utilizam a chave única API_BASE_URL', () {
      const api = String.fromEnvironment('API_BASE_URL');
      expect(Env.apiBaseUrl, api);
      expect(Env.backendBaseUrl, api);
    });
  });
}
