// lib/modules/login/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:validatorless/validatorless.dart';

import '../../app_module.dart';
import '../../core/constants/images.dart';
import '../../core/ui/theme/styles/colors_app.dart';
import '../../core/ui/theme/styles/design_tokens.dart';
import '../../core/ui/theme/styles/text_styles.dart';
import 'login_controller.dart';
import 'widgets/chip_login.dart';

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
    // final textStyles = context.textStyles;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(color: colors.primary300, height: 280, width: double.infinity),
                                Container(
                                  height: 50,
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, 10),
                                  child: Card(
                                    color: Colors.transparent,
                                    elevation: 7,
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: colors.secondary.withValues(alpha: 0.10),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                        color: Colors.white,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Hero(
                                        tag: 'logo',
                                        child: Material(
                                          color: Colors.transparent,
                                          shape: const CircleBorder(),
                                          clipBehavior: Clip.antiAlias,
                                          child: Image.asset(Images.mother, fit: BoxFit.contain),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 430),
                                  child: Form(
                                    key: formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const Spacer(flex: 2),

                                        const Text(
                                          'Bem-vinda',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
                                        ),

                                        const Text(
                                          'Cuide dos momentos do seu bebê',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 18.0),
                                        ),

                                        const SizedBox(height: 32),

                                        TextFormField(
                                          controller: emailTEC,
                                          style: context.textStyles.textStyle.copyWith(color: colors.darkText),
                                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                                          validator: Validatorless.multiple([
                                            Validatorless.required('E-mail obrigatório'),
                                            Validatorless.email('E-mail inválido'),
                                          ]),
                                          decoration: inputDecoration(label: 'E-mail', icon: Icons.email_outlined),
                                        ),

                                        const SizedBox(height: 16),

                                        TextFormField(
                                          controller: passwordTEC,
                                          obscureText: controller.obscurePassword,
                                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                                          validator: Validatorless.required('Senha obrigatória'),
                                          style: context.textStyles.textStyle.copyWith(color: colors.darkText),
                                          decoration: inputDecoration(
                                            label: 'Senha',
                                            icon: Icons.lock_outline,
                                            suffix: IconButton(
                                              onPressed: controller.passwordToggle,
                                              icon: Observer(
                                                builder: (context) {
                                                  return Icon(
                                                    size: 20,
                                                    controller.obscurePassword
                                                        ? Icons.visibility
                                                        : Icons.visibility_off,
                                                    color: colors.darkText,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          controlAffinity: ListTileControlAffinity.leading,
                                          title: const Text('Lembrar-me', style: TextStyle(fontSize: 14)),
                                          value: true,
                                          onChanged: (value) {},
                                        ),

                                        const SizedBox(height: 10),

                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: colors.darkText),
                                          onPressed: () {
                                            final valid = formKey.currentState?.validate() ?? false;
                                            if (valid) {
                                              Modular.to.pushReplacementNamed(routeTab);
                                              //controller.login(emailTEC.text, passwordTEC.text);
                                            }
                                          },
                                          child: Observer(
                                            builder: (context) {
                                              if (controller.loading) {
                                                return const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                );
                                              }

                                              return Text(
                                                'Entrar',
                                                style: context.textStyles.buttonLargeStyle.copyWith(
                                                  color: Colors.white,
                                                ),
                                              );
                                            },
                                          ),
                                        ),

                                        SizedBox(height: Spacing.xl),

                                        Row(
                                          children: [
                                            const Expanded(child: Divider()),
                                            Padding(
                                              padding: EdgeInsets.symmetric(horizontal: Spacing.sm),
                                              child: Text(
                                                'ou',
                                                style: context.textStyles.bodySmall.copyWith(color: colors.primary400),
                                              ),
                                            ),
                                            const Expanded(child: Divider()),
                                          ],
                                        ),

                                        SizedBox(height: Spacing.lg),

                                        ChipLogin(
                                          label: 'Criar nova conta',
                                          icon: Icons.person_add,
                                          onTap: () {
                                            Modular.to.pushNamed(routeForm);
                                          },
                                        ),

                                        const Spacer(flex: 3),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    // return Observer(
    //   builder: (_) {
    //     return Scaffold(
    //       backgroundColor: colors.secondary,
    //       body: Center(
    //         child: SingleChildScrollView(
    //           padding: EdgeInsets.all(Spacing.lg),
    //           child: Container(
    //             padding: EdgeInsets.all(Spacing.xl),
    //             decoration: BoxDecoration(
    //               color: colors.surface,
    //               borderRadius: RadiusTokens.xxlAll,
    //               boxShadow: [ElevationTokens.raisedShadow(colors.onSurface)],
    //             ),
    //             child: Form(
    //               key: formKey,
    //               child: Column(
    //                 crossAxisAlignment: CrossAxisAlignment.stretch,
    //                 children: [
    //                   Column(
    //                     children: [
    //                       Image.asset(Images.mother, height: 120),
    //                       SizedBox(height: Spacing.sm),
    //                       Text(
    //                         'Bem-vinda',
    //                         style: textStyles.titleStyle.copyWith(fontSize: 26),
    //                         textAlign: TextAlign.center,
    //                       ),
    //                       SizedBox(height: Spacing.xs),
    //                       Text(
    //                         'Cuide dos momentos do seu bebê',
    //                         style: context.textStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
    //                       ),
    //                     ],
    //                   ),

    //                   SizedBox(height: Spacing.xxxl),

    //                   TextFormField(
    //                     controller: emailTEC,
    //                     style: context.textStyles.textStyle.copyWith(color: colors.darkText),
    //                     onTapOutside: (_) => FocusScope.of(context).unfocus(),
    //                     validator: Validatorless.multiple([
    //                       Validatorless.required('E-mail obrigatório'),
    //                       Validatorless.email('E-mail inválido'),
    //                     ]),
    //                     decoration: inputDecoration(label: 'E-mail', icon: Icons.email_outlined),
    //                   ),

    //                   SizedBox(height: Spacing.xl),

    //                   TextFormField(
    //                     controller: passwordTEC,
    //                     obscureText: controller.obscurePassword,
    //                     onTapOutside: (_) => FocusScope.of(context).unfocus(),
    //                     validator: Validatorless.required('Senha obrigatória'),
    //                     style: context.textStyles.textStyle.copyWith(color: colors.darkText),
    //                     decoration: inputDecoration(
    //                       label: 'Senha',
    //                       icon: Icons.lock_outline,
    //                       suffix: IconButton(
    //                         onPressed: controller.passwordToggle,
    //                         icon: Observer(
    //                           builder: (context) {
    //                             return Icon(
    //                               size: 20,
    //                               controller.obscurePassword ? Icons.visibility : Icons.visibility_off,
    //                               color: colors.darkText,
    //                             );
    //                           },
    //                         ),
    //                       ),
    //                     ),
    //                   ),

    //                   SizedBox(height: Spacing.sm),

    //                   Align(
    //                     alignment: Alignment.centerRight,
    //                     child: TextButton(
    //                       onPressed: controller.forgotMyPassword,
    //                       child: Text('Esqueceu a senha?', style: context.textStyles.textStyle),
    //                     ),
    //                   ),

    //                   SizedBox(height: Spacing.lg),

    //                   SizedBox(
    //                     height: 50,
    //                     child: Observer(
    //                       builder: (_) {
    //                         return ElevatedButton.icon(
    //                           icon: controller.loading
    //                               ? const SizedBox(
    //                                   width: 18,
    //                                   height: 18,
    //                                   child: CircularProgressIndicator(strokeWidth: 2),
    //                                 )
    //                               : const Icon(Icons.login),
    //                           style: ElevatedButton.styleFrom(
    //                             backgroundColor: colors.darkText,
    //                             shape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll),
    //                           ),
    //                           onPressed: controller.loading
    //                               ? null
    //                               : () {
    //                                   final valid = formKey.currentState?.validate() ?? false;
    //                                   if (valid) {
    //                                     Modular.to.pushReplacementNamed(routeTab);
    //                                     //controller.login(emailTEC.text, passwordTEC.text);
    //                                   }
    //                                 },
    //                           label: Text(
    //                             'Entrar',
    //                             style: context.textStyles.buttonLargeStyle.copyWith(color: Colors.white),
    //                           ),
    //                         );
    //                       },
    //                     ),
    //                   ),

    //                   SizedBox(height: Spacing.xl),

    //                   Row(
    //                     children: [
    //                       const Expanded(child: Divider()),
    //                       Padding(
    //                         padding: EdgeInsets.symmetric(horizontal: Spacing.sm),
    //                         child: Text(
    //                           'ou',
    //                           style: context.textStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
    //                         ),
    //                       ),
    //                       const Expanded(child: Divider()),
    //                     ],
    //                   ),

    //                   SizedBox(height: Spacing.lg),

    //                   TextButton.icon(
    //                     onPressed: () {
    //                       Modular.to.pushNamed(routeForm);
    //                     },
    //                     icon: const Icon(Icons.person_add_alt_1, size: 22),
    //                     label: Text('Criar nova conta', style: context.textStyles.bodyMedium),
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           ),
    //         ),
    //       ),
    //     );
    //   },
    // );
  }
}
