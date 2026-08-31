import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../app_module.dart';
import '../../core/auth/credential_storage.dart';
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
  final CredentialStorage credentialStorage;
  final OnboardingResolver onboardingResolver;
  final void Function(OnboardingResolution resolution) _navigateReplacement;

  @observable
  bool obscurePassword = true;

  @observable
  bool logged = false;

  @observable
  bool loading = false;

  /// "Lembrar-me": `true` (default) persiste a sessão entre aberturas. `false`
  /// mantém a sessão apenas até o app fechar — os tokens são descartados na
  /// próxima abertura.
  @observable
  bool rememberMe = true;

  /// Credenciais lembradas (lidas no `initialize`) para hidratar o Login.
  ///
  /// NÃO são `@observable`: são consumidas UMA vez na hidratação dos campos
  /// (`TextEditingController`). A senha existe SOMENTE em
  /// [SecureCredentialStorage] e nunca toca SharedPreferences/arquivo/log.
  String? rememberedEmail;
  String? rememberedPassword;

  @action
  void passwordToggle() => obscurePassword = !obscurePassword;

  @action
  void toggleRememberMe(bool? value) => rememberMe = value ?? true;

  LoginControllerBase(
    this.authRepository,
    this.tokenStorage,
    this.credentialStorage,
    this.onboardingResolver, {
    void Function(OnboardingResolution resolution)? navigateReplacement,
  }) : _navigateReplacement = navigateReplacement ?? navigateOnboardingResolution;

  /// Hidrata o estado "Lembrar-me" na abertura da tela de Login.
  ///
  /// Lê a flag persistida e, quando `true`, as credenciais lembradas do
  /// armazenamento seguro. Quando `false`, garante campos vazios.
  @action
  Future<void> initialize() async {
    final remember = await tokenStorage.getRememberMe();
    rememberMe = remember;
    if (remember) {
      rememberedEmail = await credentialStorage.getEmail();
      rememberedPassword = await credentialStorage.getPassword();
    } else {
      rememberedEmail = null;
      rememberedPassword = null;
    }
  }

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
        await tokenStorage.setRememberMe(rememberMe);
        await tokenStorage.saveTokens(accessToken: token.accessToken, refreshToken: token.refreshToken);
        // TOKENS (sessão) ≠ CREDENCIAIS (lembrar-me): os tokens são persistidos
        // sempre para a sessão atual; as credenciais só quando "Lembrar-me".
        if (rememberMe) {
          await credentialStorage.save(email: email, password: password);
        } else {
          await credentialStorage.clear();
        }
        logged = true;
        final resolution = await onboardingResolver.resolve();
        _navigateReplacement(resolution);
    }
  }

  void forgotMyPassword() {
    Messages.showInfo('Entre em contato com o suporte pelo e-mail\nsuporte@meubebe.app para recuperar sua senha.');
  }

  void createAccount() {
    Modular.to.pushNamed(routeRegister);
  }
}
