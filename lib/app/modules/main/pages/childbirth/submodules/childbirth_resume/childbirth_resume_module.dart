import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/exame/exame_repository.dart';
import '../../../../../../repositories/exame/exame_repository_impl.dart';
import '../../../../../../repositories/historico_obstetrico/historico_obstetrico_repository.dart';
import '../../../../../../repositories/historico_obstetrico/historico_obstetrico_repository_impl.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository_impl.dart';
import '../../../../../../repositories/plano_parto/plano_parto_repository.dart';
import '../../../../../../repositories/plano_parto/plano_parto_repository_impl.dart';
import '../../../../../core/core_module.dart';
import 'childbirth_resume_controller.dart';
import 'childbirth_resume_page.dart';

class ChildbirthResumeModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.addSingleton<PerfilRepository>(PerfilRepositoryImpl.new);
    i.addSingleton<HistoricoObstetricoRepository>(HistoricoObstetricoRepositoryImpl.new);
    i.addSingleton<ExameRepository>(ExameRepositoryImpl.new);
    i.addSingleton<PlanoPartoRepository>(PlanoPartoRepositoryImpl.new);
    i.addSingleton(ChildbirthResumeController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const ChildbirthResumePage());
  }
}
