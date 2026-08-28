import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/historico_obstetrico/historico_obstetrico_repository.dart';
import '../../../../../../repositories/historico_obstetrico/historico_obstetrico_repository_impl.dart';
import '../../../../../core/core_module.dart';
import 'history_controller.dart';
import 'history_page.dart';

class HistoryModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.addSingleton<HistoricoObstetricoRepository>(
      HistoricoObstetricoRepositoryImpl.new,
    );
    i.addSingleton(HistoryController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const HistoryPage());
  }
}
