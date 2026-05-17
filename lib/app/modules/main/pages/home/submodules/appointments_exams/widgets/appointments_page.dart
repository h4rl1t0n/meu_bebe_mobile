import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:validatorless/validatorless.dart';

import '../../../../../../../core/extensions/size_extension.dart';
import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../../model/appointment.dart';
import '../appointments_exams_controller.dart';
import '../text_controllers/form_text_controller.dart';
import 'card_with_date.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key, required this.controller});

  final AppointmentsExamsController controller;

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> with FormTextController {
  AppointmentsExamsController get _controller => widget.controller;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.updated) {
        _controller.resetUpdated();
      }
    });
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
      child: Observer(
        builder: (_) => Visibility(
          visible: !_controller.updated,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(onPressed: () => addAppointmentDialog(), child: const Text('Adicionar consulta')),
              ),
              const SizedBox(height: Spacing.lg),
              _controller.appointments.isNotEmpty
                  ? Expanded(
                      child: ListView(
                        children: _controller.appointments
                            .map(
                              (appointment) => CardWithDate(
                                title: appointment.title,
                                date: appointment.appointmentDate,
                                description: appointment.description,
                                onTap: () {
                                  _controller.deleteAppointment(appointment.id);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : Expanded(
                      child: SizedBox(
                        child: Center(
                          child: Text('Não foram encontradas consultas', style: context.textStyles.subTitleStyle),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void addAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => Form(
        key: formKey,
        child: AlertDialog(
          title: const Text('Adicionar consulta'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: context.textStyles.subTitleStyle),
            ),
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                final valid = formKey.currentState?.validate() ?? false;
                if (valid) {
                  _controller.saveAppointment(
                    Appointment(
                      id: 0,
                      title: nameEC.text,
                      appointmentDate: dateEC.text,
                      description: descriptionEC.text,
                    ),
                  );
                  clearControllers();
                  Navigator.pop(context);
                }
              },
              child: Text('Salvar', style: context.textStyles.subTitleStyle.copyWith(color: context.colors.text)),
            ),
          ],
          content: SizedBox(
            width: context.screenWidth * .8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameEC, 'Nome da consulta', validator: Validatorless.required('Nome obrigatório')),
                const SizedBox(height: Spacing.sm),
                _buildTextField(
                  dateEC,
                  'Data da consulta',
                  validator: Validatorless.required('Data obrigatória'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, DataInputFormatter()],
                ),
                const SizedBox(height: Spacing.sm),
                _buildTextField(descriptionEC, 'Descrição', validator: Validatorless.required('Descrição obrigatória')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextField(
    TextEditingController controller,
    String label, {
    FormFieldValidator<String?>? validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization captalization = TextCapitalization.sentences,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(label: Text(label)),
      keyboardType: keyboardType,
      textCapitalization: captalization,
      inputFormatters: inputFormatters,
    );
  }
}
