import 'package:flutter_modular/flutter_modular.dart';

import '../onboarding/onboarding_module.dart';
import 'inicializar_app_page.dart';

class InicializarAppModule extends Module {
  @override
  List<Module> get imports => [OnboardingModule()];

  @override
  void binds(i) {}

  @override
  void routes(RouteManager r) {
    r.child(Modular.initialRoute, child: (context) => InicializarAppPage());
  }
}
