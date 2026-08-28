import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/app_module.dart';
import 'package:meu_bebe/app/core/auth/token_storage.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/modules/login/login_controller.dart';
import 'package:meu_bebe/app/repositories/auth/auth_repository.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

TokenResponseModel _token() => const TokenResponseModel(
      user: UserResponseModel(id: 'u1', email: 'maria@example.com', isActive: true),
      accessToken: 'access',
      refreshToken: 'refresh',
    );

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.onLogin);

  Future<Result<TokenResponseModel, BackendFailure>> Function(String, String) onLogin;
  int loginCalls = 0;

  @override
  Future<Result<TokenResponseModel, BackendFailure>> login(String email, String password) {
    loginCalls++;
    return onLogin(email, password);
  }

  @override
  Future<Result<TokenResponseModel, BackendFailure>> register(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<Result<TokenResponseModel, BackendFailure>> refresh(String refreshToken) =>
      throw UnimplementedError();

  @override
  Future<Result<Unit, BackendFailure>> logout(String refreshToken) => throw UnimplementedError();

  @override
  Future<Result<UserResponseModel, BackendFailure>> me() => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  LoginController makeController(_FakeAuthRepository repo, {List<String>? navigations}) {
    return LoginController(
      repo,
      const TokenStorage(),
      navigateReplacement: (route) => navigations?.add(route),
    );
  }

  group('LoginController.login', () {
    test('estado inicial sem login', () {
      final c = makeController(_FakeAuthRepository((_, _) async => Success(_token())));

      expect(c.loading, isFalse);
      expect(c.logged, isFalse);
    });

    test('sucesso: salva tokens, marca logged e navega para a Tab', () async {
      final navigations = <String>[];
      final repo = _FakeAuthRepository((_, _) async => Success(_token()));
      final c = makeController(repo, navigations: navigations);

      await c.login('maria@example.com', 'senha123');

      expect(repo.loginCalls, 1);
      expect(c.logged, isTrue);
      expect(c.loading, isFalse);
      expect(navigations, [routeTab]);

      final storage = const TokenStorage();
      expect(await storage.getAccessToken(), 'access');
      expect(await storage.getRefreshToken(), 'refresh');
    });

    test('credenciais inválidas: não loga, não navega, não persiste sessão', () async {
      final navigations = <String>[];
      final repo = _FakeAuthRepository(
        (_, _) async => const Error(InvalidCredentialsFailure()),
      );
      final c = makeController(repo, navigations: navigations);

      await c.login('maria@example.com', 'errada');

      expect(c.logged, isFalse);
      expect(c.loading, isFalse);
      expect(navigations, isEmpty);
      expect(await const TokenStorage().hasSession(), isFalse);
    });

    test('duplo submit é ignorado (uma única requisição)', () async {
      final completer = Completer<Result<TokenResponseModel, BackendFailure>>();
      final repo = _FakeAuthRepository((_, _) => completer.future);
      final c = makeController(repo);

      final first = c.login('a@b.com', 'senha123');
      final second = c.login('a@b.com', 'senha123');

      completer.complete(Success(_token()));
      await Future.wait([first, second]);

      expect(repo.loginCalls, 1);
      expect(c.logged, isTrue);
    });

    test('loading fica true durante a chamada', () async {
      final completer = Completer<Result<TokenResponseModel, BackendFailure>>();
      final repo = _FakeAuthRepository((_, _) => completer.future);
      final c = makeController(repo);

      final future = c.login('a@b.com', 'senha123');
      expect(c.loading, isTrue);

      completer.complete(Success(_token()));
      await future;

      expect(c.loading, isFalse);
    });
  });
}
