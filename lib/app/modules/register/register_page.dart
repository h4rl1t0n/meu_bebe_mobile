import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:validatorless/validatorless.dart';

import '../../core/ui/theme/styles/colors_app.dart';
import '../../core/ui/theme/styles/design_tokens.dart';
import '../../core/ui/theme/styles/text_styles.dart';
import 'register_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final RegisterController controller;

  late final GlobalKey<FormState> formKey;
  late final TextEditingController emailTEC;
  late final TextEditingController passwordTEC;
  late final TextEditingController confirmPasswordTEC;

  @override
  void initState() {
    super.initState();
    controller = Modular.get<RegisterController>();
    formKey = GlobalKey<FormState>();
    emailTEC = TextEditingController();
    passwordTEC = TextEditingController();
    confirmPasswordTEC = TextEditingController();
  }

  @override
  void dispose() {
    emailTEC.dispose();
    passwordTEC.dispose();
    confirmPasswordTEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Criar conta'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: Spacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Cadastre-se para começar',
                      textAlign: TextAlign.center,
                      style: context.textStyles.titleStyle,
                    ),
                    const SizedBox(height: Spacing.xxxl),
                    _field(
                      controller: emailTEC,
                      label: 'E-mail',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validatorless.multiple([
                        Validatorless.required('E-mail obrigatório'),
                        Validatorless.email('E-mail inválido'),
                      ]),
                    ),
                    const SizedBox(height: Spacing.lg),
                    _field(
                      controller: passwordTEC,
                      label: 'Senha',
                      icon: Icons.lock_outline,
                      obscureText: controller.obscurePassword,
                      validator: Validatorless.multiple([
                        Validatorless.required('Senha obrigatória'),
                        Validatorless.min(8, 'Senha deve ter no mínimo 8 caracteres'),
                      ]),
                      suffix: IconButton(
                        onPressed: controller.passwordToggle,
                        icon: Observer(
                          builder: (_) => Icon(
                            controller.obscurePassword ? Icons.visibility : Icons.visibility_off,
                            size: 20,
                            color: colors.darkText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    _field(
                      controller: confirmPasswordTEC,
                      label: 'Confirmar senha',
                      icon: Icons.lock_outline,
                      obscureText: controller.obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Confirmação obrigatória';
                        if (value != passwordTEC.text) return 'As senhas não conferem';
                        return null;
                      },
                      suffix: IconButton(
                        onPressed: controller.confirmPasswordToggle,
                        icon: Observer(
                          builder: (_) => Icon(
                            controller.obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                            color: colors.darkText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xxl),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: colors.darkText),
                        onPressed: controller.loading
                            ? null
                            : () {
                                final valid = formKey.currentState?.validate() ?? false;
                                if (valid) {
                                  controller.register(
                                    emailTEC.text,
                                    passwordTEC.text,
                                    confirmPasswordTEC.text,
                                  );
                                }
                              },
                        child: Observer(
                          builder: (_) {
                            if (controller.loading) {
                              return const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            }
                            return Text(
                              'Criar conta',
                              style: context.textStyles.buttonLargeStyle.copyWith(
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    TextButton(
                      onPressed: () => Modular.to.pop(),
                      child: Text('Já tenho uma conta', style: context.textStyles.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffix,
  }) {
    final colors = context.colors;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: context.textStyles.textStyle.copyWith(color: colors.darkText),
      keyboardType: keyboardType,
      validator: validator,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colors.darkText, size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}
