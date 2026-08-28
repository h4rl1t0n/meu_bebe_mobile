import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository_impl.dart';
import '../../../../../core/core_module.dart';
import 'profile_data_controller.dart';
import 'profile_data_page.dart';

class ProfileDataModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.addSingleton<PerfilRepository>(PerfilRepositoryImpl.new);
    i.addSingleton(ProfileDataController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const ProfileDataPage());
  }
}
