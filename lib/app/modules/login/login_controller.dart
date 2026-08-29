import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../app_module.dart';
import '../../core/auth/token_storage.dart';
import '../../core/helpers/messages.dart';
import '../../repositories/auth/auth_repository.dart';
import '../onboarding/onboarding_navigator.dart';
import '../onboarding/onboarding_resolution.dart';
import '../onboarding/onboarding_resolver.dart';

part 'login_controller.g.dart';

class LoginController = LoginControllerBase with _$LoginController;

abstract class LoginControllerBase with Store {
  final AuthRepository authRepository;
  final TokenStorage tokenStorage;
  final OnboardingResolver onboardingResolver;
  final void Function(OnboardingResolution resolution) _navigateReplacement;

  @observable
  bool obscurePassword = true;

  @observable
  bool logged = false;

  @observable
  bool loading = false;

  @action
  void passwordToggle() => obscurePassword = !obscurePassword;

  LoginControllerBase(
    this.authRepository,
    this.tokenStorage,
    this.onboardingResolver, {
    void Function(OnboardingResolution resolution)? navigateReplacement,
  }) : _navigateReplacement =
           navigateReplacement ?? navigateOnboardingResolution;

  @action
  Future<void> login(String email, String password) async {
    if (loading) return;
    loading = true;
    final loginResult = await authRepository.login(email, password);
    loading = false;

    switch (loginResult) {
      case Error(error: final failure):
        Messages.showError(failure.message);
      case Success(success: final token):
        await tokenStorage.saveTokens(
          accessToken: token.accessToken,
          refreshToken: token.refreshToken,
        );
        logged = true;
        final resolution = await onboardingResolver.resolve();
        _navigateReplacement(resolution);
    }
  }

  void forgotMyPassword() {
    Messages.showInfo(
      'Entre em contato com o suporte pelo e-mail\nsuporte@meubebe.app para recuperar sua senha.',
    );
  }

  void createAccount() {
    Modular.to.pushNamed(routeRegister);
  }
}
