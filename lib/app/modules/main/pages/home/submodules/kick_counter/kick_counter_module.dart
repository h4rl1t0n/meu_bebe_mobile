import 'package:flutter_modular/flutter_modular.dart';

import 'kick_counter_controller.dart';
import 'kick_counter_page.dart';

class KickCounterModule extends Module {
  @override
  void binds(i) {
    i.addSingleton(KickCounterController.new);
  }

  @override
  void routes(r) {
    r.child(Modular.initialRoute, child: (context) => const KickCounterPage());
  }
}
