import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/model/consulta/consulta_model.dart';
import 'package:meu_bebe/app/model/exame/exame_model.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';
import 'package:meu_bebe/app/model/historico_obstetrico/historico_obstetrico_model.dart';
import 'package:meu_bebe/app/modules/main/pages/gestation/gestation_controller.dart';
import 'package:meu_bebe/app/repositories/consulta/consulta_repository.dart';
import 'package:meu_bebe/app/repositories/exame/exame_repository.dart';
import 'package:meu_bebe/app/repositories/historico_obstetrico/historico_obstetrico_repository.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:multiple_result/multiple_result.dart';

const _gestante = GestanteModel(
  id: 'g1',
  nome: 'Maria Silva',
  nomeSocial: 'Má',
  dataNascimento: '1995-03-20',
  cns: '898 0000 0000 0000',
);

const _gestacao = GestacaoModel(
  id: 'ges1',
  dataUltimaMenstruacao: '2026-01-10',
  localPreNatal: 'UBS Centro',
  profissionalPreNatal: 'Dra. Ana',
  contatoLocalPreNatal: '(92) 99999-0000',
);

const _historico = HistoricoObstetricoModel(
  id: 'hist-1',
  pregnancyNumber: 2,
  givenBirthNumber: 1,
  abortionsNumber: 0,
);

class _FakePerfilRepository implements PerfilRepository {
  _FakePerfilRepository({this.onGetGestante, this.onGetGestacaoAtual});

  Future<Result<GestanteModel?, BackendFailure>> Function()? onGetGestante;
  Future<Result<GestacaoModel?, BackendFailure>> Function()? onGetGestacaoAtual;

  @override
  Future<Result<GestanteModel?, BackendFailure>> getGestante() =>
      onGetGestante!();

  @override
  Future<Result<GestacaoModel?, BackendFailure>> getGestacaoAtual() =>
      onGetGestacaoAtual!();

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

class _FakeHistoricoRepository implements HistoricoObstetricoRepository {
  _FakeHistoricoRepository({this.onGet});

  Future<Result<HistoricoObstetricoModel?, BackendFailure>> Function()? onGet;

  @override
  Future<Result<HistoricoObstetricoModel?, BackendFailure>> getHistorico() =>
      onGet!();

  @override
  Future<Result<HistoricoObstetricoModel, BackendFailure>> saveHistorico(
    HistoricoObstetricoModel historico,
  ) => throw UnimplementedError();
}

class _FakeConsultaRepository implements ConsultaRepository {
  _FakeConsultaRepository({this.onList});

  Future<Result<List<ConsultaModel>, BackendFailure>> Function(String)? onList;

  @override
  Future<Result<List<ConsultaModel>, BackendFailure>> listConsultas(
    String gestacaoId,
  ) =>
      onList?.call(gestacaoId) ??
      Future.value(Success<List<ConsultaModel>, BackendFailure>([]));

  @override
  Future<Result<ConsultaModel, BackendFailure>> createConsulta(
    String gestacaoId,
    ConsultaModel consulta,
  ) => throw UnimplementedError();

  @override
  Future<Result<ConsultaModel, BackendFailure>> updateConsulta(
    String gestacaoId,
    ConsultaModel consulta,
  ) => throw UnimplementedError();

  @override
  Future<Result<bool, BackendFailure>> deleteConsulta(
    String gestacaoId,
    String consultaId,
  ) => throw UnimplementedError();
}

class _FakeExameRepository implements ExameRepository {
  _FakeExameRepository({this.onList});

  Future<Result<List<ExameModel>, BackendFailure>> Function(String)? onList;

  @override
  Future<Result<List<ExameModel>, BackendFailure>> listExames(
    String gestacaoId,
  ) =>
      onList?.call(gestacaoId) ??
      Future.value(Success<List<ExameModel>, BackendFailure>([]));

  @override
  Future<Result<ExameModel, BackendFailure>> createExame(
    String gestacaoId,
    ExameModel exame,
  ) => throw UnimplementedError();

  @override
  Future<Result<ExameModel, BackendFailure>> updateExame(
    String gestacaoId,
    ExameModel exame,
  ) => throw UnimplementedError();

  @override
  Future<Result<bool, BackendFailure>> deleteExame(
    String gestacaoId,
    String exameId,
  ) => throw UnimplementedError();
}

Result<GestanteModel?, BackendFailure> _gestanteResult(GestanteModel? g) =>
    Success<GestanteModel?, BackendFailure>(g);

Result<GestacaoModel?, BackendFailure> _gestacaoResult(GestacaoModel? g) =>
    Success<GestacaoModel?, BackendFailure>(g);

Result<HistoricoObstetricoModel?, BackendFailure> _historicoResult(
  HistoricoObstetricoModel? h,
) => Success<HistoricoObstetricoModel?, BackendFailure>(h);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GestationController makeController({
    _FakePerfilRepository? perfil,
    _FakeHistoricoRepository? historico,
    _FakeConsultaRepository? consulta,
    _FakeExameRepository? exame,
  }) {
    return GestationController(
      perfil ?? _FakePerfilRepository(),
      historico ?? _FakeHistoricoRepository(),
      consulta ?? _FakeConsultaRepository(),
      exame ?? _FakeExameRepository(),
    );
  }

