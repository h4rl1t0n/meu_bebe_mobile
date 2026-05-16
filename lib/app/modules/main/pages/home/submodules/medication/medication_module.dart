import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/medication/medication_repository.dart';
import '../../../../../../repositories/medication/medication_repository_impl.dart';
import 'medication_controller.dart';
import 'medication_page.dart';

class MedicationModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<MedicationRepository>(MedicationRepositoryImpl.new);
    i.addSingleton(MedicationController.new);
  }

  @override
  void routes(r) {
    r.child(Modular.initialRoute, child: (context) => const MedicationPage());
  }
}
