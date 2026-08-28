import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../app_module.dart';
import '../../core/auth/token_storage.dart';
import '../../core/helpers/messages.dart';
import '../../repositories/auth/auth_repository.dart';

part 'register_controller.g.dart';

class RegisterController = RegisterControllerBase with _$RegisterController;

abstract class RegisterControllerBase with Store {
  final AuthRepository authRepository;
  final TokenStorage tokenStorage;
  final void Function(String route) _navigateReplacement;

  @observable
  bool obscurePassword = true;

  @observable
  bool obscureConfirmPassword = true;

  @observable
  bool loading = false;

  @action
  void passwordToggle() => obscurePassword = !obscurePassword;

  @action
  void confirmPasswordToggle() => obscureConfirmPassword = !obscureConfirmPassword;

  RegisterControllerBase(
    this.authRepository,
    this.tokenStorage, {
    void Function(String route)? navigateReplacement,
  }) : _navigateReplacement = navigateReplacement ?? _defaultNavigateReplacement;

  static void _defaultNavigateReplacement(String route) {
    Modular.to.pushReplacementNamed(route);
  }

  @action
  Future<void> register(String email, String password, String confirmPassword) async {
    if (loading) return;
    if (password != confirmPassword) {
      Messages.showError('As senhas não conferem');
      return;
    }
    loading = true;
    final result = await authRepository.register(email, password);
    loading = false;

    switch (result) {
      case Error(error: final failure):
        Messages.showError(failure.message);
      case Success(success: final token):
        await tokenStorage.saveTokens(
          accessToken: token.accessToken,
          refreshToken: token.refreshToken,
        );
        _navigateReplacement(routeTab);
    }
  }
}
