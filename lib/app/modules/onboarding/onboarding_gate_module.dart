import 'package:flutter_modular/flutter_modular.dart';

import 'onboarding_gate_page.dart';
import 'onboarding_module.dart';

/// Tela de verificação/retry do onboarding, alvo do redirect da
/// [OnboardingGuard]. Re-resolve o estado e encaminha (retry ou próximo
/// passo). Importa o [OnboardingModule] para reutilizar o MESMO resolver.
class OnboardingGateModule extends Module {
  @override
  List<Module> get imports => [OnboardingModule()];

  @override
  void routes(r) {
    r.child(Modular.initialRoute, child: (context) => const OnboardingGatePage());
  }
}
