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
            SwitchListTile(
              title: const Text('Está estudando atualmente?'),
              value: controller.estuda,
              onChanged: controller.setEstuda,
            ),
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
            SwitchListTile(
              title: const Text('Já teve que interromper os estudos por causa da gestação?'),
              value: controller.interrompeuEstudos,
              onChanged: controller.setInterrompeuEstudos,
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
            SwitchListTile(
              title: const Text('Você consegue entender bem as orientações dos profissionais de saúde?'),
              value: controller.entendeOrientacoes,
              onChanged: controller.setEntendeOrientacoes,
            ),
            SizedBox(height: Spacing.lg),
            SwitchListTile(
              title: const Text('Faz ou fez algum curso extracurricular?'),
              value: controller.fezCursoExtracurricular,
              onChanged: controller.setFezCursoExtracurricular,
            ),
          ],
        ),
      ),
    );
  }
}
