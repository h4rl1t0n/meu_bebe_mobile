import 'package:flutter_modular/flutter_modular.dart';

import '../../app_module.dart';
import 'onboarding_resolution.dart';
import 'onboarding_route_args.dart';

/// Aplica a resolução do onboarding à navegação (FASE 9G-FIX1).
///
/// - [OnboardingComplete]   → Main (routeTab)
/// - [OnboardingNextStep]   → próximo passo do onboarding (com onboardingArgs)
/// - [OnboardingFailure]    → tela de verificação/retry (routeOnboardingGate)
/// - [OnboardingSessionExpired] → no-op: o SessionManager já navegou ao login.
void navigateOnboardingResolution(OnboardingResolution resolution) {
  switch (resolution) {
    case OnboardingComplete():
      Modular.to.pushReplacementNamed(routeTab);
    case OnboardingNextStep(route: final route):
      Modular.to.pushReplacementNamed(route, arguments: onboardingArgs);
    case OnboardingFailure():
      Modular.to.pushReplacementNamed(routeOnboardingGate);
    case OnboardingSessionExpired():
      // SessionManager já navegou ao login; nada a fazer.
      break;
  }
}
