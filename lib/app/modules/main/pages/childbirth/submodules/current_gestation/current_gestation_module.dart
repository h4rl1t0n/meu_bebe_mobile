import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/current_gestation/current_gestation_repository.dart';
import '../../../../../../repositories/current_gestation/current_gestation_repository_impl.dart';
import 'current_gestation_controller.dart';
import 'current_gestation_page.dart';

class CurrentGestationModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<CurrentGestationRepository>(CurrentGestationRepositoryImpl.new);
    i.addSingleton(CurrentGestationController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const CurrentGestationPage());
  }
}
