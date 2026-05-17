// lib/modules/profile/ui/pages/profile_data_page.dart

import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:validatorless/validatorless.dart';

import '../../../../../../core/extensions/size_extension.dart';
import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/pregnant_data.dart';
import '../../../../../../model/user_data.dart';
import 'profile_data_controller.dart';
import 'profile_form_controller.dart';
import 'widgets/custom_drop_down.dart';
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
    initializeForm(controller.pregnant, controller.user);
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
          builder: (_) {
            return controller.formEnabled ? _saveButton() : _editButton();
          },
        ),
      ),
    );
  }

  Widget _form() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              _nameField(),
              const SizedBox(height: 12),
              _socialNameField(),
              const SizedBox(height: 12),
              _birthDateField(),
              const SizedBox(height: 12),
              _cpfField(),
              const SizedBox(height: 12),
              _emailField(),
              const SizedBox(height: 12),
              _cnsField(),
              const SizedBox(height: 12),
              _prenatalPlaceField(),
              const SizedBox(height: 12),
              _maritalStatusField(),
              const SizedBox(height: 12),
              _educationField(),
              const SizedBox(height: 12),
              _incomeField(),
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
    validator: Validatorless.required('Data obrigatória'),
    keyboardType: TextInputType.datetime,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly, DataInputFormatter()],
  );

  Widget _cpfField() => CustomTextField(
    controller: controller,
    textController: cpfEC,
    label: 'CPF',
    validator: Validatorless.required('CPF obrigatório'),
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly, CpfInputFormatter()],
  );

  Widget _emailField() => CustomTextField(
    controller: controller,
    textController: emailEC,
    label: 'E-mail',
    validator: Validatorless.multiple([
      Validatorless.required('E-mail obrigatório'),
      Validatorless.email('E-mail inválido'),
    ]),
    keyboardType: TextInputType.emailAddress,
  );

  Widget _cnsField() => CustomTextField(
    controller: controller,
    textController: nationalHealthCardEC,
    label: 'Número do Cartão Nacional de Saúde',
    keyboardType: TextInputType.number,
  );

  Widget _prenatalPlaceField() =>
      CustomTextField(controller: controller, textController: prenatalPlaceEC, label: 'Local que realiza o pré-natal');

  Widget _maritalStatusField() =>
      CustomDropDown(label: 'Estado civil', textController: maritalStatusEC, type: 0, controller: controller);

  Widget _educationField() =>
      CustomDropDown(label: 'Nível de escolaridade', textController: educationEC, type: 1, controller: controller);

  Widget _incomeField() =>
      CustomDropDown(label: 'Renda familiar', textController: incomeEC, type: 2, controller: controller);

  // -------- Buttons ----------

  SizedBox _saveButton() => _actionButton(
    label: 'Salvar',
    onPressed: () async {
      FocusScope.of(context).unfocus();

      final valid = formKey.currentState?.validate() ?? false;
      if (!valid) return;

      final success = await controller.saveProfile(
        PregnantData(
          id: controller.pregnant?.id ?? 0,
          name: nameEC.text,
          socialName: socialNameEC.text,
          birthDate: birthdayEC.text,
          cpf: cpfEC.text,
          nationalHealthCard: nationalHealthCardEC.text,
          prenatalPlace: prenatalPlaceEC.text,
          professionalName: controller.pregnant?.professionalName,
          prenatalPlaceContact: controller.pregnant?.prenatalPlaceContact,
        ),
        UserData(
          id: controller.user?.id ?? 0,
          name: controller.user?.name ?? '',
          email: emailEC.text,
          phone: controller.user?.phone,
        ),
      );

      if (success && mounted) {
        controller.setFormEnabled(false);
      }
    },
  );

  SizedBox _editButton() => _actionButton(label: 'Editar', onPressed: () => controller.setFormEnabled(true));

  SizedBox _actionButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
