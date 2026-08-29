import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository_impl.dart';
import '../../../../../../repositories/plano_parto/plano_parto_repository.dart';
import '../../../../../../repositories/plano_parto/plano_parto_repository_impl.dart';
import '../../../../../core/core_module.dart';
import 'birth_controller.dart';
import 'birth_page.dart';

class BirthModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.addSingleton<PerfilRepository>(PerfilRepositoryImpl.new);
    i.addSingleton<PlanoPartoRepository>(PlanoPartoRepositoryImpl.new);
    i.addSingleton(BirthController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const BirthPage());
  }
}
