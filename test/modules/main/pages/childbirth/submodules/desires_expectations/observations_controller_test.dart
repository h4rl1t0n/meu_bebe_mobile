import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_model.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/desires_expectations/observations_controller.dart';
import 'package:multiple_result/multiple_result.dart';

import '../plano_parto_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ObservationsController.initialize', () {
    test('plano existente → carrega observações', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(observacoes: 'Quero luz baixa'),
        ),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = ObservationsController(planoRepo, perfil);

      await c.initialize();

      expect(c.hasGestacao, isTrue);
      expect(c.plano?.observacoes, 'Quero luz baixa');
      expect(c.isLoading, isFalse);
    });
  });

  group('ObservationsController.saveObservations', () {
    test('salva observações e preserva as demais seções', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(
            acompanhante: 'sim',
            viaParto: 'vaginal',
          ),
        ),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = ObservationsController(planoRepo, perfil);
      await c.initialize();

      await c.saveObservations(observacoes: 'Preferências de parto');

      final sent = planoRepo.lastUpserted!;
      expect(sent.observacoes, 'Preferências de parto');
      // Demais seções preservadas.
      expect(sent.acompanhante, 'sim');
      expect(sent.viaParto, 'vaginal');
      expect(sent.querAlivioDor, 'nao_sei');
      expect(c.saved, isTrue);
    });

    test('sem gestação → não chama o PUT', () async {
      final planoRepo = FakePlanoPartoRepository();
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(null),
      );
      final c = ObservationsController(planoRepo, perfil);
      await c.initialize();

      await c.saveObservations(observacoes: 'x');

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
      final c = ObservationsController(planoRepo, perfil);
      await c.initialize();

      await c.saveObservations(observacoes: 'x');

      expect(c.saved, isFalse);
    });

    test('erro no GET → save bloqueado (não chama o PUT)', () async {
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => const Error(NetworkFailure()),
      );
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = ObservationsController(planoRepo, perfil);
      await c.initialize();

      await c.saveObservations(observacoes: 'x');

      expect(planoRepo.upsertCalls, 0);
      expect(c.saved, isFalse);
    });
  });
}
