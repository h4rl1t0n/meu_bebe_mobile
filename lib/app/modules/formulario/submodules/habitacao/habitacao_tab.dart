import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../catalog/habitacao_options.dart';
import '../../widgets/dss_question.dart';
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
                labelText: 'Tipo de moradia *',
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
            DropdownButtonFormField<MaterialMoradia>(
              decoration: const InputDecoration(
                labelText: 'Material predominante das paredes *',
                border: OutlineInputBorder(),
              ),
              validator: HabitacaoValidator.materialMoradia,
              initialValue: controller.materialMoradia,
              items: MaterialMoradia.values
                  .map((e) => DropdownMenuItem<MaterialMoradia>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setMaterialMoradia(v),
            ),
            SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Nº de pessoas', border: OutlineInputBorder()),
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
                    validator: HabitacaoValidator.numeroComodos,
                    onChanged: (v) => controller.setNumeroComodos(int.tryParse(v) ?? 0),
                  ),
                ),
                SizedBox(width: Spacing.lg),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Cômodos usados para dormir', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => HabitacaoValidator.numeroDormitorios(v, numeroComodos: controller.numeroComodos),
                    onChanged: (v) => controller.setNumeroDormitorios(int.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            SizedBox(height: Spacing.lg),
            DssMultiChoiceQuestion<ItemResidencia>(
              title: 'Quais destes itens sua casa possui?',
              options: ItemResidencia.values,
              selected: controller.itensResidencia,
              labelOf: (i) => i.label,
              onToggle: controller.toggleItemResidencia,
              required: true,
              showError: controller.showErrors,
              exclusive: ItemResidencia.nenhumDosListados,
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<SegurancaResidencia>(
              decoration: const InputDecoration(
                labelText: 'Como você avalia a segurança da sua moradia? *',
                border: OutlineInputBorder(),
              ),
              validator: HabitacaoValidator.segurancaResidencia,
              initialValue: controller.segurancaResidencia,
              items: SegurancaResidencia.values
                  .map((e) => DropdownMenuItem<SegurancaResidencia>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setSegurancaResidencia(v),
            ),
            SizedBox(height: Spacing.lg),
            DssMultiChoiceQuestion<MelhoriaMoradia>(
              title: 'Quais melhorias gostaria de fazer na sua moradia?',
              options: MelhoriaMoradia.values,
              selected: controller.melhoriasDesejadas,
              labelOf: (m) => m.label,
              onToggle: controller.toggleMelhoriaMoradia,
              required: true,
              showError: controller.showErrors,
              exclusive: MelhoriaMoradia.semMelhorias,
            ),
            SizedBox(height: Spacing.lg),
            DssBinaryQuestion(
              title: 'Tem fácil acesso a serviços de saúde a partir da sua residência?',
              value: controller.facilAcessoSaude,
              onChanged: controller.setFacilAcessoSaude,
              required: true,
              showError: controller.showErrors,
            ),
          ],
        ),
      ),
    );
  }

  bool validateTab() => formKey.currentState?.validate() ?? false;
}
