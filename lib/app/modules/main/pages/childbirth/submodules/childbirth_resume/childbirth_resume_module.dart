import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/birth/birth_repository.dart';
import '../../../../../../repositories/birth/birth_repository_impl.dart';
import '../../../../../../repositories/birth_moment/birth_moment_repository.dart';
import '../../../../../../repositories/birth_moment/birth_moment_repository_impl.dart';
import '../../../../../../repositories/expectations/expectations_repository.dart';
import '../../../../../../repositories/expectations/expectations_repository_impl.dart';
import '../../../../../../repositories/historico_obstetrico/historico_obstetrico_repository.dart';
import '../../../../../../repositories/historico_obstetrico/historico_obstetrico_repository_impl.dart';
import '../../../../../../repositories/observations/observations_repository.dart';
import '../../../../../../repositories/observations/observations_repository_impl.dart';
import '../../../../../../repositories/pain_relief/pain_relief_repository.dart';
import '../../../../../../repositories/pain_relief/pain_relief_repository_impl.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository_impl.dart';
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
    i.addSingleton<ExpectationsRepository>(ExpectationsRepositoryImpl.new);
    i.addSingleton<BirthMomentRepository>(BirthMomentRepositoryImpl.new);
    i.addSingleton<BirthRepository>(BirthRepositoryImpl.new);
    i.addSingleton<PainReliefRepository>(PainReliefRepositoryImpl.new);
    i.addSingleton<ObservationsRepository>(ObservationsRepositoryImpl.new);
    i.addSingleton(ChildbirthResumeController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const ChildbirthResumePage());
  }
}
