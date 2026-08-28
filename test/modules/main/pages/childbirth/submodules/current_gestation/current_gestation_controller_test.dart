import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/current_gestation/current_gestation_controller.dart';
import 'package:meu_bebe/app/repositories/gestacao/gestacao_repository.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:multiple_result/multiple_result.dart';

const _gestacao = GestacaoModel(
  id: 'gestacao-1',
  dataUltimaMenstruacao: '2025-11-01',
  localPreNatal: 'UBS Central',
  profissionalPreNatal: 'Dra. Ana',
  contatoLocalPreNatal: '(92) 99999-0000',
);

class _FakePerfilRepository implements PerfilRepository {
  _FakePerfilRepository({this.onGetGestacaoAtual});

  Future<Result<GestacaoModel?, BackendFailure>> Function()? onGetGestacaoAtual;
  int getGestacaoAtualCalls = 0;

  @override
  Future<Result<GestacaoModel?, BackendFailure>> getGestacaoAtual() {
    getGestacaoAtualCalls++;
    return onGetGestacaoAtual!();
  }

  @override
  Future<Result<UserResponseModel?, BackendFailure>> getUser() =>
      throw UnimplementedError();

  @override
  Future<Result<GestanteModel?, BackendFailure>> getGestante() =>
      throw UnimplementedError();

  @override
  Future<Result<GestanteModel, BackendFailure>> createGestante(
    GestanteModel gestante,
  ) => throw UnimplementedError();

  @override
  Future<Result<GestanteModel, BackendFailure>> updateGestante(
    GestanteModel gestante,
  ) => throw UnimplementedError();
}

class _FakeGestacaoRepository implements GestacaoRepository {
  _FakeGestacaoRepository({this.onCreate, this.onUpdate});

  Future<Result<GestacaoModel, BackendFailure>> Function(GestacaoModel)? onCreate;
  Future<Result<GestacaoModel, BackendFailure>> Function(GestacaoModel)? onUpdate;
  int createCalls = 0;
  int updateCalls = 0;

  @override
  Future<Result<GestacaoModel, BackendFailure>> createGestacao(
    GestacaoModel gestacao,
  ) {
    createCalls++;
    return onCreate!(gestacao);
  }

  @override
  Future<Result<GestacaoModel, BackendFailure>> updateGestacao(
    GestacaoModel gestacao,
  ) {
    updateCalls++;
    return onUpdate!(gestacao);
  }
}

Result<GestacaoModel?, BackendFailure> _getResult(GestacaoModel? g) =>
    Success<GestacaoModel?, BackendFailure>(g);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurrentGestationController.initialize', () {
    test('com gestação ativa → model preenchido e loading false', () async {
      final perfil = _FakePerfilRepository(
        onGetGestacaoAtual: () async => _getResult(_gestacao),
      );
      final c = CurrentGestationController(perfil, _FakeGestacaoRepository());

      await c.initialize();

      expect(c.model, isNotNull);
      expect(c.model!.id, 'gestacao-1');
      expect(c.loading, isFalse);
    });

    test('sem gestação ativa (404 → null) → model null, tela abre normal',
        () async {
      final perfil = _FakePerfilRepository(
        onGetGestacaoAtual: () async => _getResult(null),
      );
      final c = CurrentGestationController(perfil, _FakeGestacaoRepository());

      await c.initialize();

      expect(c.model, isNull);
      expect(c.loading, isFalse);
    });

    test('erro (sessão/rede) → model null, tela abre normal', () async {
      final perfil = _FakePerfilRepository(
        onGetGestacaoAtual: () async => const Error(SessionExpiredFailure()),
      );
      final c = CurrentGestationController(perfil, _FakeGestacaoRepository());

      await c.initialize();

      expect(c.model, isNull);
      expect(c.loading, isFalse);
    });
  });

  group('CurrentGestationController.save', () {
    test('sem gestação → cria (POST)', () async {
      final perfil = _FakePerfilRepository(
        onGetGestacaoAtual: () async => _getResult(null),
      );
      final gestacaoRepo = _FakeGestacaoRepository(
        onCreate: (g) async => Success(g),
      );
      final c = CurrentGestationController(perfil, gestacaoRepo);
      await c.initialize();

      final ok = await c.save(_gestacao);

      expect(ok, isTrue);
      expect(gestacaoRepo.createCalls, 1);
      expect(gestacaoRepo.updateCalls, 0);
      expect(c.model!.id, 'gestacao-1');
    });

    test('com gestação → atualiza (PUT)', () async {
      final perfil = _FakePerfilRepository(
        onGetGestacaoAtual: () async => _getResult(_gestacao),
      );
      final gestacaoRepo = _FakeGestacaoRepository(
        onUpdate: (g) async => Success(g),
      );
      final c = CurrentGestationController(perfil, gestacaoRepo);
      await c.initialize();

      final ok = await c.save(_gestacao);

      expect(ok, isTrue);
      expect(gestacaoRepo.updateCalls, 1);
      expect(gestacaoRepo.createCalls, 0);
    });

    test('erro → retorna false e não atualiza model', () async {
      final perfil = _FakePerfilRepository(
        onGetGestacaoAtual: () async => _getResult(null),
      );
      final gestacaoRepo = _FakeGestacaoRepository(
        onCreate: (g) async => const Error(ValidationFailure()),
      );
      final c = CurrentGestationController(perfil, gestacaoRepo);
      await c.initialize();

      final ok = await c.save(_gestacao);

      expect(ok, isFalse);
      expect(c.model, isNull);
      expect(c.loading, isFalse);
    });

    test('duplo submit → uma única escrita', () async {
      final perfil = _FakePerfilRepository(
        onGetGestacaoAtual: () async => _getResult(null),
      );
      final completer = Completer<Result<GestacaoModel, BackendFailure>>();
      final gestacaoRepo = _FakeGestacaoRepository(
        onCreate: (g) => completer.future,
      );
      final c = CurrentGestationController(perfil, gestacaoRepo);
      await c.initialize();

      final first = c.save(_gestacao);
      final second = c.save(_gestacao);

      completer.complete(Success(_gestacao));
      final results = await Future.wait([first, second]);

      expect(gestacaoRepo.createCalls, 1);
      expect(results, [true, false]);
    });

    test('loading fica true durante a chamada', () async {
      final perfil = _FakePerfilRepository(
        onGetGestacaoAtual: () async => _getResult(null),
      );
      final completer = Completer<Result<GestacaoModel, BackendFailure>>();
      final gestacaoRepo = _FakeGestacaoRepository(
        onCreate: (g) => completer.future,
      );
      final c = CurrentGestationController(perfil, gestacaoRepo);
      await c.initialize();

      final future = c.save(_gestacao);
      expect(c.loading, isTrue);

      completer.complete(Success(_gestacao));
      await future;
      expect(c.loading, isFalse);
    });
  });
}
