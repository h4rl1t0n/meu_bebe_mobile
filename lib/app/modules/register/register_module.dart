import 'package:flutter_modular/flutter_modular.dart';

import '../../core/auth/token_storage.dart';
import '../../repositories/auth/auth_repository.dart';
import '../../repositories/auth/auth_repository_impl.dart';
import '../core/core_module.dart';
import '../onboarding/onboarding_module.dart';
import 'register_controller.dart';
import 'register_page.dart';

class RegisterModule extends Module {
  @override
  List<Module> get imports => [CoreModule(), OnboardingModule()];

  @override
  void binds(i) {
    i.addSingleton<AuthRepository>(AuthRepositoryImpl.new);
    i.addSingleton<TokenStorage>(TokenStorage.new);
    i.addSingleton(RegisterController.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const RegisterPage());
  }
}
