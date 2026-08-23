import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../core/ui/theme/styles/text_styles.dart';
import '../../catalog/habitacao_options.dart';
import '../../widgets/item_tab_page.dart';
import 'habitacao_controller.dart';
import 'habitacao_validator.dart';

class HabitacaoTab extends StatefulWidget {
  const HabitacaoTab({super.key});

  @override
  State<HabitacaoTab> createState() => _HabitacaoTabState();
}

class _HabitacaoTabState extends State<HabitacaoTab> {
  final formKey = GlobalKey<FormState>();
  final controller = Modular.get<HabitacaoController>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Observer(
        builder: (_) => ItemTabPage(
          title: 'Habitação',
          children: [
            DropdownButtonFormField<TipoMoradia>(
              decoration: const InputDecoration(
                labelText: 'Tipo de moradia',
                border: OutlineInputBorder(),
                hintText: 'Selecione o tipo de residência',
              ),
              validator: HabitacaoValidator.tipoMoradia,
              initialValue: controller.tipoMoradia,
              items: TipoMoradia.values
                  .map((e) => DropdownMenuItem<TipoMoradia>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setTipoMoradia(v),
            ),
            SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Nº de pessoas na casa', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: HabitacaoValidator.numeroPessoas,
                    onChanged: (v) => controller.setNumeroPessoas(int.tryParse(v) ?? 0),
                  ),
                ),
                SizedBox(width: Spacing.lg),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Nº de cômodos', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => controller.setNumeroComodos(int.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            SizedBox(height: Spacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quais destes itens sua casa possui?', style: context.textStyles.subTitleSmallStyle),
                SizedBox(height: Spacing.sm),
                ...ItemResidencia.values.map(
                  (i) => CheckboxListTile(
                    title: Text(i.label),
                    value: controller.itensResidencia.contains(i),
                    onChanged: (_) => controller.toggleItemResidencia(i),
                  ),
                ),
              ],
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<SegurancaResidencia>(
              decoration: const InputDecoration(
                labelText: 'Como avalia a segurança da sua casa?',
                border: OutlineInputBorder(),
              ),
              validator: HabitacaoValidator.segurancaEstrutural,
              initialValue: controller.segurancaEstrutural,
              items: SegurancaResidencia.values
                  .map((e) => DropdownMenuItem<SegurancaResidencia>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setSegurancaEstrutural(v),
            ),
            SizedBox(height: Spacing.lg),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Quais melhorias gostaria de fazer na sua moradia?',
                border: OutlineInputBorder(),
                hintText: 'Ex: Reformar banheiro, melhorar ventilação...',
              ),
              maxLines: 2,
              onChanged: controller.setMelhoriasDesejadas,
            ),
            SizedBox(height: Spacing.lg),
            SwitchListTile(
              title: const Text('Tem fácil acesso a serviços de saúde a partir da sua residência?'),
              value: controller.facilAcessoSaude,
              onChanged: controller.setFacilAcessoSaude,
            ),
          ],
        ),
      ),
    );
  }

  bool validateTab() => formKey.currentState?.validate() ?? false;
}
