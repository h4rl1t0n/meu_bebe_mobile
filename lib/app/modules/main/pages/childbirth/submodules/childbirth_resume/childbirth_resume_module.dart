import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/birth/birth_repository.dart';
import '../../../../../../repositories/birth/birth_repository_impl.dart';
import '../../../../../../repositories/birth_moment/birth_moment_repository.dart';
import '../../../../../../repositories/birth_moment/birth_moment_repository_impl.dart';
import '../../../../../../repositories/current_gestation/current_gestation_repository.dart';
import '../../../../../../repositories/current_gestation/current_gestation_repository_impl.dart';
import '../../../../../../repositories/expectations/expectations_repository.dart';
import '../../../../../../repositories/expectations/expectations_repository_impl.dart';
import '../../../../../../repositories/gestation/gestation_repository.dart';
import '../../../../../../repositories/gestation/gestation_repository_impl.dart';
import '../../../../../../repositories/history/history_repository.dart';
import '../../../../../../repositories/history/history_repository_impl.dart';
import '../../../../../../repositories/observations/observations_repository.dart';
import '../../../../../../repositories/observations/observations_repository_impl.dart';
import '../../../../../../repositories/pain_relief/pain_relief_repository.dart';
import '../../../../../../repositories/pain_relief/pain_relief_repository_impl.dart';
import 'childbirth_resume_controller.dart';
import 'childbirth_resume_page.dart';

class ChildbirthResumeModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<GestationRepository>(GestationRepositoryImpl.new);
    i.addSingleton<HistoryRepository>(HistoryRepositoryImpl.new);
    i.addSingleton<CurrentGestationRepository>(CurrentGestationRepositoryImpl.new);
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
