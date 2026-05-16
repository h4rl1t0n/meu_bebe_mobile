import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/expectations/expectations_repository.dart';
import '../../../../../../repositories/expectations/expectations_repository_impl.dart';
import 'expectations_controller.dart';
import 'expectations_page.dart';

class ExpectationsModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<ExpectationsRepository>(ExpectationsRepositoryImpl.new);
    i.addSingleton(ExpectationsController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const ExpectationsPage());
  }
}
