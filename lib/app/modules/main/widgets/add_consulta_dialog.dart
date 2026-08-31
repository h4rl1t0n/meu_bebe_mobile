import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:validatorless/validatorless.dart';

import '../../../core/extensions/size_extension.dart';
import '../../../core/helpers/civil_date.dart';
import '../../../core/helpers/messages.dart';
import '../../../core/ui/theme/styles/colors_app.dart';
import '../../../core/ui/theme/styles/design_tokens.dart';
import '../../../core/ui/theme/styles/text_styles.dart';
import '../../../model/consulta/consulta_model.dart';

/// Diálogo canônico de cadastro de CONSULTA (fonte única Home + Gestação).
///
/// Encapsula o `Form` + validação + parse de data. Retorna via
/// [showAddConsultaDialog] um [ConsultaModel] pronto para o caller persistir,
/// ou `null` se cancelado. A persistência (e sua mensagem) fica no caller.
class AddConsultaDialog extends StatefulWidget {
  const AddConsultaDialog({super.key});

  @override
  State<AddConsultaDialog> createState() => _AddConsultaDialogState();
}

class _AddConsultaDialogState extends State<AddConsultaDialog> {
  final formKey = GlobalKey<FormState>();
  final nameEC = TextEditingController();
  final dateEC = TextEditingController();
  final descriptionEC = TextEditingController();

  @override
  void dispose() {
    nameEC.dispose();
    dateEC.dispose();
    descriptionEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: AlertDialog(
        title: const Text('Adicionar consulta'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: context.textStyles.subTitleStyle),
          ),
          TextButton(
            onPressed: _submit,
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
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final valid = formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final iso = civilDateDisplayToIso(dateEC.text);
    if (iso == null) {
      Messages.showError('Data inválida. Use DD/MM/AAAA.');
      return;
    }

    Navigator.pop(
      context,
      ConsultaModel(id: '', titulo: nameEC.text.trim(), dataConsulta: iso, descricao: descriptionEC.text.trim()),
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

/// Abre o diálogo de consulta e retorna o [ConsultaModel] (ou `null`).
Future<ConsultaModel?> showAddConsultaDialog(BuildContext context) {
  return showDialog<ConsultaModel>(context: context, builder: (_) => const AddConsultaDialog());
}
