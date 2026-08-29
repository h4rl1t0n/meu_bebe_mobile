import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/app_module.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/model/avaliacao_dss/avaliacao_dss_model.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/formulario_data.dart';
import 'package:meu_bebe/app/modules/onboarding/onboarding_resolution.dart';
import 'package:meu_bebe/app/modules/onboarding/onboarding_resolver.dart';
import 'package:meu_bebe/app/repositories/avaliacao_dss/avaliacao_dss_repository.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:multiple_result/multiple_result.dart';

const _gestante = GestanteModel(id: 'g1', nome: 'Maria Silva');

const _gestacao = GestacaoModel(
  id: 'ges1',
  dataUltimaMenstruacao: '2026-01-10',
);

const _avaliacao = AvaliacaoDssModel(
  id: 'a1',
  schemaVersion: '1.13',
  respostas: <String, dynamic>{},
  createdAt: '2026-08-29T00:00:00Z',
);

class _FakePerfilRepository implements PerfilRepository {
  _FakePerfilRepository({
    this.onGetGestante,
    this.onGetGestacaoAtual,
  });

  Future<Result<GestanteModel?, BackendFailure>> Function()? onGetGestante;
  Future<Result<GestacaoModel?, BackendFailure>> Function()? onGetGestacaoAtual;

  int getGestanteCalls = 0;
  int getGestacaoAtualCalls = 0;

  @override
  Future<Result<GestanteModel?, BackendFailure>> getGestante() {
    getGestanteCalls++;
    return onGetGestante!();
  }

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

class _FakeAvaliacaoDssRepository implements AvaliacaoDssRepository {
  _FakeAvaliacaoDssRepository(this.onList);

  Future<Result<List<AvaliacaoDssModel>, BackendFailure>> Function(String)
  onList;

  int listCalls = 0;

  @override
  Future<Result<List<AvaliacaoDssModel>, BackendFailure>> list(
    String gestacaoId,
  ) {
    listCalls++;
    return onList(gestacaoId);
  }

  @override
  Future<Result<AvaliacaoDssModel, BackendFailure>> registrar(
    String gestacaoId,
    FormularioData data,
  ) => throw UnimplementedError();
}

void main() {
  OnboardingResolver resolver({
    _FakePerfilRepository? perfil,
    _FakeAvaliacaoDssRepository? avaliacao,
  }) {
    return OnboardingResolver(
      perfil ??
          _FakePerfilRepository(
            onGetGestante: () async => const Success(_gestante),
            onGetGestacaoAtual: () async => const Success(_gestacao),
          ),
      avaliacao ??
          _FakeAvaliacaoDssRepository(
            (_) async => const Success(<AvaliacaoDssModel>[_avaliacao]),
          ),
    );
  }

  group('OnboardingResolver.resolve — estado → destino tipado', () {
    test('sem gestante (Success null) → OnboardingNextStep(dadosPerfil)',
        () async {
      final r = resolver(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => const Success(null),
          onGetGestacaoAtual: () async => const Success(_gestacao),
        ),
      );

      final resolution = await r.resolve();

      expect(
        resolution,
        isA<OnboardingNextStep>()
            .having((e) => e.route, 'route', routeDadosPerfil),
      );
    });

    test('gestante OK, sem gestação ativa → OnboardingNextStep(gravidezAtual)',
        () async {
      final r = resolver(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => const Success(_gestante),
          onGetGestacaoAtual: () async => const Success(null),
        ),
      );

      final resolution = await r.resolve();

      expect(
        resolution,
        isA<OnboardingNextStep>()
            .having((e) => e.route, 'route', routeGravidezAtual),
      );
    });

    test('gestante + gestação, sem avaliação DSS → OnboardingNextStep(form)',
        () async {
      final r = resolver(
        avaliacao: _FakeAvaliacaoDssRepository(
          (_) async => const Success(<AvaliacaoDssModel>[]),
        ),
      );

      final resolution = await r.resolve();

      expect(
        resolution,
        isA<OnboardingNextStep>().having((e) => e.route, 'route', routeForm),
      );
    });

    test('gestante + gestação + avaliação DSS → OnboardingComplete', () async {
      final r = resolver();

      expect(await r.resolve(), isA<OnboardingComplete>());
    });
  });

  group('OnboardingResolver.resolve — falhas NUNCA liberam a Main', () {
    test('erro de rede ao buscar gestante → OnboardingFailure', () async {
      final r = resolver(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => const Error(NetworkFailure()),
          onGetGestacaoAtual: () async => const Success(_gestacao),
        ),
      );

      expect(await r.resolve(), isA<OnboardingFailure>());
    });

    test('sessão expirada ao buscar gestante → OnboardingSessionExpired',
        () async {
      final r = resolver(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => const Error(SessionExpiredFailure()),
          onGetGestacaoAtual: () async => const Success(_gestacao),
        ),
      );

      expect(await r.resolve(), isA<OnboardingSessionExpired>());
    });

    test('erro de rede ao buscar gestação → OnboardingFailure', () async {
      final r = resolver(
        perfil: _FakePerfilRepository(
          onGetGestante: () async => const Success(_gestante),
          onGetGestacaoAtual: () async => const Error(NetworkFailure()),
        ),
      );

      expect(await r.resolve(), isA<OnboardingFailure>());
    });

    test('sessão expirada ao listar avaliações → OnboardingSessionExpired',
        () async {
      final r = resolver(
        avaliacao: _FakeAvaliacaoDssRepository(
          (_) async => const Error(SessionExpiredFailure()),
        ),
      );

      expect(await r.resolve(), isA<OnboardingSessionExpired>());
    });

    test('erro inesperado ao listar avaliações → OnboardingFailure', () async {
      final r = resolver(
        avaliacao: _FakeAvaliacaoDssRepository(
          (_) async => const Error(UnexpectedFailure()),
        ),
      );

      expect(await r.resolve(), isA<OnboardingFailure>());
    });
  });

  group('OnboardingResolver — resolução reutilizável (sem duplicar queries)', () {
    test('resolveCached reusa o resultado sem re-consultar o backend', () async {
      final perfil = _FakePerfilRepository(
        onGetGestante: () async => const Success(_gestante),
        onGetGestacaoAtual: () async => const Success(_gestacao),
      );
      final r = resolver(perfil: perfil);

      final first = await r.resolveCached();
      final second = await r.resolveCached();

      expect(first, isA<OnboardingComplete>());
      expect(second, isA<OnboardingComplete>());
      expect(perfil.getGestanteCalls, 1);
      expect(perfil.getGestacaoAtualCalls, 1);
    });

    test('invalidate descarta o cache e re-consulta na próxima resolução',
        () async {
      final perfil = _FakePerfilRepository(
        onGetGestante: () async => const Success(_gestante),
        onGetGestacaoAtual: () async => const Success(_gestacao),
      );
      final r = resolver(perfil: perfil);

      await r.resolveCached();
      expect(perfil.getGestanteCalls, 1);

      r.invalidate();
      await r.resolveCached();

      expect(perfil.getGestanteCalls, 2);
    });
  });
}
