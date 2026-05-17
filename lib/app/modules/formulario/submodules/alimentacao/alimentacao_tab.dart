import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../core/ui/theme/styles/text_styles.dart';
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
                RadioGroup<int>(
                  groupValue: controller.refeicoesPorDia,
                  onChanged: (v) => controller.setRefeicoesPorDia(v ?? 0),
                  child: Column(
                    children: const [
                      RadioListTile<int>(title: Text('1-2 refeições'), value: 1),
                      RadioListTile<int>(title: Text('3 refeições'), value: 3),
                      RadioListTile<int>(title: Text('4 ou mais refeições'), value: 4),
                    ],
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
            Text('Quais alimentos você consome regularmente?', style: context.textStyles.subTitleSmallStyle),
            CheckboxListTile(
              title: const Text('Frutas e verduras'),
              value: controller.consomeFrutasVerduras,
              onChanged: (v) => controller.setConsomeFrutasVerduras(v ?? false),
            ),
            CheckboxListTile(
              title: const Text('Carnes (vermelha, frango ou peixe)'),
              value: controller.consomeCarnes,
              onChanged: (v) => controller.setConsomeCarnes(v ?? false),
            ),
            CheckboxListTile(
              title: const Text('Leite e derivados'),
              value: controller.consomeLeite,
              onChanged: (v) => controller.setConsomeLeite(v ?? false),
            ),
            CheckboxListTile(
              title: const Text('Feijão e outras leguminosas'),
              value: controller.consomeFeijao,
              onChanged: (v) => controller.setConsomeFeijao(v ?? false),
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'De onde vem os alimentos que você consome?',
                border: OutlineInputBorder(),
              ),
              validator: AlimentacaoValidator.fonteAlimentos,
              initialValue: controller.fonteAlimentos.isNotEmpty ? controller.fonteAlimentos : null,
              items: const [
                DropdownMenuItem(value: 'Supermercado/feira', child: Text('Supermercado/feira')),
                DropdownMenuItem(value: 'Horta própria', child: Text('Horta própria')),
                DropdownMenuItem(value: 'Doações', child: Text('Doações')),
                DropdownMenuItem(value: 'Cesta básica', child: Text('Cesta básica')),
                DropdownMenuItem(value: 'Outro', child: Text('Outro')),
              ],
              onChanged: (v) => controller.setFonteAlimentos(v ?? ''),
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
                RadioGroup<String>(
                  groupValue: controller.avaliacaoAlimentacao,
                  onChanged: (v) => controller.setAvaliacaoAlimentacao(v ?? ''),
                  child: Column(
                    children: const [
                      RadioListTile<String>(
                        title: Text('Muito boa - atende todas minhas necessidades'),
                        value: 'Muito boa',
                      ),
                      RadioListTile<String>(title: Text('Boa - com algumas limitações'), value: 'Boa'),
                      RadioListTile<String>(title: Text('Regular - poderia ser melhor'), value: 'Regular'),
                      RadioListTile<String>(title: Text('Ruim - não atende minhas necessidades'), value: 'Ruim'),
                    ],
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
