import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/auth/token_storage.dart';
import 'package:meu_bebe/app/core/constants/local_storage_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const storage = TokenStorage();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TokenStorage', () {
    test('saveTokens persiste access e refresh nas chaves esperadas', () async {
      await storage.saveTokens(accessToken: 'a', refreshToken: 'r');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(LocalStorageConstants.accessToken), 'a');
      expect(prefs.getString(LocalStorageConstants.refreshToken), 'r');
      expect(await storage.getAccessToken(), 'a');
      expect(await storage.getRefreshToken(), 'r');
    });

    test('getAccessToken/getRefreshToken retornam null sem valores', () async {
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test('hasSession true apenas quando há access token', () async {
      expect(await storage.hasSession(), isFalse);

      await storage.saveTokens(accessToken: 'a', refreshToken: 'r');
      expect(await storage.hasSession(), isTrue);

      await storage.clear();
      expect(await storage.hasSession(), isFalse);
    });

    test('clear remove access e refresh', () async {
      await storage.saveTokens(accessToken: 'a', refreshToken: 'r');
      await storage.clear();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });
  });
}
