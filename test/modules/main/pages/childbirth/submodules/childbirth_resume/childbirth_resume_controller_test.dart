import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/exame/exame_model.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/historico_obstetrico/historico_obstetrico_model.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_model.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/childbirth_resume/childbirth_resume_controller.dart';
import 'package:meu_bebe/app/repositories/exame/exame_repository.dart';
import 'package:meu_bebe/app/repositories/historico_obstetrico/historico_obstetrico_repository.dart';
import 'package:multiple_result/multiple_result.dart';

import '../plano_parto_test_helpers.dart';

const _historico = HistoricoObstetricoModel(
  id: 'hist-1',
  pregnancyNumber: 2,
  givenBirthNumber: 1,
  abortionsNumber: 0,
);

class _FakeHistoricoRepository implements HistoricoObstetricoRepository {
  _FakeHistoricoRepository({this.onGet});

  Future<Result<HistoricoObstetricoModel?, BackendFailure>> Function()? onGet;

  @override
  Future<Result<HistoricoObstetricoModel?, BackendFailure>> getHistorico() =>
      onGet?.call() ??
      Future.value(const Success<HistoricoObstetricoModel?, BackendFailure>(
        null,
      ));

  @override
  Future<Result<HistoricoObstetricoModel, BackendFailure>> saveHistorico(
    HistoricoObstetricoModel historico,
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
      Future.value(const Success<List<ExameModel>, BackendFailure>([]));

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

Result<HistoricoObstetricoModel?, BackendFailure> _historicoResult(
  HistoricoObstetricoModel? h,
) => Success<HistoricoObstetricoModel?, BackendFailure>(h);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ChildbirthResumeController makeController({
    required FakePerfilRepository perfil,
    _FakeHistoricoRepository? historico,
    _FakeExameRepository? exame,
    FakePlanoPartoRepository? plano,
  }) {
    return ChildbirthResumeController(
      perfilRepository: perfil,
      historicoObstetricoRepository:
          historico ?? _FakeHistoricoRepository(),
      exameRepository: exame ?? _FakeExameRepository(),
      planoPartoRepository: plano ?? FakePlanoPartoRepository(),
    );
  }

  group('ChildbirthResumeController.initialize', () {
    test('sucesso → carrega API e encerra o loading', () async {
      final c = makeController(
        perfil: FakePerfilRepository(
          onGetGestante: () async => gestanteResult(gestanteAtiva),
          onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
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
        perfil: FakePerfilRepository(
          onGetGestante: () async => const Error(SessionExpiredFailure()),
          onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
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
        perfil: FakePerfilRepository(
          onGetGestante: () async => throw Exception('falha de rede'),
          onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
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
      var gestacaoAtual = gestacaoAtiva;
      final perfil = FakePerfilRepository(
        onGetGestante: () async => gestanteResult(gestanteAtiva),
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtual),
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

  group('ChildbirthResumeController.firstUltrasound', () {
    test('com gestação ativa e ultrassom → data mais antiga (fonte: EXAMES)',
        () async {
      final c = makeController(
        perfil: FakePerfilRepository(
          onGetGestante: () async => gestanteResult(gestanteAtiva),
          onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(_historico),
        ),
        exame: _FakeExameRepository(
          onList: (_) async => const Success([
            ExameModel(
              id: 'e1',
              titulo: 'USG morfológica',
              dataExame: '2025-11-01',
              descricao: 'x',
              categoria: 'ultrassom',
            ),
            ExameModel(
              id: 'e2',
              titulo: 'USG inicial',
              dataExame: '2025-09-15',
              descricao: 'x',
              categoria: 'ultrassom',
            ),
          ]),
        ),
      );

      await c.initialize();

      expect(c.firstUltrasound, '2025-09-15');
      expect(c.isLoading, isFalse);
    });

    test('sem ultrassom na lista → firstUltrasound null', () async {
      final c = makeController(
        perfil: FakePerfilRepository(
          onGetGestante: () async => gestanteResult(gestanteAtiva),
          onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(_historico),
        ),
        exame: _FakeExameRepository(
          onList: (_) async => const Success([
            ExameModel(
              id: 'e1',
              titulo: 'Sangue',
              dataExame: '2025-10-01',
              descricao: 'x',
              categoria: 'sangue',
            ),
          ]),
        ),
      );

      await c.initialize();

      expect(c.firstUltrasound, isNull);
    });

    test('sem gestação ativa → firstUltrasound null (não lista exames)', () async {
      final exame = _FakeExameRepository();
      final c = makeController(
        perfil: FakePerfilRepository(
          onGetGestante: () async => gestanteResult(gestanteAtiva),
          onGetGestacaoAtual: () async => gestacaoResult(null),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(_historico),
        ),
        exame: exame,
      );

      await c.initialize();

      expect(c.firstUltrasound, isNull);
    });
  });

  group('ChildbirthResumeController.plano', () {
    test('com gestação ativa e plano → carrega o plano consolidado', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(
            viaParto: 'vaginal',
            acompanhante: 'sim',
          ),
        ),
      );
      final c = makeController(
        perfil: FakePerfilRepository(
          onGetGestante: () async => gestanteResult(gestanteAtiva),
          onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(_historico),
        ),
        plano: planoRepo,
      );

      await c.initialize();

      expect(c.plano?.viaParto, 'vaginal');
      expect(c.plano?.acompanhante, 'sim');
    });

    test('404 → plano null', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Success(null),
      );
      final c = makeController(
        perfil: FakePerfilRepository(
          onGetGestante: () async => gestanteResult(gestanteAtiva),
          onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(_historico),
        ),
        plano: planoRepo,
      );

      await c.initialize();

      expect(c.plano, isNull);
    });

    test('sem gestação ativa → plano null e não lê o plano', () async {
      final planoRepo = FakePlanoPartoRepository();
      final c = makeController(
        perfil: FakePerfilRepository(
          onGetGestante: () async => gestanteResult(gestanteAtiva),
          onGetGestacaoAtual: () async => gestacaoResult(null),
        ),
        historico: _FakeHistoricoRepository(
          onGet: () async => _historicoResult(_historico),
        ),
        plano: planoRepo,
      );

      await c.initialize();

      expect(c.plano, isNull);
      expect(planoRepo.getCalls, 0);
    });
  });
}
