import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_enums.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_model.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/pain_relief/pain_relief_controller.dart';
import 'package:multiple_result/multiple_result.dart';

import '../plano_parto_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PainReliefController.initialize', () {
    test('plano existente → carrega', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(querAlivioDor: 'sim'),
        ),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = PainReliefController(planoRepo, perfil);

      await c.initialize();

      expect(c.hasGestacao, isTrue);
      expect(c.plano?.querAlivioDor, 'sim');
      expect(c.querAlivioDor, TriState.sim);
      expect(c.isLoading, isFalse);
    });
  });

  group('PainReliefController.savePainRelief', () {
    test('salva os métodos e preserva as demais seções', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(observacoes: 'nota'),
        ),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = PainReliefController(planoRepo, perfil);
      await c.initialize();

      c.setQuerAlivioDor(TriState.sim);
      c.setMassagem(true);
      c.setExerciciosBola(true);
      c.setExerciciosRespiracao(false);
      c.setBanhoChuveiro(true);
      c.setBanhoBanheira(false);
      c.setAcupuntura(false);
      c.setAcupressao(true);
      c.setOutroMetodo(false);
      await c.savePainRelief();

      final sent = planoRepo.lastUpserted!;
      expect(sent.querAlivioDor, 'sim');
      expect(sent.massagem, isTrue);
      expect(sent.exerciciosBola, isTrue);
      expect(sent.exerciciosRespiracao, isFalse);
      expect(sent.banhoChuveiro, isTrue);
      expect(sent.banhoBanheira, isFalse);
      expect(sent.acupuntura, isFalse);
      expect(sent.acupressao, isTrue);
      expect(sent.outroMetodo, isFalse);
      // Demais seções preservadas.
      expect(sent.observacoes, 'nota');
      expect(sent.acompanhante, 'nao_sei');
      expect(c.saved, isTrue);
    });

    test('erro no PUT → saved false', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Success(null),
        onUpsert: (_, _) async => const Error(ValidationFailure()),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = PainReliefController(planoRepo, perfil);
      await c.initialize();

      c.setQuerAlivioDor(TriState.nao);
      c.setMassagem(false);
      c.setExerciciosBola(false);
      c.setExerciciosRespiracao(false);
      c.setBanhoChuveiro(false);
      c.setBanhoBanheira(false);
      c.setAcupuntura(false);
      c.setAcupressao(false);
      c.setOutroMetodo(false);
      await c.savePainRelief();

      expect(c.saved, isFalse);
    });

    test('erro no GET → save bloqueado (não chama o PUT)', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Error(NetworkFailure()),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = PainReliefController(planoRepo, perfil);
      await c.initialize();

      c.setQuerAlivioDor(TriState.nao);
      c.setMassagem(false);
      c.setExerciciosBola(false);
      c.setExerciciosRespiracao(false);
      c.setBanhoChuveiro(false);
      c.setBanhoBanheira(false);
      c.setAcupuntura(false);
      c.setAcupressao(false);
      c.setOutroMetodo(false);
      await c.savePainRelief();

      expect(planoRepo.upsertCalls, 0);
      expect(c.saved, isFalse);
    });
  });
}
