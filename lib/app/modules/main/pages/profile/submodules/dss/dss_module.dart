import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/avaliacao_dss/avaliacao_dss_repository.dart';
import '../../../../../../repositories/avaliacao_dss/avaliacao_dss_repository_impl.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository_impl.dart';
import '../../../../../core/core_module.dart';
import 'dss_controller.dart';
import 'dss_history_page.dart';

class DssModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.addSingleton<PerfilRepository>(PerfilRepositoryImpl.new);
    i.addSingleton<AvaliacaoDssRepository>(AvaliacaoDssRepositoryImpl.new);
    i.addSingleton(DssController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const DssHistoryPage());
  }
}
