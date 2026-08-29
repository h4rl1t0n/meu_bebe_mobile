import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/medicamento/medicamento_repository.dart';
import '../../../../../../repositories/medicamento/medicamento_repository_impl.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository_impl.dart';
import '../../../../../core/core_module.dart';
import 'medication_controller.dart';
import 'medication_page.dart';

class MedicationModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.addSingleton<PerfilRepository>(PerfilRepositoryImpl.new);
    i.addSingleton<MedicamentoRepository>(MedicamentoRepositoryImpl.new);
    i.addSingleton(MedicationController.new);
  }

  @override
  void routes(r) {
    r.child(Modular.initialRoute, child: (context) => const MedicationPage());
  }
}
