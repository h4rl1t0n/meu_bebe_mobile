import 'package:flutter_modular/flutter_modular.dart';

import 'notificacoes_page.dart';

class NotificacoesModule extends Module {
  @override
  void routes(r) {
    r.child('/', child: (context) => const NotificacoesPage());
  }
}
