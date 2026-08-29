import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository_impl.dart';
import '../../../../../../repositories/plano_parto/plano_parto_repository.dart';
import '../../../../../../repositories/plano_parto/plano_parto_repository_impl.dart';
import '../../../../../core/core_module.dart';
import 'pain_relief_controller.dart';
import 'pain_relief_page.dart';

class PainReliefModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.addSingleton<PerfilRepository>(PerfilRepositoryImpl.new);
    i.addSingleton<PlanoPartoRepository>(PlanoPartoRepositoryImpl.new);
    i.addSingleton(PainReliefController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const PainReliefPage());
  }
}
