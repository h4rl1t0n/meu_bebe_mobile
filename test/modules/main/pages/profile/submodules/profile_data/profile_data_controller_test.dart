import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';
import 'package:meu_bebe/app/modules/main/pages/profile/submodules/profile_data/profile_data_controller.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:multiple_result/multiple_result.dart';

const _user = UserResponseModel(id: 'u1', email: 'maria@example.com', isActive: true);

const _existing = GestanteModel(
  id: 'g1',
  nome: 'Maria Silva',
  dataNascimento: '1995-03-20',
  cpf: '12345678901',
);

const _input = GestanteModel(
  id: '',
  nome: 'Maria Souza',
  nomeSocial: 'Maria',
  dataNascimento: '1995-03-20',
  cpf: '12345678901',
  cns: '123456789012345',
);

class _FakePerfilRepository implements PerfilRepository {
  _FakePerfilRepository({
    this.onGetUser,
    this.onGetGestante,
    this.onCreate,
    this.onUpdate,
  });

  Future<Result<UserResponseModel?, BackendFailure>> Function()? onGetUser;
  Future<Result<GestanteModel?, BackendFailure>> Function()? onGetGestante;
  Future<Result<GestanteModel, BackendFailure>> Function(GestanteModel)? onCreate;
  Future<Result<GestanteModel, BackendFailure>> Function(GestanteModel)? onUpdate;

  int createCalls = 0;
  int updateCalls = 0;
  GestanteModel? lastCreatePayload;
  GestanteModel? lastUpdatePayload;

  @override
  Future<Result<UserResponseModel?, BackendFailure>> getUser() => onGetUser!();

  @override
  Future<Result<GestanteModel?, BackendFailure>> getGestante() => onGetGestante!();

  @override
  Future<Result<GestacaoModel?, BackendFailure>> getGestacaoAtual() => throw UnimplementedError();

  @override
  Future<Result<GestanteModel, BackendFailure>> createGestante(GestanteModel gestante) {
    createCalls++;
    lastCreatePayload = gestante;
    return onCreate!(gestante);
  }

  @override
  Future<Result<GestanteModel, BackendFailure>> updateGestante(GestanteModel gestante) {
    updateCalls++;
    lastUpdatePayload = gestante;
    return onUpdate!(gestante);
  }
}

Result<UserResponseModel?, BackendFailure> _userResult(UserResponseModel? u) =>
    Success<UserResponseModel?, BackendFailure>(u);

Result<GestanteModel?, BackendFailure> _gestanteResult(GestanteModel? g) =>
    Success<GestanteModel?, BackendFailure>(g);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileDataController.initialize', () {
    test('carrega gestante e e-mail do usuário', () async {
      final repo = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(_existing),
        onGetUser: () async => _userResult(_user),
      );
      final c = ProfileDataController(repo);

      await c.initialize();

      expect(c.gestante, isNotNull);
      expect(c.gestante!.nome, 'Maria Silva');
      expect(c.email, 'maria@example.com');
      expect(c.loading, isFalse);
    });

    test('sem gestante cadastrada, gestante fica null', () async {
      final repo = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(null),
        onGetUser: () async => _userResult(_user),
      );
      final c = ProfileDataController(repo);

      await c.initialize();

      expect(c.gestante, isNull);
      expect(c.email, 'maria@example.com');
    });
  });

  group('ProfileDataController.saveProfile', () {
    test('POST quando ainda não existe gestante', () async {
      final repo = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(null),
        onGetUser: () async => _userResult(_user),
        onCreate: (g) async => Success(g),
      );
      final c = ProfileDataController(repo);
      await c.initialize();

      final ok = await c.saveProfile(_input);

      expect(ok, isTrue);
      expect(repo.createCalls, 1);
      expect(repo.updateCalls, 0);
      expect(repo.lastCreatePayload, same(_input));
    });

    test('PUT quando já existe gestante', () async {
      final repo = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(_existing),
        onGetUser: () async => _userResult(_user),
        onUpdate: (g) async => Success(g),
      );
      final c = ProfileDataController(repo);
      await c.initialize();

      final ok = await c.saveProfile(_input);

      expect(ok, isTrue);
      expect(repo.createCalls, 0);
      expect(repo.updateCalls, 1);
      expect(repo.lastUpdatePayload, same(_input));
    });

    test('payload enviado não carrega id/timestamps (toWriteJson)', () async {
      final repo = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(null),
        onGetUser: () async => _userResult(_user),
        onCreate: (g) async => Success(g),
      );
      final c = ProfileDataController(repo);
      await c.initialize();

      await c.saveProfile(_input);

      final json = repo.lastCreatePayload!.toWriteJson();
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('user_id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
    });

    test('sucesso atualiza gestante e retorna true', () async {
      final repo = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(null),
        onGetUser: () async => _userResult(_user),
        onCreate: (g) async => Success(g),
      );
      final c = ProfileDataController(repo);
      await c.initialize();

      final ok = await c.saveProfile(_input);

      expect(ok, isTrue);
      expect(c.gestante, isNotNull);
      expect(c.loading, isFalse);
    });

    test('erro retorna false e não atualiza gestante', () async {
      final repo = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(null),
        onGetUser: () async => _userResult(_user),
        onCreate: (g) async => const Error(ValidationFailure()),
      );
      final c = ProfileDataController(repo);
      await c.initialize();

      final ok = await c.saveProfile(_input);

      expect(ok, isFalse);
      expect(c.gestante, isNull);
      expect(c.loading, isFalse);
    });

    test('duplo submit é ignorado (uma única escrita)', () async {
      final completer = Completer<Result<GestanteModel, BackendFailure>>();
      final repo = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(null),
        onGetUser: () async => _userResult(_user),
        onCreate: (g) => completer.future,
      );
      final c = ProfileDataController(repo);
      await c.initialize();

      final first = c.saveProfile(_input);
      final second = c.saveProfile(_input);

      completer.complete(Success(_input));
      final results = await Future.wait([first, second]);

      expect(repo.createCalls, 1);
      expect(results, [true, false]);
    });
  });
}
