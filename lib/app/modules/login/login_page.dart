// lib/modules/login/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:validatorless/validatorless.dart';

import '../../app_module.dart';
import '../../core/helpers/messages.dart';
import '../../core/ui/theme/styles/colors_app.dart';
import '../../core/ui/theme/styles/text_styles.dart';
import 'login_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  late final LoginController controller;

  late final GlobalKey<FormState> formKey;
  late final TextEditingController emailTEC;
  late final TextEditingController passwordTEC;

  @override
  void initState() {
    super.initState();
    controller = Modular.get<LoginController>();
    formKey = GlobalKey<FormState>();
    emailTEC = TextEditingController(text: 'fms@oab.am.gov.br');
    passwordTEC = TextEditingController(text: 'fms1622030013');
  }

  @override
  void dispose() {
    emailTEC.dispose();
    passwordTEC.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration({required String label, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: ColorsApp.instance.darkText, size: 20),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Observer(
      builder: (_) {
        return Scaffold(
          backgroundColor: colors.secondary,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          Image.asset('assets/images/mother.png', height: 120),
                          const SizedBox(height: 10),
                          Text(
                            'Bem-vinda',
                            style: textStyles.titleStyle.copyWith(fontSize: 26),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Cuide dos momentos do seu bebê',
                            style: TextStyle(color: colors.darkText.withValues(alpha: 0.7), fontSize: 14),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      TextFormField(
                        controller: emailTEC,
                        style: TextStyle(color: colors.darkText),
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        validator: Validatorless.multiple([
                          Validatorless.required('E-mail obrigatório'),
                          Validatorless.email('E-mail inválido'),
                        ]),
                        decoration: inputDecoration(label: 'E-mail', icon: Icons.email_outlined),
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: passwordTEC,
                        obscureText: controller.obscurePassword,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        validator: Validatorless.required('Senha obrigatória'),
                        style: TextStyle(color: colors.darkText),
                        decoration: inputDecoration(
                          label: 'Senha',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            onPressed: controller.passwordToggle,
                            icon: Observer(
                              builder: (context) {
                                return Icon(
                                  size: 20,
                                  controller.obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: colors.darkText,
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Messages.showError('Funcionalidade ainda não implementada');
                          },
                          child: const Text('Esqueceu a senha?', style: TextStyle(fontSize: 16)),
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.darkText,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            final valid = formKey.currentState?.validate() ?? false;

                            if (valid) {
                              Modular.to.pushReplacementNamed(routeTab);
                            }
                          },
                          label: const Text('Entrar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('ou', style: TextStyle(color: colors.darkText.withValues(alpha: 0.6))),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 15),

                      TextButton.icon(
                        onPressed: () {
                          Modular.to.pushNamed(routeForm);
                        },
                        icon: const Icon(Icons.person_add_alt_1, size: 22),
                        label: const Text(
                          'Criar nova conta',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
