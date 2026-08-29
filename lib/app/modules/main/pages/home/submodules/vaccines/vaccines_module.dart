import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository_impl.dart';
import '../../../../../../repositories/vacina/vacina_repository.dart';
import '../../../../../../repositories/vacina/vacina_repository_impl.dart';
import '../../../../../core/core_module.dart';
import 'vaccines_controller.dart';
import 'vaccines_page.dart';

class VaccinesModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.addSingleton<PerfilRepository>(PerfilRepositoryImpl.new);
    i.addSingleton<VacinaRepository>(VacinaRepositoryImpl.new);
    i.addSingleton(VaccinesController.new);
  }

  @override
  void routes(r) {
    r.child(Modular.initialRoute, child: (context) => const VaccinesPage());
  }
}
