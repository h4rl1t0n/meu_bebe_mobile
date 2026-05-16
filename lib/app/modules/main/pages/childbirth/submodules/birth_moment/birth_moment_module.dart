import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/birth_moment/birth_moment_repository.dart';
import '../../../../../../repositories/birth_moment/birth_moment_repository_impl.dart';
import 'birth_moment_controller.dart';
import 'birth_moment_page.dart';

class BirthMomentModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<BirthMomentRepository>(BirthMomentRepositoryImpl.new);
    i.addSingleton(BirthMomentController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const BirthMomentPage());
  }
}
