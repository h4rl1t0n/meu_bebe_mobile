import 'package:flutter_modular/flutter_modular.dart';

import 'configuracoes_page.dart';

class ConfiguracoesModule extends Module {
  @override
  void routes(r) {
    r.child('/', child: (context) => const ConfiguracoesPage());
  }
}
