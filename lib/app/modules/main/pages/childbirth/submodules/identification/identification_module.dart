import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/gestacao/gestacao_repository.dart';
import '../../../../../../repositories/gestacao/gestacao_repository_impl.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository_impl.dart';
import '../../../../../core/core_module.dart';
import 'identification_controller.dart';
import 'identification_page.dart';

class IdentificationModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.addSingleton<PerfilRepository>(PerfilRepositoryImpl.new);
    i.addSingleton<GestacaoRepository>(GestacaoRepositoryImpl.new);
    i.addSingleton(IdentificationController.new);
  }

  @override
  void routes(r) {
    r.child(Modular.initialRoute, child: (_) => const IdentificationPage());
  }
}
