import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:validatorless/validatorless.dart';

import '../../../../../../app_module.dart';
import '../../../../../../core/extensions/size_extension.dart';
import '../../../../../../core/helpers/messages.dart';
import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/gestante/gestante_model.dart';
import '../../../../../../modules/onboarding/onboarding_route_args.dart';
import 'profile_data_controller.dart';
import 'profile_form_controller.dart';
import 'widgets/custom_text_field.dart';

class ProfileDataPage extends StatefulWidget {
  const ProfileDataPage({super.key});

  @override
  State<ProfileDataPage> createState() => _ProfileDataPageState();
}

class _ProfileDataPageState extends State<ProfileDataPage> with ProfileFormController {
  late final ProfileDataController controller;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    controller = Modular.get<ProfileDataController>();
    _init();
  }

  Future<void> _init() async {
    await controller.initialize();
    initializeForm(controller.gestante, controller.email);
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Observer(
          builder: (_) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              controller.formEnabled ? 'Alterar Dados' : 'Meus Dados',
              key: ValueKey(controller.formEnabled),
              style: textStyles.titleSmallStyle,
            ),
          ),
        ),
      ),
      body: Observer(
        builder: (_) {
          if (controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Container(
            width: context.screenWidth,
            color: colors.secondary,
            child: ListView(children: [_form()]),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Observer(
          builder: (_) => controller.formEnabled ? _saveButton() : _editButton(),
        ),
      ),
    );
  }

  Widget _form() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              _nameField(),
              const SizedBox(height: Spacing.md),
              _socialNameField(),
              const SizedBox(height: Spacing.md),
              _birthDateField(),
              const SizedBox(height: Spacing.md),
              _cpfField(),
              const SizedBox(height: Spacing.md),
              _cnsField(),
              const SizedBox(height: Spacing.md),
              _emailField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nameField() => CustomTextField(
    controller: controller,
    textController: nameEC,
    label: 'Nome',
    validator: Validatorless.required('Nome obrigatório'),
    textCapitalization: TextCapitalization.words,
  );

  Widget _socialNameField() => CustomTextField(
    controller: controller,
    textController: socialNameEC,
    label: 'Nome social',
    textCapitalization: TextCapitalization.words,
  );

  Widget _birthDateField() => CustomTextField(
    controller: controller,
    textController: birthdayEC,
    label: 'Data de nascimento',
    validator: Validatorless.multiple([
      Validatorless.required('Data obrigatória'),
      (value) => dateToIso(value) == null ? 'Data inválida' : null,
    ]),
    keyboardType: TextInputType.datetime,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly, DataInputFormatter()],
  );

  Widget _cpfField() => CustomTextField(
    controller: controller,
    textController: cpfEC,
    label: 'CPF',
    validator: (value) {
      final digits = digitsOnly(value);
      if (digits.isEmpty) return null;
      if (digits.length != 11) return 'CPF deve ter 11 dígitos';
      return null;
    },
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(11),
    ],
  );

  Widget _cnsField() => CustomTextField(
    controller: controller,
    textController: cnsEC,
    label: 'Número do Cartão Nacional de Saúde',
    validator: (value) {
      final digits = digitsOnly(value);
      if (digits.isEmpty) return null;
      if (digits.length != 15) return 'CNS deve ter 15 dígitos';
      return null;
    },
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(15),
    ],
  );

  Widget _emailField() => TextFormField(
    enabled: false,
    controller: emailEC,
    style: context.textStyles.textStyle.copyWith(color: context.colors.darkText),
    decoration: InputDecoration(fillColor: context.colors.primary, label: const Text('E-mail')),
  );

  // -------- Buttons ----------

  SizedBox _saveButton() => _actionButton(
    label: 'Salvar',
    onPressed: controller.loading ? null : _handleSave,
  );

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    final valid = formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final isoDate = dateToIso(birthdayEC.text);
    if (isoDate == null) {
      Messages.showError('Data de nascimento inválida.');
      return;
    }

    final cpf = digitsOnly(cpfEC.text);
    final cns = digitsOnly(cnsEC.text);
    final socialName = socialNameEC.text.trim();

    final success = await controller.saveProfile(
      GestanteModel(
        id: controller.gestante?.id ?? '',
        nome: nameEC.text.trim(),
        nomeSocial: socialName.isEmpty ? null : socialName,
        dataNascimento: isoDate,
        cpf: cpf.isEmpty ? null : cpf,
        cns: cns.isEmpty ? null : cns,
      ),
    );

    if (success && mounted) {
      controller.setFormEnabled(false);
      if (isOnboardingRoute()) {
        Modular.to.pushReplacementNamed(routeGravidezAtual, arguments: onboardingArgs);
      }
    }
  }

  SizedBox _editButton() => _actionButton(label: 'Editar', onPressed: () => controller.setFormEnabled(true));

  SizedBox _actionButton({required String label, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll)),
        onPressed: onPressed,
        child: Text(label, style: context.textStyles.buttonTextStyle),
      ),
    );
  }
}
