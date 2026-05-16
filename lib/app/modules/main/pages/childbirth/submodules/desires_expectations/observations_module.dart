import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/observations/observations_repository.dart';
import '../../../../../../repositories/observations/observations_repository_impl.dart';
import 'observations_controller.dart';
import 'observations_page.dart';

class ObservationsModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<ObservationsRepository>(ObservationsRepositoryImpl.new);
    i.addSingleton(ObservationsController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const ObservationsPage());
  }
}
