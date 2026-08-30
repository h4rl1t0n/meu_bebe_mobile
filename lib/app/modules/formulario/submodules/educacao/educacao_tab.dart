import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../catalog/educacao_options.dart';
import '../../widgets/dss_question.dart';
import '../../widgets/item_tab_page.dart';
import 'educacao_controller.dart';
import 'educacao_validator.dart';

class EducacaoTab extends StatefulWidget {
  const EducacaoTab({super.key});

  @override
  State<EducacaoTab> createState() => _EducacaoTabState();
}

class _EducacaoTabState extends State<EducacaoTab> {
  final formKey = GlobalKey<FormState>();
  final controller = Modular.get<EducacaoController>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Observer(
        builder: (_) => ItemTabPage(
          title: 'Educação',
          children: [
            DssBinaryQuestion(
              title: 'Está estudando atualmente?',
              value: controller.estuda,
              onChanged: controller.setEstuda,
              required: true,
              showError: controller.showErrors,
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<Escolaridade>(
              decoration: const InputDecoration(
                labelText: 'Qual seu grau de escolaridade? *',
                border: OutlineInputBorder(),
              ),
              initialValue: controller.escolaridade,
              items: Escolaridade.values.map((Escolaridade value) {
                return DropdownMenuItem<Escolaridade>(value: value, child: Text(value.label));
              }).toList(),
              onChanged: (val) => controller.setEscolaridade(val),
              validator: EducacaoValidator.escolaridade,
            ),
            SizedBox(height: Spacing.lg),
            _situacaoEstudos(
              'Qual situação melhor descreve seus estudos durante esta gestação?',
              controller.situacaoEstudosGestacao,
              controller.setSituacaoEstudosGestacao,
            ),
            SizedBox(height: Spacing.lg),
            DssMultiChoiceQuestion<DificuldadeEducacao>(
              title: 'Que dificuldades enfrenta no acesso à educação?',
              options: DificuldadeEducacao.values,
              selected: controller.dificuldadesEscolares,
              labelOf: (d) => d.label,
              onToggle: controller.toggleDificuldade,
              required: true,
              showError: controller.showErrors,
              exclusive: DificuldadeEducacao.semDificuldades,
            ),
            SizedBox(height: Spacing.lg),
            DssBinaryQuestion(
              title: 'Você consegue entender bem as orientações dos profissionais de saúde?',
              value: controller.entendeOrientacoes,
              onChanged: controller.setEntendeOrientacoes,
              required: true,
              showError: controller.showErrors,
            ),
            SizedBox(height: Spacing.lg),
            DssBinaryQuestion(
              title: 'Faz ou fez algum curso profissionalizante ou de qualificação?',
              value: controller.fezCursoQualificacaoProfissional,
              onChanged: controller.setFezCursoQualificacaoProfissional,
              required: true,
              showError: controller.showErrors,
            ),
          ],
        ),
      ),
    );
  }

  /// Situação dos estudos na gestação: pergunta categórica de escolha única,
  /// inicia em `null` (nada pré-selecionado).
  Widget _situacaoEstudos(
    String title,
    SituacaoEstudosGestacao? value,
    ValueChanged<SituacaoEstudosGestacao?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        SizedBox(height: Spacing.sm),
        RadioGroup<SituacaoEstudosGestacao>(
          groupValue: value,
          onChanged: onChanged,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: SituacaoEstudosGestacao.values
                .map(
                  (e) => RadioListTile<SituacaoEstudosGestacao>(
                    title: Text(e.label),
                    value: e,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
