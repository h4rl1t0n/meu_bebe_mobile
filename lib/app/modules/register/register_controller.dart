import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/auth/token_storage.dart';
import '../../core/helpers/messages.dart';
import '../../repositories/auth/auth_repository.dart';
import '../onboarding/onboarding_navigator.dart';
import '../onboarding/onboarding_resolution.dart';
import '../onboarding/onboarding_resolver.dart';

part 'register_controller.g.dart';

class RegisterController = RegisterControllerBase with _$RegisterController;

abstract class RegisterControllerBase with Store {
  final AuthRepository authRepository;
  final TokenStorage tokenStorage;
  final OnboardingResolver onboardingResolver;
  final void Function(OnboardingResolution resolution) _navigateReplacement;

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
    this.tokenStorage,
    this.onboardingResolver, {
    void Function(OnboardingResolution resolution)? navigateReplacement,
  }) : _navigateReplacement =
           navigateReplacement ?? navigateOnboardingResolution;

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
        final resolution = await onboardingResolver.resolve();
        _navigateReplacement(resolution);
    }
  }
}
