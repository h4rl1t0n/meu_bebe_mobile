import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/consulta/consulta_repository.dart';
import '../../../../../../repositories/consulta/consulta_repository_impl.dart';
import '../../../../../../repositories/exame/exame_repository.dart';
import '../../../../../../repositories/exame/exame_repository_impl.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository_impl.dart';
import '../../../../../core/core_module.dart';
import 'appointments_exams_controller.dart';
import 'appointments_exams_page.dart';

class AppointmentsExamsModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.addSingleton<PerfilRepository>(PerfilRepositoryImpl.new);
    i.addSingleton<ConsultaRepository>(ConsultaRepositoryImpl.new);
    i.addSingleton<ExameRepository>(ExameRepositoryImpl.new);
    i.addSingleton(AppointmentsExamsController.new);
  }

  @override
  void routes(r) {
    r.child(Modular.initialRoute, child: (context) => const AppointmentsExamsPage());
  }
}
