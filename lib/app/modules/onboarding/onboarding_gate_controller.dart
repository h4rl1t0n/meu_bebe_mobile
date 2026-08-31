import 'package:mobx/mobx.dart';

import 'onboarding_navigator.dart';
import 'onboarding_resolution.dart';
import 'onboarding_resolver.dart';

part 'onboarding_gate_controller.g.dart';

class OnboardingGateController = OnboardingGateControllerBase with _$OnboardingGateController;

/// Estado da tela de verificação/retry do onboarding (FASE 9G-FIX1). O
/// `checking` (observable) controla o spinner vs. o botão de retry, eliminando
/// o `setState` da página.
abstract class OnboardingGateControllerBase with Store {
  final OnboardingResolver resolver;

  OnboardingGateControllerBase(this.resolver);

  @observable
  bool checking = true;

  @action
  Future<void> resolve() async {
    checking = true;
    final resolution = await resolver.resolve();
    switch (resolution) {
      case OnboardingComplete():
      case OnboardingNextStep():
        navigateOnboardingResolution(resolution);
      case OnboardingFailure():
        checking = false;
      case OnboardingSessionExpired():
        // SessionManager já navegou ao login; nada a fazer.
        break;
    }
  }
}
