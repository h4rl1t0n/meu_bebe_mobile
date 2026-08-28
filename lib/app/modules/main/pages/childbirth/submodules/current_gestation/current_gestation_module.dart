import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/gestacao/gestacao_repository.dart';
import '../../../../../../repositories/gestacao/gestacao_repository_impl.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository_impl.dart';
import '../../../../../core/core_module.dart';
import 'current_gestation_controller.dart';
import 'current_gestation_page.dart';

class CurrentGestationModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.addSingleton<PerfilRepository>(PerfilRepositoryImpl.new);
    i.addSingleton<GestacaoRepository>(GestacaoRepositoryImpl.new);
    i.addSingleton(CurrentGestationController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const CurrentGestationPage());
  }
}
