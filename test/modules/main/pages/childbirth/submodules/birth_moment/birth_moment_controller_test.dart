import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_enums.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_model.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/birth_moment/birth_moment_controller.dart';
import 'package:multiple_result/multiple_result.dart';

import '../plano_parto_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BirthMomentController.initialize', () {
    test('plano existente → carrega', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(viaParto: 'vaginal'),
        ),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = BirthMomentController(planoRepo, perfil);

      await c.initialize();

      expect(c.hasGestacao, isTrue);
      expect(c.plano?.viaParto, 'vaginal');
      expect(c.isLoading, isFalse);
    });

    test('sem gestação → não lê o plano', () async {
      final planoRepo = FakePlanoPartoRepository();
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(null),
      );
      final c = BirthMomentController(planoRepo, perfil);

      await c.initialize();

      expect(c.hasGestacao, isFalse);
      expect(c.plano, isNull);
      expect(planoRepo.getCalls, 0);
    });
  });

  group('BirthMomentController.saveBirthMoment', () {
    test('salva posição "outra" com texto e preserva demais seções', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(
            acompanhante: 'sim',
            observacoes: 'nota',
          ),
        ),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = BirthMomentController(planoRepo, perfil);
      await c.initialize();

      await c.saveBirthMoment(
        viaParto: ViaParto.cesarea,
        anestesia: TriState.sim,
        corteVaginal: TriState.nao,
        posicaoPreferida: PosicaoParto.outra,
        outraPosicao: 'De cócoras',
      );

      final sent = planoRepo.lastUpserted!;
      expect(sent.viaParto, 'cesarea');
      expect(sent.anestesia, 'sim');
      expect(sent.corteVaginal, 'nao');
      expect(sent.posicaoPreferida, 'outra');
      expect(sent.outraPosicao, 'De cócoras');
      // Demais seções preservadas.
      expect(sent.acompanhante, 'sim');
      expect(sent.observacoes, 'nota');
      expect(c.saved, isTrue);
    });

    test('posição sem "outra" → outraPosicao null', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Success(null),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = BirthMomentController(planoRepo, perfil);
      await c.initialize();

      await c.saveBirthMoment(
        viaParto: ViaParto.vaginal,
        anestesia: TriState.naoSei,
        corteVaginal: TriState.naoSei,
        posicaoPreferida: PosicaoParto.deitada,
        outraPosicao: null,
      );

      final sent = planoRepo.lastUpserted!;
      expect(sent.posicaoPreferida, 'deitada');
      expect(sent.outraPosicao, isNull);
    });

    test('erro no PUT → saved false', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Success(null),
        onUpsert: (_, _) async => const Error(UnexpectedFailure()),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = BirthMomentController(planoRepo, perfil);
      await c.initialize();

      await c.saveBirthMoment(
        viaParto: ViaParto.vaginal,
        anestesia: TriState.sim,
        corteVaginal: TriState.nao,
      );

      expect(c.saved, isFalse);
    });

    test('erro no GET → save bloqueado (não chama o PUT)', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Error(NetworkFailure()),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = BirthMomentController(planoRepo, perfil);
      await c.initialize();

      await c.saveBirthMoment(
        viaParto: ViaParto.vaginal,
        anestesia: TriState.sim,
        corteVaginal: TriState.nao,
      );

      expect(planoRepo.upsertCalls, 0);
      expect(c.saved, isFalse);
    });
  });
}
