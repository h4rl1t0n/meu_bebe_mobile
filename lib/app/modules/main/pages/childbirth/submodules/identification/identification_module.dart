import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/gestation/gestation_repository.dart';
import '../../../../../../repositories/gestation/gestation_repository_impl.dart';
import 'identification_controller.dart';
import 'identification_page.dart';

class IdentificationModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<GestationRepository>(GestationRepositoryImpl.new);
    i.addSingleton(IdentificationController.new);
  }

  @override
  void routes(r) {
    r.child(Modular.initialRoute, child: (_) => const IdentificationPage());
  }
}
