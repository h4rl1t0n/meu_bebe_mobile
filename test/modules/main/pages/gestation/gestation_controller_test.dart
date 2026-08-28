import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/core/fp/failure.dart';
import 'package:meu_bebe/app/model/appointment.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/model/exam.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';
import 'package:meu_bebe/app/model/historico_obstetrico/historico_obstetrico_model.dart';
import 'package:meu_bebe/app/modules/main/pages/gestation/gestation_controller.dart';
import 'package:meu_bebe/app/repositories/appointments/appointments_repository.dart';
import 'package:meu_bebe/app/repositories/exams/exams_repository.dart';
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

class _FakeAppointmentsRepository implements AppointmentsRepository {
  @override
  Future<Result<List<Appointment>, Failure>> getAppointments() async =>
      const Success([]);

  @override
  Future<Result<Appointment, Failure>> saveAppointment({
    required Appointment appointment,
  }) => throw UnimplementedError();

  @override
  Future<Result<bool, Failure>> deleteAppointment({required int id}) =>
      throw UnimplementedError();
}

class _FakeExamsRepository implements ExamsRepository {
  @override
  Future<Result<List<Exam>, Failure>> getExams() async => const Success([]);

  @override
  Future<Result<Exam, Failure>> saveExam({required Exam exam}) =>
      throw UnimplementedError();

  @override
  Future<Result<bool, Failure>> deleteExam({required int id}) =>
      throw UnimplementedError();
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
  }) {
    return GestationController(
      perfil ?? _FakePerfilRepository(),
      historico ?? _FakeHistoricoRepository(),
      _FakeAppointmentsRepository(),
      _FakeExamsRepository(),
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
      // O valor antigo (SQLite PregnantData) não existe mais como dependência
      // do controlador; a fonte única é PerfilRepository.getGestacaoAtual.
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
      // Sem leitura legada: o controlador não expõe PregnantData nem lê o
      // repositório SQLite. A única origem é a API.
      expect(c.gestante?.nome, 'Maria Silva');
    });
  });
}
