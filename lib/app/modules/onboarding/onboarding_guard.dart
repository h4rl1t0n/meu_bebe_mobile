import 'package:flutter_modular/flutter_modular.dart';

import '../../app_module.dart';
import 'onboarding_resolution.dart';
import 'onboarding_resolver.dart';

/// Proteção real da Main (routeTab): só libera com onboarding COMPLETO
/// ([OnboardingComplete]). Qualquer outro estado — pendente, falha ou sessão
/// expirada — redireciona para a tela de verificação (routeOnboardingGate),
/// que re-resolve e encaminha (retry/next-step), sem loop.
class OnboardingGuard extends RouteGuard {
  OnboardingGuard({this.resolver}) : super(redirectTo: routeOnboardingGate);

  final OnboardingResolver? resolver;

  @override
  Future<bool> canActivate(String path, ParallelRoute route) async {
    final active = resolver ?? Modular.get<OnboardingResolver>();
    final resolution = await active.resolveCached();
    return releasesRouteTab(resolution);
  }
}

/// `true` somente para onboarding completo. Mantida pura para teste.
bool releasesRouteTab(OnboardingResolution resolution) =>
    resolution is OnboardingComplete;
