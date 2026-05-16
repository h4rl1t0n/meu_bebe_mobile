import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/gestation/gestation_repository.dart';
import '../../../../../../repositories/gestation/gestation_repository_impl.dart';
import '../../../../../../repositories/profile/profile_repository.dart';
import '../../../../../../repositories/profile/profile_repository_impl.dart';
import 'profile_data_controller.dart';
import 'profile_data_page.dart';

class ProfileDataModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<ProfileRepository>(ProfileRepositoryImpl.new);
    i.addSingleton<GestationRepository>(GestationRepositoryImpl.new);
    i.addSingleton(ProfileDataController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const ProfileDataPage());
  }
}
