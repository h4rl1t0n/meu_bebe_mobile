import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/core/fp/failure.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/model/birth.dart';
import 'package:meu_bebe/app/model/birth_moment.dart';
import 'package:meu_bebe/app/model/expectation.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';
import 'package:meu_bebe/app/model/historico_obstetrico/historico_obstetrico_model.dart';
import 'package:meu_bebe/app/model/observations.dart';
import 'package:meu_bebe/app/model/pain_relief.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/childbirth_resume/childbirth_resume_controller.dart';
import 'package:meu_bebe/app/repositories/birth/birth_repository.dart';
import 'package:meu_bebe/app/repositories/birth_moment/birth_moment_repository.dart';
import 'package:meu_bebe/app/repositories/expectations/expectations_repository.dart';
import 'package:meu_bebe/app/repositories/historico_obstetrico/historico_obstetrico_repository.dart';
import 'package:meu_bebe/app/repositories/observations/observations_repository.dart';
import 'package:meu_bebe/app/repositories/pain_relief/pain_relief_repository.dart';
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

  int getGestacaoAtualCalls = 0;

  @override
  Future<Result<GestanteModel?, BackendFailure>> getGestante() =>
      onGetGestante!();

  @override
  Future<Result<GestacaoModel?, BackendFailure>> getGestacaoAtual() {
    getGestacaoAtualCalls++;
    return onGetGestacaoAtual!();
  }

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

class _FakeExpectationsRepository implements ExpectationsRepository {
  @override
  Future<Result<Expectation?, Failure>> getExpectations() async =>
      Success(null);

  @override
  Future<Result<Expectation, Failure>> saveExpectations({
    required Expectation expectation,
  }) => throw UnimplementedError();

  @override
  Future<Result<Expectation, Failure>> updateExpectations({
    required Expectation expectation,
  }) => throw UnimplementedError();
}

class _FakeBirthMomentRepository implements BirthMomentRepository {
  @override
  Future<Result<BirthMoment?, Failure>> getBirthMoment() async => Success(null);

  @override
  Future<Result<BirthMoment, Failure>> saveBirthMoment({
    required BirthMoment birthMoment,
  }) => throw UnimplementedError();

  @override
  Future<Result<BirthMoment, Failure>> updateBirthMoment({
    required BirthMoment birthMoment,
  }) => throw UnimplementedError();
}

class _FakeBirthRepository implements BirthRepository {
  @override
  Future<Result<Birth?, Failure>> getBirth() async => Success(null);

  @override
  Future<Result<Birth, Failure>> saveBirth({required Birth birth}) =>
      throw UnimplementedError();

  @override
  Future<Result<Birth, Failure>> updateBirth({required Birth birth}) =>
      throw UnimplementedError();
}

class _FakePainReliefRepository implements PainReliefRepository {
  @override
  Future<Result<PainRelief?, Failure>> getPainRelief() async => Success(null);

  @override
  Future<Result<PainRelief, Failure>> savePainRelief({
    required PainRelief painRelief,
  }) => throw UnimplementedError();

  @override
  Future<Result<PainRelief, Failure>> updatePainRelief({
    required PainRelief painRelief,
  }) => throw UnimplementedError();
}

class _FakeObservationsRepository implements ObservationsRepository {
  @override
  Future<Result<Observations?, Failure>> getObservations() async => Success(null);

  @override
  Future<Result<Observations, Failure>> saveObservations({
    required Observations observations,
  }) => throw UnimplementedError();

  @override
  Future<Result<Observations, Failure>> updateObservations({
    required Observations observations,
  }) => throw UnimplementedError();
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

  ChildbirthResumeController makeController({
    required _FakePerfilRepository perfil,
    _FakeHistoricoRepository? historico,
  }) {
    return ChildbirthResumeController(
      perfilRepository: perfil,
      historicoObstetricoRepository:
          historico ?? _FakeHistoricoRepository(),
      expectationsRepository: _FakeExpectationsRepository(),
      birthMomentRepository: _FakeBirthMomentRepository(),
      birthRepository: _FakeBirthRepository(),
      painReliefRepository: _FakePainReliefRepository(),
      observationsRepository: _FakeObservationsRepository(),
    );
  }

  group('ChildbirthResumeController.initialize', () {
    test('sucesso → carrega API e encerra o loading', () async {
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
      expect(c.gestante?.dataNascimento, '1995-03-20');
      expect(c.gestacao?.dataUltimaMenstruacao, '2026-01-10');
      expect(c.gestacao?.localPreNatal, 'UBS Centro');
      expect(c.historico?.pregnancyNumber, 2);
      expect(c.historico?.abortionsNumber, 0);
      expect(c.isLoading, isFalse);
    });

    test('erro (Result.Error) em um repository → não deixa loading eterno',
        () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => const Error(SessionExpiredFailure()),
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(_historico),
        ),
      );

      await c.initialize();

      expect(c.gestante, isNull);
      expect(c.gestacao?.localPreNatal, 'UBS Centro');
      expect(c.isLoading, isFalse);
    });

    test('repository que lança exceção → não deixa loading eterno', () async {
      final c = makeController(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => throw Exception('falha de rede'),
          onGetGestacaoAtual: () async => _gestacaoResult(_gestacao),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(_historico),
        ),
      );

      await c.initialize();

      expect(c.isLoading, isFalse);
    });

    test('retorno de edição → re-inicializa, encerra loading e reflete novos dados',
        () async {
      var gestacaoAtual = _gestacao;
      final perfil = _FakePerfilRepository(
        onGetGestante: () async => _gestanteResult(_gestante),
        onGetGestacaoAtual: () async => _gestacaoResult(gestacaoAtual),
      );
      final c = makeController(
        perfil: perfil,
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(_historico),
        ),
      );

      await c.initialize();
      expect(c.gestacao?.localPreNatal, 'UBS Centro');
      expect(c.isLoading, isFalse);

      // Usuário editou e voltou: o pushNamed(...).then chama initialize de novo.
      gestacaoAtual = const GestacaoModel(id: 'ges1', localPreNatal: 'UBS Editada');
      await c.initialize();

      expect(perfil.getGestacaoAtualCalls, 2);
      expect(c.gestacao?.localPreNatal, 'UBS Editada');
      expect(c.isLoading, isFalse);
    });
  });
}
