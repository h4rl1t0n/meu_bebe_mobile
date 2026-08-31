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
          children: [
            DssQuestionCard(
              child: DssDropdownQuestion<TipoMoradia>(
                title: 'Tipo de moradia',
                value: controller.tipoMoradia,
                options: TipoMoradia.values,
                labelOf: (e) => e.label,
                onChanged: controller.setTipoMoradia,
                required: true,
                validator: HabitacaoValidator.tipoMoradia,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssDropdownQuestion<MaterialMoradia>(
                title: 'Material predominante das paredes',
                value: controller.materialMoradia,
                options: MaterialMoradia.values,
                labelOf: (e) => e.label,
                onChanged: controller.setMaterialMoradia,
                required: true,
                validator: HabitacaoValidator.materialMoradia,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: dssInputDecoration(context, labelText: 'Nº de pessoas na casa *'),
                    validator: HabitacaoValidator.numeroPessoas,
                    onChanged: (v) => controller.setNumeroPessoas(int.tryParse(v) ?? 0),
                  ),
                  SizedBox(height: Spacing.lg),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: dssInputDecoration(context, labelText: 'Nº de cômodos *'),
                    validator: HabitacaoValidator.numeroComodos,
                    onChanged: (v) => controller.setNumeroComodos(int.tryParse(v) ?? 0),
                  ),
                  SizedBox(height: Spacing.lg),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: dssInputDecoration(context, labelText: 'Cômodos usados para dormir *'),
                    validator: (v) =>
                        HabitacaoValidator.numeroDormitorios(v, numeroComodos: controller.numeroComodos),
                    onChanged: (v) => controller.setNumeroDormitorios(int.tryParse(v) ?? 0),
                  ),
                ],
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssMultiChoiceQuestion<ItemResidencia>(
                title: 'Quais destes itens sua casa possui?',
                options: ItemResidencia.values,
                selected: controller.itensResidencia,
                labelOf: (i) => i.label,
                onToggle: controller.toggleItemResidencia,
                required: true,
                showError: controller.showErrors,
                exclusive: ItemResidencia.nenhumDosListados,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssDropdownQuestion<SegurancaResidencia>(
                title: 'Como você avalia a segurança da sua moradia?',
                value: controller.segurancaResidencia,
                options: SegurancaResidencia.values,
                labelOf: (e) => e.label,
                onChanged: controller.setSegurancaResidencia,
                required: true,
                validator: HabitacaoValidator.segurancaResidencia,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssMultiChoiceQuestion<MelhoriaMoradia>(
                title: 'Quais melhorias gostaria de fazer na sua moradia?',
                options: MelhoriaMoradia.values,
                selected: controller.melhoriasDesejadas,
                labelOf: (m) => m.label,
                onToggle: controller.toggleMelhoriaMoradia,
                required: true,
                showError: controller.showErrors,
                exclusive: MelhoriaMoradia.semMelhorias,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Tem fácil acesso a serviços de saúde a partir da sua residência?',
                value: controller.facilAcessoSaude,
                onChanged: controller.setFacilAcessoSaude,
                required: true,
                showError: controller.showErrors,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
