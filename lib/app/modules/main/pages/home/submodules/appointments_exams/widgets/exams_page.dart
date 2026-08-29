import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:validatorless/validatorless.dart';

import '../../../../../../../core/extensions/size_extension.dart';
import '../../../../../../../core/helpers/civil_date.dart';
import '../../../../../../../core/helpers/messages.dart';
import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../../model/exame/exame_categoria.dart';
import '../../../../../../../model/exame/exame_model.dart';
import '../appointments_exams_controller.dart';
import '../text_controllers/form_text_controller.dart';
import 'card_with_date.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key, required this.controller});

  final AppointmentsExamsController controller;

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> with FormTextController {
  AppointmentsExamsController get _controller => widget.controller;
  final formKey = GlobalKey<FormState>();

  /// Categoria opcional selecionada no cadastro. `null` = não informada.
  CategoriaExame? _categoria;

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.pageH,
        vertical: Spacing.pageV,
      ),
      child: Observer(
        builder: (_) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_controller.hasGestacao) {
            return Center(
              child: Text(
                'Cadastre sua gestação para gerenciar consultas e exames.',
                textAlign: TextAlign.center,
                style: context.textStyles.subTitleStyle,
              ),
            );
          }
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => addExamDialog(),
                  child: const Text('Adicionar exame'),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              _controller.exams.isNotEmpty
                  ? Expanded(
                      child: ListView(
                        children: _controller.exams
                            .map(
                              (exam) => CardWithDate(
                                title: exam.titulo,
                                date: civilDateIsoToDisplay(exam.dataExame),
                                description: exam.descricao,
                                onTap: () {
                                  _controller.deleteExam(exam.id);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : Expanded(
                      child: SizedBox(
                        child: Center(
                          child: Text(
                            'Não foram encontrados exames',
                            style: context.textStyles.subTitleStyle,
                          ),
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  void addExamDialog() {
    showDialog(
      context: context,
      builder: (context) => Form(
        key: formKey,
        child: AlertDialog(
          title: const Text('Adicionar exame'),
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
                  final iso = civilDateDisplayToIso(dateEC.text);
                  if (iso == null) {
                    Messages.showError('Data inválida. Use DD/MM/AAAA.');
                    return;
                  }
                  _controller.saveExam(
                    ExameModel(
                      id: '',
                      titulo: nameEC.text.trim(),
                      dataExame: iso,
                      descricao: descriptionEC.text.trim(),
                      categoria: _categoria?.code,
                    ),
                  );
                  clearControllers();
                  _categoria = null;
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Salvar',
                style: context.textStyles.subTitleStyle.copyWith(
                  color: context.colors.text,
                ),
              ),
            ),
          ],
          content: SizedBox(
            width: context.screenWidth * .8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  nameEC,
                  'Nome do exame',
                  validator: Validatorless.required('Nome obrigatório'),
                ),
                const SizedBox(height: Spacing.sm),
                _buildTextField(
                  dateEC,
                  'Data do exame',
                  validator: Validatorless.required('Data obrigatória'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    DataInputFormatter(),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                _buildTextField(
                  descriptionEC,
                  'Descrição',
                  validator: Validatorless.required('Descrição obrigatória'),
                ),
                const SizedBox(height: Spacing.sm),
                DropdownButtonFormField<CategoriaExame>(
                  decoration: const InputDecoration(
                    labelText: 'Categoria (opcional)',
                  ),
                  initialValue: _categoria,
                  items: [
                    for (final categoria in CategoriaExame.values)
                      DropdownMenuItem<CategoriaExame>(
                        value: categoria,
                        child: Text(categoria.label),
                      ),
                  ],
                  onChanged: (categoria) =>
                      setState(() => _categoria = categoria),
                ),
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