  group('GestationController.initialize', () {
    test('carrega gestante, gestação e histórico exclusivamente da API',
        () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => _gestanteResult(_gestante),
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(_historico),
        ),
      );

      await c.initialize();

      expect(c.gestante?.nome, 'Maria Silva');
      expect(c.gestacao?.localPreNatal, 'UBS Centro');
      expect(c.gestacao?.dataUltimaMenstruacao, '2026-01-10');
      expect(c.historico?.pregnancyNumber, 2);
      expect(c.isLoading, isFalse);
    });

    test('404/erro → domínios null sem quebrar a tela', () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => const Error(SessionExpiredFailure()),
          onGetGestacaoAtual: () async => _gestacaoResult(null),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(null),
        ),
      );

      await c.initialize();

      expect(c.gestante, isNull);
      expect(c.gestacao, isNull);
      expect(c.historico, isNull);
      expect(c.isLoading, isFalse);
    });

    test('sem gestação ativa → consultas/exames vazios (não lista 404)', () async {
      final consulta = _FakeConsultaRepository();
      final exame = _FakeExameRepository();
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => _gestanteResult(_gestante),
          onGetGestacaoAtual: () async => _gestacaoResult(null),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(_historico),
        ),
        consulta: consulta,
        exame: exame,
      );

      await c.initialize();

      expect(c.appointments, isEmpty);
      expect(c.exams, isEmpty);
      expect(c.isLoading, isFalse);
    });
  });

  group('consultas/exames — fonte de verdade é a API', () {
    test('lista e formata as consultas/exames da API', () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => _gestanteResult(_gestante),
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(_historico),
        ),
        consulta: _FakeConsultaRepository(
          onList: (_) async => const Success([
            ConsultaModel(
              id: 'c1',
              titulo: 'Pré-natal',
              dataConsulta: '2025-11-01',
              descricao: 'Rotina',
            ),
          ]),
        ),
        exame: _FakeExameRepository(
          onList: (_) async => const Success([
            ExameModel(
              id: 'e1',
              titulo: 'Ultrassom',
              dataExame: '2025-10-01',
              descricao: 'Obstétrico',
              categoria: 'ultrassom',
            ),
          ]),
        ),
      );

      await c.initialize();

      expect(c.appointments, ['Pré-natal - 01/11/2025']);
      expect(c.exams, ['Ultrassom - 01/10/2025']);
    });

    test('anti split-brain: o controlador não depende de SQLite para consultas/exames',
        () async {
      // O GestationController só conhece ConsultaRepository/ExameRepository
      // (API). Não há mais leitura do SQLite (Appointments/Exams legados).
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => _gestanteResult(_gestante),
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(_historico),
        ),
        consulta: _FakeConsultaRepository(
          onList: (_) async => const Success([
            ConsultaModel(
              id: 'c1',
              titulo: 'Consulta API',
              dataConsulta: '2025-11-01',
              descricao: 'x',
            ),
          ]),
        ),
      );

      await c.initialize();

      expect(c.appointments, contains('Consulta API - 01/11/2025'));
    });
  });

  group('historyItems — null ≠ 0', () {
    test('null → "Sem dados" (nunca vira zero)', () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => _gestanteResult(_gestante),
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(
            const HistoricoObstetricoModel(id: 'h', pregnancyNumber: null),
          ),
        ),
      );

      await c.initialize();

      expect(c.historyItems, [
        'Gravidezes anteriores: Sem dados',
        'Partos anteriores: Sem dados',
        'Abortos: Sem dados',
      ]);
    });

    test('0 → "0" (zero é um valor, não ausência)', () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => _gestanteResult(_gestante),
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(
            const HistoricoObstetricoModel(
              id: 'h',
              pregnancyNumber: 0,
              givenBirthNumber: 0,
              abortionsNumber: 0,
            ),
          ),
        ),
      );

      await c.initialize();

      expect(c.historyItems, [
        'Gravidezes anteriores: 0',
        'Partos anteriores: 0',
        'Abortos: 0',
      ]);
    });
  });

  group('split-brain (API-novo vs SQLite-antigo)', () {
    test('a API é a única fonte de verdade do pré-natal', () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => _gestanteResult(_gestante),
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(_historico),
        ),
      );

      await c.initialize();

      expect(c.gestacao?.localPreNatal, 'UBS Centro');
      expect(c.gestacao?.profissionalPreNatal, 'Dra. Ana');
      expect(c.gestacao?.contatoLocalPreNatal, '(92) 99999-0000');
      expect(c.gestante?.nome, 'Maria Silva');
    });
  });
}
