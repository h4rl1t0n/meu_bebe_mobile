import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/pain_relief/pain_relief_repository.dart';
import '../../../../../../repositories/pain_relief/pain_relief_repository_impl.dart';
import 'pain_relief_controller.dart';
import 'pain_relief_page.dart';

class PainReliefModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<PainReliefRepository>(PainReliefRepositoryImpl.new);
    i.addSingleton(PainReliefController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const PainReliefPage());
  }
}
