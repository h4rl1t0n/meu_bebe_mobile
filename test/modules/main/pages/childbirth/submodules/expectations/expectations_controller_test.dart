import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_enums.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_model.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/expectations/expectations_controller.dart';
import 'package:multiple_result/multiple_result.dart';

import '../plano_parto_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExpectationsController.initialize', () {
    test('gestação ativa + plano existente → carrega plano', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(acompanhante: 'sim'),
        ),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = ExpectationsController(planoRepo, perfil);

      await c.initialize();

      expect(c.hasGestacao, isTrue);
      expect(c.plano?.acompanhante, 'sim');
      expect(c.acompanhante, TriState.sim);
      expect(c.isLoading, isFalse);
      expect(planoRepo.getCalls, 1);
    });

    test('404 (plano inexistente) → plano vazio e funcional', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Success(null),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = ExpectationsController(planoRepo, perfil);

      await c.initialize();

      expect(c.hasGestacao, isTrue);
      expect(c.plano?.acompanhante, 'nao_sei');
      expect(c.acompanhante, TriState.naoSei);
      expect(c.isLoading, isFalse);
    });

    test('sem gestação ativa → hasGestacao false, não lê o plano', () async {
      final planoRepo = FakePlanoPartoRepository();
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(null),
      );
      final c = ExpectationsController(planoRepo, perfil);

      await c.initialize();

      expect(c.hasGestacao, isFalse);
      expect(c.plano, isNull);
      expect(planoRepo.getCalls, 0);
      expect(c.isLoading, isFalse);
    });

    test('erro ao carregar → plano permanece null e registra falha', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Error(SessionExpiredFailure()),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = ExpectationsController(planoRepo, perfil);

      await c.initialize();

      expect(c.hasGestacao, isTrue);
      expect(c.plano, isNull);
      expect(c.loadFailed, isTrue);
      expect(c.isLoading, isFalse);
    });
  });

  group('ExpectationsController.saveExpectations', () {
    test('salva a seção e preserva as demais (PUT completo)', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(
            viaParto: 'cesarea',
            observacoes: 'nota pré-existente',
          ),
        ),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = ExpectationsController(planoRepo, perfil);
      await c.initialize();

      c.setAcompanhante(TriState.sim);
      c.setRasparPelosIntimos(TriState.nao);
      c.setLavagemIntestinal(TriState.naoSei);
      c.setAmbientePoucaLuz(TriState.sim);
      c.setOuvirMusica(TriState.nao);
      c.setBeberLiquidos(TriState.sim);
      c.setRegistrarFotosVideos(TriState.naoSei);
      await c.saveExpectations();

      expect(c.saved, isTrue);
      expect(planoRepo.upsertCalls, 1);
      expect(planoRepo.lastUpsertedGestacaoId, 'ges-1');

      // Seção editada...
      final sent = planoRepo.lastUpserted!;
      expect(sent.acompanhante, 'sim');
      expect(sent.rasparPelosIntimos, 'nao');
      // ...e as demais 27 preservadas.
      expect(sent.viaParto, 'cesarea');
      expect(sent.observacoes, 'nota pré-existente');
      expect(sent.quemCortaCordao, 'nao_sei');
      expect(sent.querAlivioDor, 'nao_sei');
    });

    test('sem gestação → não chama o PUT', () async {
      final planoRepo = FakePlanoPartoRepository();
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(null),
      );
      final c = ExpectationsController(planoRepo, perfil);
      await c.initialize();

      c.setAcompanhante(TriState.sim);
      c.setRasparPelosIntimos(TriState.nao);
      c.setLavagemIntestinal(TriState.naoSei);
      c.setAmbientePoucaLuz(TriState.sim);
      c.setOuvirMusica(TriState.nao);
      c.setBeberLiquidos(TriState.sim);
      c.setRegistrarFotosVideos(TriState.naoSei);
      await c.saveExpectations();

      expect(c.saved, isFalse);
      expect(planoRepo.upsertCalls, 0);
    });

    test('erro no PUT → saved permanece false', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Success(null),
        onUpsert: (_, _) async => const Error(ValidationFailure()),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = ExpectationsController(planoRepo, perfil);
      await c.initialize();

      c.setAcompanhante(TriState.sim);
      c.setRasparPelosIntimos(TriState.nao);
      c.setLavagemIntestinal(TriState.naoSei);
      c.setAmbientePoucaLuz(TriState.sim);
      c.setOuvirMusica(TriState.nao);
      c.setBeberLiquidos(TriState.sim);
      c.setRegistrarFotosVideos(TriState.naoSei);
      await c.saveExpectations();

      expect(c.saved, isFalse);
      expect(planoRepo.upsertCalls, 1);
    });

    test('erro no GET → save bloqueado (não chama o PUT)', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Error(NetworkFailure()),
        // PUT estaria disponível (onUpsert padrão → Success), mas não deve ser
        // chamado enquanto o GET não tiver sido bem-sucedido.
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = ExpectationsController(planoRepo, perfil);
      await c.initialize();

      c.setAcompanhante(TriState.sim);
      c.setRasparPelosIntimos(TriState.nao);
      c.setLavagemIntestinal(TriState.naoSei);
      c.setAmbientePoucaLuz(TriState.sim);
      c.setOuvirMusica(TriState.nao);
      c.setBeberLiquidos(TriState.sim);
      c.setRegistrarFotosVideos(TriState.naoSei);
      await c.saveExpectations();

      expect(planoRepo.upsertCalls, 0);
      expect(c.saved, isFalse);
    });

    test('save falha após sucesso anterior → saved volta a false (L3)', () async {
      var shouldFail = false;
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Success(null),
        onUpsert: (_, p) async {
          if (shouldFail) {
            return const Error(ValidationFailure());
          }
          return Success(p);
        },
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = ExpectationsController(planoRepo, perfil);
      await c.initialize();

      c.setAcompanhante(TriState.sim);
      c.setRasparPelosIntimos(TriState.nao);
      c.setLavagemIntestinal(TriState.naoSei);
      c.setAmbientePoucaLuz(TriState.sim);
      c.setOuvirMusica(TriState.nao);
      c.setBeberLiquidos(TriState.sim);
      c.setRegistrarFotosVideos(TriState.naoSei);
      await c.saveExpectations();
      expect(c.saved, isTrue);

      shouldFail = true;
      c.setAcompanhante(TriState.nao);
      c.setRasparPelosIntimos(TriState.sim);
      c.setLavagemIntestinal(TriState.nao);
      c.setAmbientePoucaLuz(TriState.nao);
      c.setOuvirMusica(TriState.sim);
      c.setBeberLiquidos(TriState.nao);
      c.setRegistrarFotosVideos(TriState.sim);
      await c.saveExpectations();
      expect(c.saved, isFalse);
    });

    test('double-submit → apenas 1 PUT (guard de concorrência)', () async {
      final completer = Completer<Result<PlanoPartoModel, BackendFailure>>();
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Success(null),
        onUpsert: (_, _) => completer.future,
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = ExpectationsController(planoRepo, perfil);
      await c.initialize();

      c.setAcompanhante(TriState.sim);
      c.setRasparPelosIntimos(TriState.nao);
      c.setLavagemIntestinal(TriState.naoSei);
      c.setAmbientePoucaLuz(TriState.sim);
      c.setOuvirMusica(TriState.nao);
      c.setBeberLiquidos(TriState.sim);
      c.setRegistrarFotosVideos(TriState.naoSei);
      final first = c.saveExpectations();
      // Chamada concorrente enquanto a 1ª ainda está pendente.
      c.setAcompanhante(TriState.nao);
      c.setRasparPelosIntimos(TriState.sim);
      c.setLavagemIntestinal(TriState.nao);
      c.setAmbientePoucaLuz(TriState.nao);
      c.setOuvirMusica(TriState.sim);
      c.setBeberLiquidos(TriState.nao);
      c.setRegistrarFotosVideos(TriState.sim);
      await c.saveExpectations();

      completer.complete(Success(PlanoPartoModel.empty()));
      await first;

      expect(planoRepo.upsertCalls, 1);
    });
  });
}
