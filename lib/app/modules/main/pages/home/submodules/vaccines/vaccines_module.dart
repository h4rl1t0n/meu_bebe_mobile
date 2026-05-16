import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/vaccines/vaccines_repository.dart';
import '../../../../../../repositories/vaccines/vaccines_repository_impl.dart';
import 'vaccines_controller.dart';
import 'vaccines_page.dart';

class VaccinesModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<VaccinesRepository>(VaccinesRepositoryImpl.new);
    i.addSingleton(VaccinesController.new);
  }

  @override
  void routes(r) {
    r.child(Modular.initialRoute, child: (context) => const VaccinesPage());
  }
}
