import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/model/consulta/consulta_model.dart';
import 'package:meu_bebe/app/model/exame/exame_categoria.dart';
import 'package:meu_bebe/app/model/exame/exame_model.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';
import 'package:meu_bebe/app/modules/main/pages/home/submodules/appointments_exams/appointments_exams_controller.dart';
import 'package:meu_bebe/app/repositories/consulta/consulta_repository.dart';
import 'package:meu_bebe/app/repositories/exame/exame_repository.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:multiple_result/multiple_result.dart';

const _gestacao = GestacaoModel(
  id: 'ges-1',
  dataUltimaMenstruacao: '2026-01-10',
);

const _consulta = ConsultaModel(
  id: 'c1',
  titulo: 'Pré-natal',
  dataConsulta: '2025-11-01',
  descricao: 'Rotina',
);

const _exame = ExameModel(
  id: 'e1',
  titulo: 'Ultrassom',
  dataExame: '2025-10-01',
  descricao: 'Obstétrico',
  categoria: 'ultrassom',
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

class _FakeConsultaRepository implements ConsultaRepository {
  Future<Result<List<ConsultaModel>, BackendFailure>> Function(String)? onList;
  Future<Result<ConsultaModel, BackendFailure>> Function(String, ConsultaModel)?
  onCreate;
  Future<Result<bool, BackendFailure>> Function(String, String)? onDelete;

  int listCalls = 0;
  int createCalls = 0;
  int deleteCalls = 0;

  @override
  Future<Result<List<ConsultaModel>, BackendFailure>> listConsultas(
    String gestacaoId,
  ) {
    listCalls++;
    return onList?.call(gestacaoId) ??
        Future.value(Success<List<ConsultaModel>, BackendFailure>([]));
  }

  @override
  Future<Result<ConsultaModel, BackendFailure>> createConsulta(
    String gestacaoId,
    ConsultaModel consulta,
  ) {
    createCalls++;
    return onCreate?.call(gestacaoId, consulta) ??
        Future.value(const Success(_consulta));
  }

  @override
  Future<Result<ConsultaModel, BackendFailure>> updateConsulta(
    String gestacaoId,
    ConsultaModel consulta,
  ) => throw UnimplementedError();

  @override
  Future<Result<bool, BackendFailure>> deleteConsulta(
    String gestacaoId,
    String consultaId,
  ) {
    deleteCalls++;
    return onDelete?.call(gestacaoId, consultaId) ??
        Future.value(const Success(true));
  }
}

class _FakeExameRepository implements ExameRepository {
  Future<Result<List<ExameModel>, BackendFailure>> Function(String)? onList;
  Future<Result<ExameModel, BackendFailure>> Function(String, ExameModel)?
  onCreate;
  Future<Result<bool, BackendFailure>> Function(String, String)? onDelete;

  int listCalls = 0;
  int createCalls = 0;
  int deleteCalls = 0;

  @override
  Future<Result<List<ExameModel>, BackendFailure>> listExames(
    String gestacaoId,
  ) {
    listCalls++;
    return onList?.call(gestacaoId) ??
        Future.value(Success<List<ExameModel>, BackendFailure>([]));
  }

  @override
  Future<Result<ExameModel, BackendFailure>> createExame(
    String gestacaoId,
    ExameModel exame,
  ) {
    createCalls++;
    return onCreate?.call(gestacaoId, exame) ??
        Future.value(const Success(_exame));
  }

  @override
  Future<Result<ExameModel, BackendFailure>> updateExame(
    String gestacaoId,
    ExameModel exame,
  ) => throw UnimplementedError();

  @override
  Future<Result<bool, BackendFailure>> deleteExame(
    String gestacaoId,
    String exameId,
  ) {
    deleteCalls++;
    return onDelete?.call(gestacaoId, exameId) ??
        Future.value(const Success(true));
  }
}

Result<GestacaoModel?, BackendFailure> _gestacaoResult(GestacaoModel? g) =>
    Success<GestacaoModel?, BackendFailure>(g);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppointmentsExamsController makeController({
    _FakePerfilRepository? perfil,
    _FakeConsultaRepository? consulta,
    _FakeExameRepository? exame,
  }) {
    return AppointmentsExamsController(
      perfil ?? _FakePerfilRepository(),
      consulta ?? _FakeConsultaRepository(),
      exame ?? _FakeExameRepository(),
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

    test(
      'sem gestação ativa (Success(null)) → hasGestacao=false e listas vazias',
      () async {
        final consulta = _FakeConsultaRepository();
        final exame = _FakeExameRepository();
        final c = makeController(
          perfil: _FakePerfilRepository(
            onGetGestacaoAtual: () async => _gestacaoResult(null),
          ),
          consulta: consulta,
          exame: exame,
        );

        await c.initialize();

        expect(c.hasGestacao, isFalse);
        expect(c.appointments, isEmpty);
        expect(c.exams, isEmpty);
        expect(consulta.listCalls, 0);
        expect(exame.listCalls, 0);
        expect(c.isLoading, isFalse);
      },
    );

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

    test('listas preenchidas a partir da API (fonte de verdade)', () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        consulta: _FakeConsultaRepository()
          ..onList = (_) async => const Success([_consulta]),
        exame: _FakeExameRepository()
          ..onList = (_) async => const Success([_exame]),
      );

      await c.initialize();

      expect(c.appointments, hasLength(1));
      expect(c.appointments.first.id, 'c1');
      expect(c.exams, hasLength(1));
      expect(c.exams.first.categoria, 'ultrassom');
    });

    test('erro na listagem → listas vazias sem quebrar', () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        consulta: _FakeConsultaRepository()
          ..onList = (_) async => const Error(NetworkFailure()),
        exame: _FakeExameRepository()
          ..onList = (_) async => const Error(NetworkFailure()),
      );

      await c.initialize();

      expect(c.appointments, isEmpty);
      expect(c.exams, isEmpty);
      expect(c.isLoading, isFalse);
    });
  });

  group('saveAppointment', () {
    test(
      'sucesso → cria via API e recarrega a lista (conteúdo visível)',
      () async {
        final consulta = _FakeConsultaRepository()
          ..onList = (_) async => const Success([_consulta]);
        final c = makeController(
          perfil: _FakePerfilRepository(
            onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
          ),
          consulta: consulta,
        );
        await c.initialize();
        final listBefore = consulta.listCalls;

        await c.saveAppointment(_consulta);

        expect(consulta.createCalls, 1);
        expect(consulta.listCalls, greaterThan(listBefore));
        expect(c.appointments, hasLength(1));
        expect(c.appointments.first.id, 'c1');
        expect(c.isLoading, isFalse);
      },
    );

    test('erro → não quebra e preserva a lista anterior', () async {
      final consulta = _FakeConsultaRepository();
      consulta.onCreate = (_, _) async => const Error(ValidationFailure());
      consulta.onList = (_) async => const Success([_consulta]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        consulta: consulta,
      );
      await c.initialize();
      final listBefore = consulta.listCalls;

      await c.saveAppointment(_consulta);

      expect(consulta.createCalls, 1);
      expect(consulta.listCalls, listBefore);
      expect(c.appointments, hasLength(1));
      expect(c.isLoading, isFalse);
    });

    test('double submit → apenas uma criação', () async {
      final completer = Completer<Result<ConsultaModel, BackendFailure>>();
      final consulta = _FakeConsultaRepository();
      consulta.onCreate = (_, _) => completer.future;
      consulta.onList = (_) async => const Success([_consulta]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        consulta: consulta,
      );
      await c.initialize();

      final first = c.saveAppointment(_consulta);
      final second = c.saveAppointment(_consulta);

      expect(consulta.createCalls, 1);

      completer.complete(const Success(_consulta));
      await first;
      await second;

      expect(consulta.createCalls, 1);
    });
  });

  group('deleteAppointment', () {
    test(
      'sucesso → deleta via API (UUID) e recarrega (lista visível)',
      () async {
        final consulta = _FakeConsultaRepository()
          ..onList = (_) async => const Success([_consulta]);
        final c = makeController(
          perfil: _FakePerfilRepository(
            onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
          ),
          consulta: consulta,
        );
        await c.initialize();
        final listBefore = consulta.listCalls;

        await c.deleteAppointment('c1');

        expect(consulta.deleteCalls, 1);
        expect(consulta.listCalls, greaterThan(listBefore));
        expect(c.appointments, hasLength(1));
        expect(c.isLoading, isFalse);
      },
    );

    test('double delete → apenas uma exclusão', () async {
      final completer = Completer<Result<bool, BackendFailure>>();
      final consulta = _FakeConsultaRepository();
      consulta.onDelete = (_, _) => completer.future;
      consulta.onList = (_) async => const Success(<ConsultaModel>[]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        consulta: consulta,
      );
      await c.initialize();

      final first = c.deleteAppointment('c1');
      final second = c.deleteAppointment('c1');

      expect(consulta.deleteCalls, 1);

      completer.complete(const Success(true));
      await first;
      await second;

      expect(consulta.deleteCalls, 1);
    });
  });

  group('saveExam / deleteExam', () {
    test('sucesso → cria exame via API (conteúdo visível)', () async {
      final exame = _FakeExameRepository()
        ..onList = (_) async => const Success([_exame]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        exame: exame,
      );
      await c.initialize();
      final listBefore = exame.listCalls;

      await c.saveExam(_exame);

      expect(exame.createCalls, 1);
      expect(exame.listCalls, greaterThan(listBefore));
      expect(c.exams, hasLength(1));
      expect(c.exams.first.categoria, 'ultrassom');
      expect(c.isLoading, isFalse);
    });

    test(
      'selecionar Ultrassom → createExame recebe categoria "ultrassom"',
      () async {
        ExameModel? recebido;
        final exame = _FakeExameRepository();
        exame.onCreate = (_, e) async {
          recebido = e;
          return const Success(_exame);
        };
        final c = makeController(
          perfil: _FakePerfilRepository(
            onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
          ),
          exame: exame,
        );
        await c.initialize();

        await c.saveExam(
          ExameModel(
            id: '',
            titulo: 'USG obstétrica',
            dataExame: '2026-08-20',
            descricao: 'Obstétrico',
            categoria: CategoriaExame.ultrassom.code,
          ),
        );

        expect(exame.createCalls, 1);
        expect(recebido?.categoria, CategoriaExame.ultrassom.code);
        expect(recebido?.categoria, 'ultrassom');
      },
    );

    test('sucesso → deleta exame via API (lista visível)', () async {
      final exame = _FakeExameRepository()
        ..onList = (_) async => const Success([_exame]);
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        exame: exame,
      );
      await c.initialize();
      final listBefore = exame.listCalls;

      await c.deleteExam('e1');

      expect(exame.deleteCalls, 1);
      expect(exame.listCalls, greaterThan(listBefore));
      expect(c.exams, hasLength(1));
      expect(c.isLoading, isFalse);
    });
  });
}
