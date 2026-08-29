import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/onboarding/onboarding_guard.dart';
import 'package:meu_bebe/app/modules/onboarding/onboarding_resolution.dart';
import 'package:meu_bebe/app/modules/onboarding/onboarding_resolver.dart';
import 'package:meu_bebe/app/repositories/avaliacao_dss/avaliacao_dss_repository.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';

class _NoopPerfilRepository implements PerfilRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopAvaliacaoDssRepository implements AvaliacaoDssRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Resolver stub que devolve um resultado fixo para [resolveCached] — o canal
/// usado pelo guard. Não consulta o backend.
class _StubResolver extends OnboardingResolver {
  _StubResolver(this.result)
      : super(_NoopPerfilRepository(), _NoopAvaliacaoDssRepository());

  final OnboardingResolution result;

  @override
  Future<OnboardingResolution> resolveCached() async => result;
}

void main() {
  group('releasesRouteTab — contrato da proteção da Main', () {
    test('somente OnboardingComplete libera a Main', () {
      expect(releasesRouteTab(const OnboardingComplete()), isTrue);
    });

    test('passo pendente NÃO libera a Main', () {
      expect(
        releasesRouteTab(const OnboardingNextStep('/dados_perfil/')),
        isFalse,
      );
    });

    test('falha NÃO libera a Main', () {
      expect(releasesRouteTab(const OnboardingFailure()), isFalse);
    });

    test('sessão expirada NÃO libera a Main', () {
      expect(releasesRouteTab(const OnboardingSessionExpired()), isFalse);
    });
  });

  group('OnboardingGuard.canActivate', () {
    test('onboarding completo autoriza a rota', () async {
      final guard = OnboardingGuard(
        resolver: _StubResolver(const OnboardingComplete()),
      );

      expect(await guard.canActivate('/tab/', ParallelRoute.empty()), isTrue);
    });

    test('passo pendente não autoriza (redireciona)', () async {
      final guard = OnboardingGuard(
        resolver: _StubResolver(const OnboardingNextStep('/form/')),
      );

      expect(await guard.canActivate('/tab/', ParallelRoute.empty()), isFalse);
    });

    test('falha não autoriza (redireciona)', () async {
      final guard = OnboardingGuard(
        resolver: _StubResolver(const OnboardingFailure()),
      );

      expect(await guard.canActivate('/tab/', ParallelRoute.empty()), isFalse);
    });

    test('sessão expirada não autoriza (redireciona)', () async {
      final guard = OnboardingGuard(
        resolver: _StubResolver(const OnboardingSessionExpired()),
      );

      expect(await guard.canActivate('/tab/', ParallelRoute.empty()), isFalse);
    });
  });
}
