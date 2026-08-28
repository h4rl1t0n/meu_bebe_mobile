import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/app_module.dart';
import 'package:meu_bebe/app/core/auth/token_storage.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/modules/register/register_controller.dart';
import 'package:meu_bebe/app/repositories/auth/auth_repository.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

TokenResponseModel _token() => const TokenResponseModel(
      user: UserResponseModel(id: 'u1', email: 'maria@example.com', isActive: true),
      accessToken: 'access',
      refreshToken: 'refresh',
    );

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.onRegister);

  Future<Result<TokenResponseModel, BackendFailure>> Function(String, String) onRegister;
  int registerCalls = 0;

  @override
  Future<Result<TokenResponseModel, BackendFailure>> register(String email, String password) {
    registerCalls++;
    return onRegister(email, password);
  }

  @override
  Future<Result<TokenResponseModel, BackendFailure>> login(String email, String password) =>
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

  RegisterController makeController(_FakeAuthRepository repo, {List<String>? navigations}) {
    return RegisterController(
      repo,
      const TokenStorage(),
      navigateReplacement: (route) => navigations?.add(route),
    );
  }

  group('RegisterController.register', () {
    test('sucesso: salva tokens e navega para a Tab', () async {
      final navigations = <String>[];
      final repo = _FakeAuthRepository((_, _) async => Success(_token()));
      final c = makeController(repo, navigations: navigations);

      await c.register('maria@example.com', 'senha123', 'senha123');

      expect(repo.registerCalls, 1);
      expect(c.loading, isFalse);
      expect(navigations, [routeTab]);

      final storage = const TokenStorage();
      expect(await storage.getAccessToken(), 'access');
      expect(await storage.getRefreshToken(), 'refresh');
    });

    test('senhas diferentes: não chama o backend nem navega', () async {
      final navigations = <String>[];
      final repo = _FakeAuthRepository((_, _) async => Success(_token()));
      final c = makeController(repo, navigations: navigations);

      await c.register('maria@example.com', 'senha123', 'outra');

      expect(repo.registerCalls, 0);
      expect(navigations, isEmpty);
      expect(await const TokenStorage().hasSession(), isFalse);
    });

    test('e-mail já cadastrado: não navega nem persiste sessão', () async {
      final navigations = <String>[];
      final repo = _FakeAuthRepository(
        (_, _) async => const Error(EmailAlreadyRegisteredFailure()),
      );
      final c = makeController(repo, navigations: navigations);

      await c.register('maria@example.com', 'senha123', 'senha123');

      expect(repo.registerCalls, 1);
      expect(c.loading, isFalse);
      expect(navigations, isEmpty);
      expect(await const TokenStorage().hasSession(), isFalse);
    });

    test('duplo submit é ignorado (uma única requisição)', () async {
      final completer = Completer<Result<TokenResponseModel, BackendFailure>>();
      final repo = _FakeAuthRepository((_, _) => completer.future);
      final c = makeController(repo);

      final first = c.register('a@b.com', 'senha123', 'senha123');
      final second = c.register('a@b.com', 'senha123', 'senha123');

      completer.complete(Success(_token()));
      await Future.wait([first, second]);

      expect(repo.registerCalls, 1);
    });
  });
}
