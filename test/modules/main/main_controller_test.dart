import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/app_module.dart';
import 'package:meu_bebe/app/core/auth/token_storage.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';
import 'package:meu_bebe/app/modules/main/main_controller.dart';
import 'package:meu_bebe/app/repositories/auth/auth_repository.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _user = UserResponseModel(id: 'u1', email: 'maria@example.com', isActive: true);

const _gestante = GestanteModel(
  id: 'g1',
  nome: 'Maria Silva',
  dataNascimento: '1995-03-20',
);

const _gestacao = GestacaoModel(
  id: 'ges1',
  dataUltimaMenstruacao: '2026-01-10',
  localPreNatal: 'UBS Centro',
  profissionalPreNatal: 'Dra. Ana',
  contatoLocalPreNatal: '(92) 99999-0000',
);

class _FakeAuthRepository implements AuthRepository {
  int logoutCalls = 0;
  String? loggedOutToken;

  @override
  Future<Result<Unit, BackendFailure>> logout(String refreshToken) {
    logoutCalls++;
    loggedOutToken = refreshToken;
    return Future.value(Success.unit<BackendFailure>());
  }

  @override
  Future<Result<TokenResponseModel, BackendFailure>> login(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<Result<TokenResponseModel, BackendFailure>> register(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<Result<TokenResponseModel, BackendFailure>> refresh(String refreshToken) =>
      throw UnimplementedError();

  @override
  Future<Result<UserResponseModel, BackendFailure>> me() => throw UnimplementedError();
}

class _FakePerfilRepository implements PerfilRepository {
  _FakePerfilRepository({
    this.onGetUser,
    this.onGetGestante,
    this.onGetGestacaoAtual,
  });

  Future<Result<UserResponseModel?, BackendFailure>> Function()? onGetUser;
  Future<Result<GestanteModel?, BackendFailure>> Function()? onGetGestante;
  Future<Result<GestacaoModel?, BackendFailure>> Function()? onGetGestacaoAtual;

  int getGestacaoAtualCalls = 0;

  @override
  Future<Result<UserResponseModel?, BackendFailure>> getUser() => onGetUser!();

  @override
  Future<Result<GestanteModel?, BackendFailure>> getGestante() => onGetGestante!();

  @override
  Future<Result<GestacaoModel?, BackendFailure>> getGestacaoAtual() {
    getGestacaoAtualCalls++;
    return onGetGestacaoAtual!();
  }

  @override
  Future<Result<GestanteModel, BackendFailure>> createGestante(GestanteModel gestante) =>
      throw UnimplementedError();

  @override
  Future<Result<GestanteModel, BackendFailure>> updateGestante(GestanteModel gestante) =>
      throw UnimplementedError();
}

Result<UserResponseModel?, BackendFailure> _userResult(UserResponseModel? u) =>
    Success<UserResponseModel?, BackendFailure>(u);

Result<GestanteModel?, BackendFailure> _gestanteResult(GestanteModel? g) =>
    Success<GestanteModel?, BackendFailure>(g);

Result<GestacaoModel?, BackendFailure> _gestacaoResult(GestacaoModel? g) =>
    Success<GestacaoModel?, BackendFailure>(g);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  MainController makeController({
    required _FakePerfilRepository perfil,
    required _FakeAuthRepository auth,
    List<String>? navigations,
  }) {
    return MainController(
      perfil,
      auth,
      const TokenStorage(),
      navigateReplacement: (route) => navigations?.add(route),
    );
  }

  group('MainController.initialize (Perfil)', () {
    test('A — gestante com nome é a fonte do displayName', () async {
      final perfil = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(_gestante),
        onGetUser: () async => _userResult(_user),
        onGetGestacaoAtual: () async => _gestacaoResult(null),
      );

      final c = makeController(perfil: perfil, auth: _FakeAuthRepository());
      await c.initialize();

      expect(c.name, 'Maria Silva');
      expect(c.gestacaoAtual, isNull);
    });

    test('B — sem gestante, cai para o e-mail do usuário', () async {
      final perfil = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(null),
        onGetUser: () async => _userResult(_user),
        onGetGestacaoAtual: () async => _gestacaoResult(null),
      );

      final c = makeController(perfil: perfil, auth: _FakeAuthRepository());
      await c.initialize();

      expect(c.name, 'maria@example.com');
    });

    test('C — gestante com nome vazio, cai para o e-mail', () async {
      final perfil = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(
          const GestanteModel(id: 'g1', nome: '   '),
        ),
        onGetUser: () async => _userResult(_user),
        onGetGestacaoAtual: () async => _gestacaoResult(null),
      );

      final c = makeController(perfil: perfil, auth: _FakeAuthRepository());
      await c.initialize();

      expect(c.name, 'maria@example.com');
    });

    test('D — gestação atual é consumida quando existe', () async {
      final perfil = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(_gestante),
        onGetUser: () async => _userResult(_user),
        onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
      );

      final c = makeController(perfil: perfil, auth: _FakeAuthRepository());
      await c.initialize();

      expect(c.gestacaoAtual, isNotNull);
      expect(c.gestacaoAtual!.dataUltimaMenstruacao, '2026-01-10');
      expect(c.gestacaoAtual!.localPreNatal, 'UBS Centro');
      expect(c.gestacaoAtual!.profissionalPreNatal, 'Dra. Ana');
      expect(c.gestacaoAtual!.contatoLocalPreNatal, '(92) 99999-0000');
    });

    test('E — 404/erro na gestação atual resulta em null (sem gestação ativa)', () async {
      final perfil = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(_gestante),
        onGetUser: () async => _userResult(_user),
        onGetGestacaoAtual: () async => const Error(SessionExpiredFailure()),
      );

      final c = makeController(perfil: perfil, auth: _FakeAuthRepository());
      await c.initialize();

      expect(c.gestacaoAtual, isNull);
    });

    test('sempre chama getGestacaoAtual', () async {
      final perfil = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(_gestante),
        onGetUser: () async => _userResult(_user),
        onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
      );

      final c = makeController(perfil: perfil, auth: _FakeAuthRepository());
      await c.initialize();

      expect(perfil.getGestacaoAtualCalls, 1);
    });
  });

  group('MainController.logout', () {
    test('com refresh token: revoga, limpa e navega ao login', () async {
      await const TokenStorage().saveTokens(accessToken: 'a', refreshToken: 'r');
      final navigations = <String>[];
      final auth = _FakeAuthRepository();
      final perfil = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(_gestante),
        onGetUser: () async => _userResult(_user),
        onGetGestacaoAtual: () async => _gestacaoResult(null),
      );

      final c = makeController(perfil: perfil, auth: auth, navigations: navigations);
      await c.logout();

      expect(auth.logoutCalls, 1);
      expect(auth.loggedOutToken, 'r');
      expect(navigations, [routeLogin]);
      expect(await const TokenStorage().hasSession(), isFalse);
    });

    test('sem refresh token: não chama logout, mas limpa e navega', () async {
      final navigations = <String>[];
      final auth = _FakeAuthRepository();
      final perfil = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(_gestante),
        onGetUser: () async => _userResult(_user),
        onGetGestacaoAtual: () async => _gestacaoResult(null),
      );

      final c = makeController(perfil: perfil, auth: auth, navigations: navigations);
      await c.logout();

      expect(auth.logoutCalls, 0);
      expect(navigations, [routeLogin]);
    });
  });
}
