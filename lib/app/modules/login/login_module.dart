import 'package:flutter_modular/flutter_modular.dart';

import '../../repositories/user/user_repository.dart';
import '../../repositories/user/user_repository_impl.dart';
import '../../services/user_login_service.dart';
import '../../services/user_login_service_impl.dart';
import '../core/core_module.dart';
import 'login_controller.dart';
import 'login_page.dart';

class LoginModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.addSingleton<UserRepository>(UserRepositoryImpl.new);
    i.addSingleton<UserLoginService>(UserLoginServiceImpl.new);
    i.addSingleton(LoginController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const LoginPage());
  }
}
