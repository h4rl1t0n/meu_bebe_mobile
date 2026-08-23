import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../catalog/educacao_options.dart';
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
            _simNao('Está estudando atualmente?', controller.estuda, controller.setEstuda),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<Escolaridade>(
              decoration: const InputDecoration(
                labelText: 'Qual seu grau de escolaridade?',
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
            const Text('Que dificuldades enfrenta no acesso à educação?'),
            SizedBox(height: Spacing.sm),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: DificuldadeEducacao.values.map((dificuldade) {
                return Observer(
                  builder: (_) {
                    final isSelected = controller.dificuldadesEscolares.contains(dificuldade);
                    return FilterChip(
                      label: Text(dificuldade.label),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        controller.toggleDificuldade(dificuldade);
                      },
                    );
                  },
                );
              }).toList(),
            ),
            SizedBox(height: Spacing.lg),
            _simNao(
              'Você consegue entender bem as orientações dos profissionais de saúde?',
              controller.entendeOrientacoes,
              controller.setEntendeOrientacoes,
            ),
            SizedBox(height: Spacing.lg),
            _simNao(
              'Faz ou fez algum curso profissionalizante ou de qualificação?',
              controller.fezCursoQualificacaoProfissional,
              controller.setFezCursoQualificacaoProfissional,
            ),
          ],
        ),
      ),
    );
  }

  /// Pergunta de Sim/Não com três estados: `null` (ainda não respondido),
  /// `true` (Sim) e `false` (Não). Nada fica pré-selecionado.
  Widget _simNao(String title, bool? value, ValueChanged<bool?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        SizedBox(height: Spacing.sm),
        RadioGroup<bool>(
          groupValue: value,
          onChanged: onChanged,
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(title: const Text('Sim'), value: true),
              ),
              Expanded(
                child: RadioListTile<bool>(title: const Text('Não'), value: false),
              ),
            ],
          ),
        ),
      ],
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
