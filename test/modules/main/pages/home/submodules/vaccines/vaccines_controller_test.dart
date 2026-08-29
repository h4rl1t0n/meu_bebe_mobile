import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';
import 'package:meu_bebe/app/model/vacina/vacina_model.dart';
import 'package:meu_bebe/app/modules/main/pages/home/submodules/vaccines/vaccines_controller.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:meu_bebe/app/repositories/vacina/vacina_repository.dart';
import 'package:multiple_result/multiple_result.dart';

const _gestacao = GestacaoModel(
  id: 'ges-1',
  dataUltimaMenstruacao: '2026-01-10',
);

class _FakePerfilRepository implements PerfilRepository {
  _FakePerfilRepository({this.onGetGestacaoAtual});

  Future<Result<GestacaoModel?, BackendFailure>> Function()? onGetGestacaoAtual;

  @override
  Future<Result<GestacaoModel?, BackendFailure>> getGestacaoAtual() =>
      onGetGestacaoAtual!();

  @override
  Future<Result<GestanteModel?, BackendFailure>> getGestante() =>
      throw UnimplementedError();

  @override
  Future<Result<UserResponseModel?, BackendFailure>> getUser() =>
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

class _FakeVacinaRepository implements VacinaRepository {
  Future<Result<List<VacinaModel>, BackendFailure>> Function(String)? onList;
  Future<Result<VacinaModel, BackendFailure>> Function(String, VacinaModel)?
  onCreate;
  Future<Result<VacinaModel, BackendFailure>> Function(String, VacinaModel)?
  onUpdate;

  int listCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;

  @override
  Future<Result<List<VacinaModel>, BackendFailure>> listVacinas(
    String gestacaoId,
  ) {
    listCalls++;
    return onList?.call(gestacaoId) ??
        Future.value(Success<List<VacinaModel>, BackendFailure>([]));
  }

  @override
  Future<Result<VacinaModel, BackendFailure>> createVacina(
    String gestacaoId,
    VacinaModel vacina,
  ) {
    createCalls++;
    return onCreate?.call(gestacaoId, vacina) ??
        Future.value(Success(vacina));
  }

  @override
  Future<Result<VacinaModel, BackendFailure>> updateVacina(
    String gestacaoId,
    VacinaModel vacina,
  ) {
    updateCalls++;
    return onUpdate?.call(gestacaoId, vacina) ??
        Future.value(Success(vacina));
  }
}

Result<GestacaoModel?, BackendFailure> _gestacaoResult(GestacaoModel? g) =>
    Success<GestacaoModel?, BackendFailure>(g);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  VaccinesController makeController({
    _FakePerfilRepository? perfil,
    _FakeVacinaRepository? vacina,
  }) {
    return VaccinesController(
      perfil ?? _FakePerfilRepository(),
      vacina ?? _FakeVacinaRepository(),
    );
  }

  group('initialize', () {
    test('com gestação ativa → hasGestacao=true, isLoading=false', () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
      );

      await c.initialize();

      expect(c.hasGestacao, isTrue);
      expect(c.isLoading, isFalse);
    });

    test('sem gestação ativa → hasGestacao=false e lista vazia', () async {
      final vacina = _FakeVacinaRepository();
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(null),
        ),
        vacina: vacina,
      );

      await c.initialize();

