import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../core/ui/theme/styles/text_styles.dart';
import '../../catalog/alimentacao_options.dart';
import '../../widgets/item_tab_page.dart';
import 'alimentacao_controller.dart';

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
            _simNao(
              'Nos últimos 3 meses, deixou de comer por falta de dinheiro?',
              controller.deixouDeComerFaltaDinheiro,
              controller.setDeixouComerFaltaDinheiro,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('De onde vêm os alimentos que você consome?', style: context.textStyles.subTitleSmallStyle),
                ...FonteAlimentos.values.map(
                  (f) => CheckboxListTile(
                    title: Text(f.label),
                    value: controller.fonteAlimentos.contains(f),
                    onChanged: (_) => controller.toggleFonteAlimento(f),
                  ),
                ),
              ],
            ),
            SizedBox(height: Spacing.lg),
            _simNao(
              'Sua alimentação mudou durante a gestação?',
              controller.mudancaAlimentacaoGestacao,
              controller.setMudancaAlimentacaoGestacao,
            ),
            _simNao(
              'Está tomando suplementos vitamínicos ou de ferro?',
              controller.usaSuplementos,
              controller.setUsaSuplementos,
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
}
