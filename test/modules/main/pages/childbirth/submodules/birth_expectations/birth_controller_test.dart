import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_enums.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_model.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/birth_expectations/birth_controller.dart';
import 'package:multiple_result/multiple_result.dart';

import '../plano_parto_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BirthController.initialize', () {
    test('plano existente → carrega', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(quemCortaCordao: 'eu'),
        ),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = BirthController(planoRepo, perfil);

      await c.initialize();

      expect(c.hasGestacao, isTrue);
      expect(c.plano?.quemCortaCordao, 'eu');
      expect(c.isLoading, isFalse);
    });

    test('404 → plano vazio', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Success(null),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = BirthController(planoRepo, perfil);

      await c.initialize();

      expect(c.hasGestacao, isTrue);
      expect(c.plano?.quemCortaCordao, 'nao_sei');
    });
  });

  group('BirthController.saveBirth', () {
    test('salva a seção e preserva as demais', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(acompanhante: 'sim'),
        ),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = BirthController(planoRepo, perfil);
      await c.initialize();

      await c.saveBirth(
        quemCortaCordao: ActorChoice.acompanhante,
        coletaCelulasTronco: true,
        contatoPeleAPele: TriState.sim,
        amamentarPrimeiraHora: TriState.sim,
        restricoesAmamentacao: false,
        primeiroBanho: ActorChoice.profissional,
      );

      final sent = planoRepo.lastUpserted!;
      expect(sent.quemCortaCordao, 'acompanhante');
      expect(sent.coletaCelulasTronco, isTrue);
      expect(sent.contatoPeleAPele, 'sim');
      expect(sent.amamentarPrimeiraHora, 'sim');
      expect(sent.restricoesAmamentacao, isFalse);
      expect(sent.primeiroBanho, 'profissional');
      // Demais seções preservadas.
      expect(sent.acompanhante, 'sim');
      expect(sent.viaParto, 'nao_sei');
      expect(c.saved, isTrue);
    });

    test('sem gestação → não chama o PUT', () async {
      final planoRepo = FakePlanoPartoRepository();
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(null),
      );
      final c = BirthController(planoRepo, perfil);
      await c.initialize();

      await c.saveBirth(
        quemCortaCordao: ActorChoice.eu,
        coletaCelulasTronco: false,
        contatoPeleAPele: TriState.naoSei,
        amamentarPrimeiraHora: TriState.naoSei,
        restricoesAmamentacao: false,
        primeiroBanho: ActorChoice.eu,
      );

      expect(c.saved, isFalse);
      expect(planoRepo.upsertCalls, 0);
    });

    test('erro no PUT → saved false', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Success(null),
        onUpsert: (_, _) async => const Error(NetworkFailure()),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = BirthController(planoRepo, perfil);
      await c.initialize();

      await c.saveBirth(
        quemCortaCordao: ActorChoice.eu,
        coletaCelulasTronco: false,
        contatoPeleAPele: TriState.naoSei,
        amamentarPrimeiraHora: TriState.naoSei,
        restricoesAmamentacao: false,
        primeiroBanho: ActorChoice.eu,
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
      final c = BirthController(planoRepo, perfil);
      await c.initialize();

      await c.saveBirth(
        quemCortaCordao: ActorChoice.eu,
        coletaCelulasTronco: false,
        contatoPeleAPele: TriState.naoSei,
        amamentarPrimeiraHora: TriState.naoSei,
        restricoesAmamentacao: false,
        primeiroBanho: ActorChoice.eu,
      );

      expect(planoRepo.upsertCalls, 0);
      expect(c.saved, isFalse);
    });
  });
}
