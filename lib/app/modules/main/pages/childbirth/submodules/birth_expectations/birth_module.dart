import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/birth/birth_repository.dart';
import '../../../../../../repositories/birth/birth_repository_impl.dart';
import 'birth_controller.dart';
import 'birth_page.dart';

class BirthModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<BirthRepository>(BirthRepositoryImpl.new);
    i.addSingleton(BirthController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const BirthPage());
  }
}
