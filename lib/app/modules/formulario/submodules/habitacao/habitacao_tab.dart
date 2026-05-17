import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../core/ui/theme/styles/text_styles.dart';
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
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de moradia',
                border: OutlineInputBorder(),
                hintText: 'Selecione o tipo de residência',
              ),
              validator: HabitacaoValidator.tipoMoradia,
              initialValue: controller.tipoMoradia.isNotEmpty ? controller.tipoMoradia : null,
              items: const [
                DropdownMenuItem(value: 'Casa de alvenaria', child: Text('Casa de alvenaria')),
                DropdownMenuItem(value: 'Casa de madeira', child: Text('Casa de madeira')),
                DropdownMenuItem(value: 'Apartamento', child: Text('Apartamento')),
                DropdownMenuItem(value: 'Cômodo único', child: Text('Cômodo único')),
                DropdownMenuItem(value: 'Outro', child: Text('Outro tipo')),
              ],
              onChanged: (v) => controller.setTipoMoradia(v ?? ''),
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
                CheckboxListTile(
                  title: const Text('Água encanada'),
                  value: controller.temAguaEncanada,
                  onChanged: (v) => controller.setTemAguaEncanada(v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Banheiro dentro da casa'),
                  value: controller.temBanheiro,
                  onChanged: (v) => controller.setTemBanheiro(v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Cozinha separada'),
                  value: controller.temCozinhaSeparada,
                  onChanged: (v) => controller.setTemCozinhaSeparada(v ?? false),
                ),
              ],
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Como avalia a segurança da sua casa?',
                border: OutlineInputBorder(),
              ),
              validator: HabitacaoValidator.segurancaEstrutural,
              initialValue: controller.segurancaEstrutural.isNotEmpty ? controller.segurancaEstrutural : null,
              items: const [
                DropdownMenuItem(value: 'Muito segura', child: Text('Muito segura')),
                DropdownMenuItem(value: 'Segura', child: Text('Segura')),
                DropdownMenuItem(value: 'Regular', child: Text('Regular')),
                DropdownMenuItem(value: 'Insegura', child: Text('Insegura')),
                DropdownMenuItem(value: 'Muito insegura', child: Text('Muito insegura')),
              ],
              onChanged: (v) => controller.setSegurancaEstrutural(v ?? ''),
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
