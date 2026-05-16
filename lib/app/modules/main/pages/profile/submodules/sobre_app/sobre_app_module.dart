import 'package:flutter_modular/flutter_modular.dart';

import 'sobre_app_page.dart';

class SobreAppModule extends Module {
  @override
  void routes(r) {
    r.child('/', child: (context) => const SobreAppPage());
  }
}
