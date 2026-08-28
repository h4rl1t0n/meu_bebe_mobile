import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/auth/session_manager.dart';
import 'package:meu_bebe/app/core/auth/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const storage = TokenStorage();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SessionManager.handleSessionExpired', () {
    test('limpa os tokens e navega ao login uma única vez', () async {
      await storage.saveTokens(accessToken: 'a', refreshToken: 'r');

      var navigations = 0;
      final session = SessionManager(
        navigateToLogin: () async => navigations++,
      );

      await session.handleSessionExpired();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.hasSession(), isFalse);
      expect(navigations, 1);
    });

    test('chamadas concorrentes navegam apenas uma vez (guarda contra loop)', () async {
      var navigations = 0;
      final session = SessionManager(
        navigateToLogin: () async => navigations++,
      );

      await Future.wait([
        session.handleSessionExpired(),
        session.handleSessionExpired(),
        session.handleSessionExpired(),
      ]);

      expect(navigations, 1);
    });

    test('após concluir, uma nova expiração navega novamente', () async {
      var navigations = 0;
      final session = SessionManager(
        navigateToLogin: () async => navigations++,
      );

      await session.handleSessionExpired();
      await session.handleSessionExpired();

      expect(navigations, 2);
    });
  });
}
