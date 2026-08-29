import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/identification/identification_controller.dart';
import 'package:multiple_result/multiple_result.dart';

import '../plano_parto_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IdentificationController.initialize', () {
    test('carrega gestante e gestação da API', () async {
      final perfil = FakePerfilRepository(
        onGetGestante: () async => gestanteResult(gestanteAtiva),
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final c = IdentificationController(perfil, FakeGestacaoRepository());

      await c.initialize();

      expect(c.gestante?.nome, 'Maria Silva');
      expect(c.gestante?.cpf, '12345678901');
      expect(c.gestacao?.localPreNatal, 'UBS Centro');
      expect(c.gestacao?.dataUltimaMenstruacao, '2026-01-10');
      expect(c.isLoading, isFalse);
    });

    test('erro ao carregar → null, sem quebrar', () async {
      final perfil = FakePerfilRepository(
        onGetGestante: () async => const Error(SessionExpiredFailure()),
        onGetGestacaoAtual: () async => const Error(SessionExpiredFailure()),
      );
      final c = IdentificationController(perfil, FakeGestacaoRepository());

      await c.initialize();

      expect(c.gestante, isNull);
      expect(c.gestacao, isNull);
      expect(c.isLoading, isFalse);
    });
  });

  group('IdentificationController.saveIdentification', () {
    test('primeiro salvamento (sem registros) → create + create', () async {
      var createGestanteCalls = 0;
      var createGestacaoCalls = 0;
      final perfil = FakePerfilRepository(
        onGetGestante: () async => gestanteResult(null),
        onGetGestacaoAtual: () async => gestacaoResult(null),
        onCreateGestante: (g) async {
          createGestanteCalls++;
          return Success(g);
        },
      );
      final gestacaoRepo = FakeGestacaoRepository(
        onCreate: (g) async {
          createGestacaoCalls++;
          return Success(g);
        },
      );
      final c = IdentificationController(perfil, gestacaoRepo);
      await c.initialize();

      await c.saveIdentification(
        nome: 'Maria Silva',
        dataNascimento: '1995-03-20',
        cpf: '12345678901',
      );

      expect(c.saved, isTrue);
      expect(createGestanteCalls, 1);
      expect(createGestacaoCalls, 1);
    });

    test('edição → update + update, preservando a DUM da gestação', () async {
      GestacaoModel? sentGestacao;
      final perfil = FakePerfilRepository(
        onGetGestante: () async => gestanteResult(gestanteAtiva),
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
        onUpdateGestante: (g) async => Success(g),
      );
      final gestacaoRepo = FakeGestacaoRepository(
        onUpdate: (g) async {
          sentGestacao = g;
          return Success(g);
        },
      );
      final c = IdentificationController(perfil, gestacaoRepo);
      await c.initialize();

      await c.saveIdentification(
        nome: 'Maria Silva',
        localPreNatal: 'UBS Editada',
        profissionalPreNatal: 'Dra. Bia',
      );

      expect(c.saved, isTrue);
      expect(sentGestacao?.dataUltimaMenstruacao, '2026-01-10');
      expect(sentGestacao?.localPreNatal, 'UBS Editada');
      expect(sentGestacao?.profissionalPreNatal, 'Dra. Bia');
    });

    test('erro ao salvar gestante → não salva a gestação', () async {
      var createGestacaoCalls = 0;
      final perfil = FakePerfilRepository(
        onGetGestante: () async => gestanteResult(null),
        onGetGestacaoAtual: () async => gestacaoResult(null),
        onCreateGestante: (g) async => const Error(ValidationFailure()),
      );
      final gestacaoRepo = FakeGestacaoRepository(
        onCreate: (g) async {
          createGestacaoCalls++;
          return Success(g);
        },
      );
      final c = IdentificationController(perfil, gestacaoRepo);
      await c.initialize();

      await c.saveIdentification(nome: 'Maria Silva');

      expect(c.saved, isFalse);
      expect(createGestacaoCalls, 0);
    });
  });
}
