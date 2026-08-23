import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../core/ui/theme/styles/text_styles.dart';
import '../../catalog/alimentacao_options.dart';
import '../../widgets/item_tab_page.dart';
import 'alimentacao_controller.dart';
import 'alimentacao_validator.dart';

class AlimentacaoTab extends StatefulWidget {
  const AlimentacaoTab({super.key});

  @override
  State<AlimentacaoTab> createState() => _AlimentacaoTabState();
}

class _AlimentacaoTabState extends State<AlimentacaoTab> {
  final formKey = GlobalKey<FormState>();
  final controller = Modular.get<AlimentacaoController>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Observer(
        builder: (_) => ItemTabPage(
          title: 'Alimentação',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quantas refeições completas você faz por dia?', style: context.textStyles.subTitleSmallStyle),
                RadioGroup<RefeicoesPorDia>(
                  groupValue: controller.refeicoesPorDia,
                  onChanged: (v) => controller.setRefeicoesPorDia(v),
                  child: Column(
                    children: RefeicoesPorDia.values
                        .map((e) => RadioListTile<RefeicoesPorDia>(title: Text(e.label), value: e))
                        .toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: Spacing.lg),
            SwitchListTile(
              title: const Text('Nos últimos 3 meses, deixou de comer por falta de dinheiro?'),
              value: controller.insegurancaAlimentar,
              onChanged: controller.setInsegurancaAlimentar,
            ),
            SizedBox(height: Spacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quais alimentos você consome regularmente?', style: context.textStyles.subTitleSmallStyle),
                ...AlimentoConsumido.values.map(
                  (a) => CheckboxListTile(
                    title: Text(a.label),
                    value: controller.alimentosConsumidos.contains(a),
                    onChanged: (_) => controller.toggleAlimento(a),
                  ),
                ),
              ],
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<FonteAlimentos>(
              decoration: const InputDecoration(
                labelText: 'De onde vem os alimentos que você consome?',
                border: OutlineInputBorder(),
              ),
              validator: AlimentacaoValidator.fonteAlimentos,
              initialValue: controller.fonteAlimentos,
              items: FonteAlimentos.values
                  .map((e) => DropdownMenuItem<FonteAlimentos>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setFonteAlimentos(v),
            ),
            SizedBox(height: Spacing.lg),
            SwitchListTile(
              title: const Text('Sua alimentação mudou durante a gestação?'),
              subtitle: const Text('Seja por orientação médica ou outros motivos'),
              value: controller.mudancaAlimentacaoGestacao,
              onChanged: controller.setMudancaAlimentacaoGestacao,
            ),
            SwitchListTile(
              title: const Text('Está tomando suplementos vitamínicos ou de ferro?'),
              value: controller.usaSuplementos,
              onChanged: controller.setUsaSuplementos,
            ),
            SizedBox(height: Spacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Como você avalia sua alimentação durante a gestação?',
                  style: context.textStyles.subTitleSmallStyle,
                ),
                RadioGroup<AvaliacaoAlimentacao>(
                  groupValue: controller.avaliacaoAlimentacao,
                  onChanged: (v) => controller.setAvaliacaoAlimentacao(v),
                  child: Column(
                    children: AvaliacaoAlimentacao.values
                        .map((e) => RadioListTile<AvaliacaoAlimentacao>(title: Text(e.label), value: e))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool validateTab() => formKey.currentState?.validate() ?? false;
}
