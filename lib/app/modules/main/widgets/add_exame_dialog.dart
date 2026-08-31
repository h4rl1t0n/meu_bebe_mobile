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
import '../../../model/exame/exame_categoria.dart';
import '../../../model/exame/exame_model.dart';

/// Diálogo canônico de cadastro de EXAME (fonte única Home + Gestação).
///
/// Encapsula o `Form` + validação + parse de data + categoria opcional.
/// Retorna via [showAddExameDialog] um [ExameModel] pronto para o caller
/// persistir, ou `null` se cancelado. A persistência fica no caller.
class AddExameDialog extends StatefulWidget {
  const AddExameDialog({super.key});

  @override
  State<AddExameDialog> createState() => _AddExameDialogState();
}

class _AddExameDialogState extends State<AddExameDialog> {
  final formKey = GlobalKey<FormState>();
  final nameEC = TextEditingController();
  final dateEC = TextEditingController();
  final descriptionEC = TextEditingController();

  /// Categoria opcional selecionada no cadastro. `null` = não informada.
  ///
  /// Sem `setState`: o [DropdownButtonFormField] gerencia a exibição do valor
  /// selecionado no seu próprio `FormFieldState`; aqui só lemos o valor no
  /// submit.
  CategoriaExame? _categoria;

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
        title: const Text('Adicionar exame'),
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
              _buildTextField(nameEC, 'Nome do exame', validator: Validatorless.required('Nome obrigatório')),
              const SizedBox(height: Spacing.sm),
              _buildTextField(
                dateEC,
                'Data do exame',
                validator: Validatorless.required('Data obrigatória'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, DataInputFormatter()],
              ),
              const SizedBox(height: Spacing.sm),
              _buildTextField(descriptionEC, 'Descrição', validator: Validatorless.required('Descrição obrigatória')),
              const SizedBox(height: Spacing.sm),
              DropdownButtonFormField<CategoriaExame>(
                decoration: const InputDecoration(labelText: 'Categoria (opcional)'),
                initialValue: _categoria,
                items: [
                  for (final categoria in CategoriaExame.values)
                    DropdownMenuItem<CategoriaExame>(value: categoria, child: Text(categoria.label)),
                ],
                onChanged: (categoria) => _categoria = categoria,
              ),
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
      ExameModel(
        id: '',
        titulo: nameEC.text.trim(),
        dataExame: iso,
        descricao: descriptionEC.text.trim(),
        categoria: _categoria?.code,
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

/// Abre o diálogo de exame e retorna o [ExameModel] (ou `null`).
Future<ExameModel?> showAddExameDialog(BuildContext context) {
  return showDialog<ExameModel>(context: context, builder: (_) => const AddExameDialog());
}
