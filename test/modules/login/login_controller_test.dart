import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/auth/credential_storage.dart';
import 'package:meu_bebe/app/core/auth/token_storage.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/modules/login/login_controller.dart';
import 'package:meu_bebe/app/modules/onboarding/onboarding_resolution.dart';
import 'package:meu_bebe/app/modules/onboarding/onboarding_resolver.dart';
import 'package:meu_bebe/app/repositories/auth/auth_repository.dart';
import 'package:meu_bebe/app/repositories/avaliacao_dss/avaliacao_dss_repository.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

TokenResponseModel _token() => const TokenResponseModel(
      user: UserResponseModel(id: 'u1', email: 'maria@example.com', isActive: true),
      accessToken: 'access',
      refreshToken: 'refresh',
    );

class _NoopPerfilRepository implements PerfilRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopAvaliacaoDssRepository implements AvaliacaoDssRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Resolver stub que sempre resolve para a Tab (o teste de login não exercita
/// o fluxo de onboarding; isso é coberto por `onboarding_resolver_test.dart`).
class _StubOnboardingResolver extends OnboardingResolver {
  _StubOnboardingResolver([this.resolution = const OnboardingComplete()])
      : super(_NoopPerfilRepository(), _NoopAvaliacaoDssRepository());

  final OnboardingResolution resolution;

  @override
  Future<OnboardingResolution> resolve() async => resolution;
}

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

/// CredentialStorage em memória (os testes rodam na VM, sem canais nativos do
/// `flutter_secure_storage`). Guarda e-mail + senha em campos simples e conta
/// as chamadas para provar o comportamento "Lembrar-me".
class _FakeCredentialStorage implements CredentialStorage {
  String? email;
  String? password;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<String?> getEmail() async => email;

  @override
  Future<String?> getPassword() async => password;

  @override
  Future<void> save({required String email, required String password}) async {
    saveCalls++;
    this.email = email;
    this.password = password;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    email = null;
    password = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  LoginController makeController(
    _FakeAuthRepository repo, {
    List<OnboardingResolution>? navigations,
    _FakeCredentialStorage? credentialStorage,
  }) {
    return LoginController(
      repo,
      const TokenStorage(),
      credentialStorage ?? _FakeCredentialStorage(),
      _StubOnboardingResolver(),
      navigateReplacement: (resolution) => navigations?.add(resolution),
    );
  }

  group('LoginController.login', () {
    test('estado inicial sem login', () {
      final c = makeController(_FakeAuthRepository((_, _) async => Success(_token())));

      expect(c.loading, isFalse);
      expect(c.logged, isFalse);
    });

    test('sucesso: salva tokens, marca logged e navega para a Tab', () async {
      final navigations = <OnboardingResolution>[];
      final repo = _FakeAuthRepository((_, _) async => Success(_token()));
      final c = makeController(repo, navigations: navigations);

      await c.login('maria@example.com', 'senha123');

      expect(repo.loginCalls, 1);
      expect(c.logged, isTrue);
      expect(c.loading, isFalse);
      expect(navigations, [isA<OnboardingComplete>()]);

      final storage = const TokenStorage();
      expect(await storage.getAccessToken(), 'access');
      expect(await storage.getRefreshToken(), 'refresh');
    });

    test('credenciais inválidas: não loga, não navega, não persiste sessão', () async {
      final navigations = <OnboardingResolution>[];
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

  group('LoginController — Lembrar-me (FASE 9J)', () {
    test('rememberMe é true por padrão e toggleRememberMe inverte', () {
      final c = makeController(_FakeAuthRepository((_, _) async => Success(_token())));
      expect(c.rememberMe, isTrue);

      c.toggleRememberMe(false);
      expect(c.rememberMe, isFalse);
    });

    test('remember=true persiste a flag no TokenStorage', () async {
      final c = makeController(_FakeAuthRepository((_, _) async => Success(_token())));
      c.toggleRememberMe(true);
      await c.login('maria@example.com', 'senha123');

      expect(await const TokenStorage().getRememberMe(), isTrue);
    });

    test('remember=false persiste flag false (tokens ainda salvos p/ sessão atual)', () async {
      final c = makeController(_FakeAuthRepository((_, _) async => Success(_token())));
      c.toggleRememberMe(false);
      await c.login('maria@example.com', 'senha123');

      expect(await const TokenStorage().getRememberMe(), isFalse);
      // A sessão atual ainda guarda os tokens; é a flag false que fará o
      // inicializar_app descartá-los na PRÓXIMA abertura.
      expect(await const TokenStorage().getAccessToken(), 'access');
    });

    test('a senha nunca é persistida em SharedPreferences (só no secure storage)', () async {
      final c = makeController(_FakeAuthRepository((_, _) async => Success(_token())));
      await c.login('maria@example.com', 'senha123');

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((k) => k.toLowerCase().contains('senha') || k.toLowerCase().contains('password'));
      expect(keys, isEmpty);
    });
  });

  group('LoginController — Lembrar-me completo (FASE 9J-PRE-FIX1)', () {
    test('A) remember=true: tokens + credenciais persistidos e sessão recuperável',
        () async {
      final creds = _FakeCredentialStorage();
      final c = makeController(
        _FakeAuthRepository((_, _) async => Success(_token())),
        credentialStorage: creds,
      );
      await c.login('maria@example.com', 'senha123');

      // Sessão recuperável na próxima abertura: tokens + flag presentes.
      expect(await const TokenStorage().hasSession(), isTrue);
      expect(await const TokenStorage().getRememberMe(), isTrue);
      // Credenciais lembradas em armazenamento seguro (e-mail + senha).
      expect(creds.saveCalls, 1);
      expect(creds.email, 'maria@example.com');
      expect(creds.password, 'senha123');
    });

    test('B) remember=false: credenciais limpas e flag false p/ próxima abertura',
        () async {
      final creds = _FakeCredentialStorage();
      final c = makeController(
        _FakeAuthRepository((_, _) async => Success(_token())),
        credentialStorage: creds,
      );
      c.toggleRememberMe(false);
      await c.login('maria@example.com', 'senha123');

      // Tokens da sessão atual seguem salvos; a flag false faz o inicializar_app
      // descartá-los na PRÓXIMA abertura.
      expect(await const TokenStorage().getRememberMe(), isFalse);
      expect(await const TokenStorage().getAccessToken(), 'access');
      // "Lembrar-me" desmarcado NÃO retém credenciais.
      expect(creds.clearCalls, 1);
      expect(creds.email, isNull);
      expect(creds.password, isNull);
    });

    test('C) senha vai para o secure storage, nunca para SharedPreferences', () async {
      final creds = _FakeCredentialStorage();
      final c = makeController(
        _FakeAuthRepository((_, _) async => Success(_token())),
        credentialStorage: creds,
      );
      await c.login('maria@example.com', 'senha123');

      expect(creds.password, 'senha123');
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where((k) => k.contains('senha') || k.contains('password')),
        isEmpty,
      );
    });

    test('D) logout limpa tokens, mas preserva credenciais quando remember=true',
        () async {
      final creds = _FakeCredentialStorage();
      final c = makeController(
        _FakeAuthRepository((_, _) async => Success(_token())),
        credentialStorage: creds,
      );
      await c.login('maria@example.com', 'senha123');

      // Logout = TokenStorage.clear() (sessão). Credenciais lembradas ficam.
      await const TokenStorage().clear();

      expect(await const TokenStorage().hasSession(), isFalse);
      expect(creds.email, 'maria@example.com');
      expect(creds.password, 'senha123');
    });

    test('E) initialize restaura e-mail e senha lembrados após logout', () async {
      final creds = _FakeCredentialStorage();
      final c1 = makeController(
        _FakeAuthRepository((_, _) async => Success(_token())),
        credentialStorage: creds,
      );
      await c1.login('maria@example.com', 'senha123');
      await const TokenStorage().clear(); // logout

      // Nova instância (reabertura do Login) hidrata a partir do secure storage.
      final c2 = makeController(
        _FakeAuthRepository((_, _) async => Success(_token())),
        credentialStorage: creds,
      );
      await c2.initialize();

      expect(c2.rememberMe, isTrue);
      expect(c2.rememberedEmail, 'maria@example.com');
      expect(c2.rememberedPassword, 'senha123');
    });

    test('F) remember=false → initialize volta vazio (login limpo)', () async {
      final creds = _FakeCredentialStorage();
      final c = makeController(
        _FakeAuthRepository((_, _) async => Success(_token())),
        credentialStorage: creds,
      );
      c.toggleRememberMe(false);
      await c.login('maria@example.com', 'senha123');

      final c2 = makeController(
        _FakeAuthRepository((_, _) async => Success(_token())),
        credentialStorage: creds,
      );
      await c2.initialize();

      expect(c2.rememberMe, isFalse);
      expect(c2.rememberedEmail, isNull);
      expect(c2.rememberedPassword, isNull);
    });
  });
}
