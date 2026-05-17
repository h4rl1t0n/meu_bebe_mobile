import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../app_module.dart';
import '../../core/helpers/messages.dart';
import '../../services/user_login_service.dart';

part 'login_controller.g.dart';

class LoginController = LoginControllerBase with _$LoginController;

abstract class LoginControllerBase with Store {
  final UserLoginService loginService;

  @observable
  bool obscurePassword = true;

  @observable
  bool logged = false;

  @observable
  bool loading = false;

  @action
  void passwordToggle() => obscurePassword = !obscurePassword;

  LoginControllerBase(this.loginService);

  @action
  Future<void> login(String email, String password) async {
    loading = true;
    final loginResult = await loginService.execute(email, password);
    loading = false;

    switch (loginResult) {
      case Error(error: final failure):
        Messages.showError(failure.message);
      case Success():
        logged = true;
        Modular.to.pushReplacementNamed(routeTab);
    }
  }

  void forgotMyPassword() {
    Messages.showInfo(
      'Entre em contato com o suporte pelo e-mail\nsuporte@meubebe.app para recuperar sua senha.',
    );
  }

  void createAccount() {
    Modular.to.pushNamed(routeForm);
  }
}
