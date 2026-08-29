import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';
import 'package:meu_bebe/app/model/medicamento/medicamento_model.dart';
import 'package:meu_bebe/app/modules/main/pages/home/submodules/medication/medication_controller.dart';
import 'package:meu_bebe/app/repositories/medicamento/medicamento_repository.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:multiple_result/multiple_result.dart';

const _gestacao = GestacaoModel(
  id: 'ges-1',
  dataUltimaMenstruacao: '2026-01-10',
);

const _med = MedicamentoModel(
  id: 'm1',
  nome: 'Ácido fólico',
  dose: '5mg',
  frequencia: '1 vez ao dia',
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

class _FakeMedicamentoRepository implements MedicamentoRepository {
  Future<Result<List<MedicamentoModel>, BackendFailure>> Function(String)? onList;
  Future<Result<MedicamentoModel, BackendFailure>> Function(
    String,
    MedicamentoModel,
  )?
  onCreate;
  Future<Result<bool, BackendFailure>> Function(String, String)? onDelete;

  int listCalls = 0;
  int createCalls = 0;
  int deleteCalls = 0;

  @override
  Future<Result<List<MedicamentoModel>, BackendFailure>> listMedicamentos(
    String gestacaoId,
  ) {
    listCalls++;
    return onList?.call(gestacaoId) ??
        Future.value(Success<List<MedicamentoModel>, BackendFailure>([]));
  }

  @override
  Future<Result<MedicamentoModel, BackendFailure>> createMedicamento(
    String gestacaoId,
    MedicamentoModel medicamento,
  ) {
    createCalls++;
    return onCreate?.call(gestacaoId, medicamento) ??
        Future.value(const Success(_med));
  }

  @override
  Future<Result<MedicamentoModel, BackendFailure>> updateMedicamento(
    String gestacaoId,
    MedicamentoModel medicamento,
  ) => throw UnimplementedError();

  @override
  Future<Result<bool, BackendFailure>> deleteMedicamento(
    String gestacaoId,
    String medicamentoId,
  ) {
    deleteCalls++;
    return onDelete?.call(gestacaoId, medicamentoId) ??
        Future.value(const Success(true));
  }
}

Result<GestacaoModel?, BackendFailure> _gestacaoResult(GestacaoModel? g) =>
    Success<GestacaoModel?, BackendFailure>(g);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MedicationController makeController({
    _FakePerfilRepository? perfil,
    _FakeMedicamentoRepository? medicamento,
  }) {
    return MedicationController(
      perfil ?? _FakePerfilRepository(),
      medicamento ?? _FakeMedicamentoRepository(),
    );
  }

  group('initialize', () {
    test('loading → com gestação ativa, hasGestacao=true e isLoading=false',
        () async {
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
      final medicamento = _FakeMedicamentoRepository();
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(null),
        ),
        medicamento: medicamento,
      );

      await c.initialize();

      expect(c.hasGestacao, isFalse);
      expect(c.medications, isEmpty);
      expect(medicamento.listCalls, 0);
      expect(c.isLoading, isFalse);
    });

    test('erro ao resolver gestação → hasGestacao=false sem quebrar', () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => const Error(SessionExpiredFailure()),
        ),
      );

      await c.initialize();

      expect(c.hasGestacao, isFalse);
      expect(c.isLoading, isFalse);
    });

    test('lista preenchida a partir da API (fonte de verdade)', () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        medicamento: _FakeMedicamentoRepository()
          ..onList = (_) async => const Success([_med]),
      );

      await c.initialize();

      expect(c.medications, hasLength(1));
      expect(c.medications.first.id, 'm1');
      expect(c.medications.first.nome, 'Ácido fólico');
    });

    test('erro na listagem → lista vazia sem quebrar', () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        medicamento: _FakeMedicamentoRepository()
          ..onList = (_) async => const Error(NetworkFailure()),
      );

      await c.initialize();

      expect(c.medications, isEmpty);
      expect(c.isLoading, isFalse);
    });
  });

  group('saveMedication', () {
    test('sucesso → cria via API e recarrega a lista', () async {
      final medicamento = _FakeMedicamentoRepository()
        ..onList = (_) async => const Success([_med]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        medicamento: medicamento,
      );
      await c.initialize();
      final listBefore = medicamento.listCalls;

      await c.saveMedication(_med);

      expect(medicamento.createCalls, 1);
      expect(medicamento.listCalls, greaterThan(listBefore));
      expect(c.medications, hasLength(1));
      expect(c.isLoading, isFalse);
    });

    test('sem gestação → não cria (lista segue vazia)', () async {
      final medicamento = _FakeMedicamentoRepository();
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(null),
        ),
        medicamento: medicamento,
      );
      await c.initialize();

      await c.saveMedication(_med);

      expect(medicamento.createCalls, 0);
      expect(c.medications, isEmpty);
    });

    test('erro → não quebra e preserva a lista anterior', () async {
      final medicamento = _FakeMedicamentoRepository();
      medicamento.onCreate = (_, _) async => const Error(ValidationFailure());
      medicamento.onList = (_) async => const Success([_med]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        medicamento: medicamento,
      );
      await c.initialize();
      final listBefore = medicamento.listCalls;

      await c.saveMedication(_med);

      expect(medicamento.createCalls, 1);
      expect(medicamento.listCalls, listBefore);
      expect(c.medications, hasLength(1));
      expect(c.isLoading, isFalse);
    });

    test('double submit → apenas uma criação', () async {
      final completer = Completer<Result<MedicamentoModel, BackendFailure>>();
      final medicamento = _FakeMedicamentoRepository();
      medicamento.onCreate = (_, _) => completer.future;
      medicamento.onList = (_) async => const Success([_med]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        medicamento: medicamento,
      );
      await c.initialize();

      final first = c.saveMedication(_med);
      final second = c.saveMedication(_med);

      expect(medicamento.createCalls, 1);

      completer.complete(const Success(_med));
      await first;
      await second;

      expect(medicamento.createCalls, 1);
    });
  });

  group('deleteMedication', () {
    test('sucesso → deleta via API (UUID) e recarrega', () async {
      final medicamento = _FakeMedicamentoRepository()
        ..onList = (_) async => const Success([_med]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        medicamento: medicamento,
      );
      await c.initialize();
      final listBefore = medicamento.listCalls;

      await c.deleteMedication('m1');

      expect(medicamento.deleteCalls, 1);
      expect(medicamento.listCalls, greaterThan(listBefore));
      expect(c.isLoading, isFalse);
    });

    test('double delete → apenas uma exclusão', () async {
      final completer = Completer<Result<bool, BackendFailure>>();
      final medicamento = _FakeMedicamentoRepository();
      medicamento.onDelete = (_, _) => completer.future;
      medicamento.onList = (_) async => const Success(<MedicamentoModel>[]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        medicamento: medicamento,
      );
      await c.initialize();

      final first = c.deleteMedication('m1');
      final second = c.deleteMedication('m1');

      expect(medicamento.deleteCalls, 1);

      completer.complete(const Success(true));
      await first;
      await second;

      expect(medicamento.deleteCalls, 1);
    });
  });
}