      expect(c.hasGestacao, isFalse);
      expect(c.vacinas, isEmpty);
      expect(vacina.listCalls, 0);
      expect(c.isLoading, isFalse);
    });

    test('lista vazia (nenhuma vacina registrada) → sem erro', () async {
      final vacina = _FakeVacinaRepository()
        ..onList = (_) async => const Success(<VacinaModel>[]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        vacina: vacina,
      );

      await c.initialize();

      expect(c.vacinas, isEmpty);
      expect(c.isLoading, isFalse);
    });

    test('registros existentes → preenchidos a partir da API', () async {
      final vacina = _FakeVacinaRepository()
        ..onList = (_) async => const Success([
          VacinaModel(id: 'uuid-real-abc', nome: 'dTpa', aplicada: true),
          VacinaModel(id: 'uuid-real-def', nome: 'HB_1', aplicada: false),
        ]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        vacina: vacina,
      );

      await c.initialize();

      expect(c.vacinas, hasLength(2));
      expect(c.vacinaPorNome('dTpa')?.aplicada, isTrue);
      expect(c.vacinaPorNome('HB_1')?.aplicada, isFalse);
    });

    test('erro na listagem → lista vazia sem quebrar', () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        vacina: _FakeVacinaRepository()
          ..onList = (_) async => const Error(NetworkFailure()),
      );

      await c.initialize();

      expect(c.vacinas, isEmpty);
      expect(c.isLoading, isFalse);
    });
  });

  group('vacinaPorNome — associação por nome (não por posição)', () {
    test('ordem da API difere da ordem do catálogo → associação por nome', () {
      final c = makeController();
      // A API devolve em ordem arbitrária; o catálogo é HB_1..dTpa.
      c.vacinas.addAll(const [
        VacinaModel(id: 'uuid-dtpa', nome: 'dTpa', aplicada: true),
        VacinaModel(id: 'uuid-hb1', nome: 'HB_1', aplicada: false),
        VacinaModel(id: 'uuid-hb3', nome: 'HB_3', aplicada: true),
      ]);

      expect(c.vacinaPorNome('HB_1')?.id, 'uuid-hb1');
      expect(c.vacinaPorNome('HB_3')?.id, 'uuid-hb3');
      expect(c.vacinaPorNome('dTpa')?.id, 'uuid-dtpa');
      expect(c.vacinaPorNome('HB_2'), isNull);
    });
  });

  group('toggleVacina — marcar (criar na primeira alteração)', () {
    test('vacina ausente → POST cria com aplicada=true (id vazio)', () async {
      VacinaModel? recebida;
      final vacina = _FakeVacinaRepository();
      vacina.onCreate = (_, v) async {
        recebida = v;
        return Success(VacinaModel(id: 'novo-uuid', nome: v.nome, aplicada: true));
      };
      // Nenhum `onList` definido → a listagem retorna vazio: a vacina está
      // ausente na API, então o toggle deve POSTar (criar).
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        vacina: vacina,
      );
      await c.initialize();

      await c.toggleVacina('dTpa');

      expect(vacina.createCalls, 1);
      expect(vacina.updateCalls, 0);
      expect(recebida?.id, isEmpty);
      expect(recebida?.nome, 'dTpa');
      expect(recebida?.aplicada, isTrue);
    });

    test('vacina ausente + sem gestação → não cria', () async {
      final vacina = _FakeVacinaRepository();
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(null),
        ),
        vacina: vacina,
      );
      await c.initialize();

      await c.toggleVacina('dTpa');

      expect(vacina.createCalls, 0);
      expect(vacina.updateCalls, 0);
    });
  });

  group('toggleVacina — desmarcar / marcar (PUT no UUID real)', () {
    test(
      'CRÍTICO UUID vs índice: PUT usa o UUID real, nunca 0/1/índice',
      () async {
        String? idRecebido;
        final vacina = _FakeVacinaRepository();
        vacina.onUpdate = (_, v) async {
          idRecebido = v.id;
          return Success(v);
        };
        vacina.onList = (_) async => const Success([
          VacinaModel(id: 'uuid-real-abc', nome: 'HB_1', aplicada: false),
        ]);
        final c = makeController(
          perfil: _FakePerfilRepository(
            onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
          ),
          vacina: vacina,
        );
        await c.initialize();

        await c.toggleVacina('HB_1');

        expect(vacina.updateCalls, 1);
        expect(vacina.createCalls, 0);
        expect(idRecebido, 'uuid-real-abc');
        expect(idRecebido, isNot(anyOf('0', '1', '')));
      },
    );

    test('marcar: aplicada false → PUT com aplicada true', () async {
      bool? aplicadaRecebida;
      final vacina = _FakeVacinaRepository();
      vacina.onUpdate = (_, v) async {
        aplicadaRecebida = v.aplicada;
        return Success(v);
      };
      vacina.onList = (_) async => const Success([
        VacinaModel(id: 'uuid-real-abc', nome: 'dTpa', aplicada: false),
      ]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        vacina: vacina,
      );
      await c.initialize();

      await c.toggleVacina('dTpa');

      expect(vacina.updateCalls, 1);
      expect(aplicadaRecebida, isTrue);
    });

    test('desmarcar: aplicada true → PUT com aplicada false', () async {
      bool? aplicadaRecebida;
      final vacina = _FakeVacinaRepository();
      vacina.onUpdate = (_, v) async {
        aplicadaRecebida = v.aplicada;
        return Success(v);
      };
      vacina.onList = (_) async => const Success([
        VacinaModel(id: 'uuid-real-abc', nome: 'dTpa', aplicada: true),
      ]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        vacina: vacina,
      );
      await c.initialize();

      await c.toggleVacina('dTpa');

      expect(vacina.updateCalls, 1);
      expect(aplicadaRecebida, isFalse);
    });

    test('erro na mutação → não quebra', () async {
      final vacina = _FakeVacinaRepository();
      vacina.onUpdate = (_, _) async => const Error(ValidationFailure());
      vacina.onList = (_) async => const Success([
        VacinaModel(id: 'uuid-real-abc', nome: 'dTpa', aplicada: false),
      ]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        vacina: vacina,
      );
      await c.initialize();

      await c.toggleVacina('dTpa');

      expect(vacina.updateCalls, 1);
      expect(c.isLoading, isFalse);
    });

    test('double toggle → apenas uma mutação (anti split-brain)', () async {
      final completer = Completer<Result<VacinaModel, BackendFailure>>();
      final vacina = _FakeVacinaRepository();
      vacina.onUpdate = (_, _) => completer.future;
      vacina.onList = (_) async => const Success([
        VacinaModel(id: 'uuid-real-abc', nome: 'dTpa', aplicada: false),
      ]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        vacina: vacina,
      );
      await c.initialize();

      final first = c.toggleVacina('dTpa');
      final second = c.toggleVacina('dTpa');

      expect(vacina.updateCalls, 1);
      expect(vacina.createCalls, 0);

      completer.complete(const Success(
        VacinaModel(id: 'uuid-real-abc', nome: 'dTpa', aplicada: true),
      ));
      await first;
      await second;

      expect(vacina.updateCalls, 1);
    });
  });
}
