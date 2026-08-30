import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../core/ui/theme/styles/text_styles.dart';
import '../../catalog/trabalho_options.dart';
import '../../widgets/dss_question.dart';
import '../../widgets/item_tab_page.dart';
import 'trabalho_controller.dart';

class TrabalhoTab extends StatefulWidget {
  const TrabalhoTab({super.key});

  @override
  State<TrabalhoTab> createState() => _TrabalhoTabState();
}

class _TrabalhoTabState extends State<TrabalhoTab> {
  final formKey = GlobalKey<FormState>();
  final controller = Modular.get<TrabalhoController>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Observer(
        builder: (_) => ItemTabPage(
          title: 'Trabalho e Renda',
          children: [
            DssBinaryQuestion(
              title: 'Você está trabalhando atualmente?',
              value: controller.empregado,
              onChanged: controller.setEmpregado,
              required: true,
              showError: controller.showErrors,
            ),
            if (controller.empregado == true) ...[
              SizedBox(height: Spacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qual o tipo do seu emprego? *',
                    style: context.textStyles.subTitleSmallStyle,
                  ),
                  RadioGroup<TipoEmprego>(
                    groupValue: controller.tipoEmprego,
                    onChanged: (v) => controller.setTipoEmprego(v),
                    child: Column(
                      children: TipoEmprego.values
                          .map((e) => RadioListTile<TipoEmprego>(title: Text(e.label), value: e))
                          .toList(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Spacing.lg),
              DssBinaryQuestion(
                title: 'Seu trabalho permite ir às consultas de pré-natal?',
                value: controller.permitePreNatal,
                onChanged: controller.setPermitePreNatal,
              ),
              DssBinaryQuestion(
                title: 'Seu ambiente de trabalho é seguro para gestante?',
                instruction: 'Considerando esforço físico, produtos químicos, etc.',
                value: controller.ambienteSeguro,
                onChanged: controller.setAmbienteSeguro,
              ),
              DssBinaryQuestion(
                title: 'Tem pausas para descanso e alimentação adequada?',
                value: controller.temPausas,
                onChanged: controller.setTemPausas,
              ),
              SizedBox(height: Spacing.lg),
              DssMultiChoiceQuestion<BeneficioTrabalho>(
                title: 'Quais benefícios você recebe?',
                options: BeneficioTrabalho.values,
                selected: controller.beneficios,
                labelOf: (b) => b.label,
                onToggle: controller.toggleBeneficio,
                required: true,
                showError: controller.showErrors,
                exclusive: BeneficioTrabalho.semBeneficios,
              ),
            ],
            if (controller.empregado == false) ...[
              SizedBox(height: Spacing.lg),
              DropdownButtonFormField<MotivoDesemprego>(
                decoration: const InputDecoration(
                  labelText: 'Por que não está trabalhando atualmente? *',
                  border: OutlineInputBorder(),
                ),
                initialValue: controller.motivoDesemprego,
                items: MotivoDesemprego.values
                    .map((e) => DropdownMenuItem<MotivoDesemprego>(value: e, child: Text(e.label)))
                    .toList(),
                onChanged: (v) => controller.setMotivoDesemprego(v),
              ),
            ],
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<FaixaRenda>(
              decoration: const InputDecoration(
                labelText: 'Qual é a faixa de renda mensal familiar? *',
                border: OutlineInputBorder(),
              ),
              initialValue: controller.faixaRenda,
              items: FaixaRenda.values
                  .map((e) => DropdownMenuItem<FaixaRenda>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setFaixaRenda(v),
            ),
            SizedBox(height: Spacing.lg),
            DssBinaryQuestion(
              title: 'Já solicitou ou recebe algum benefício social?',
              instruction: 'Ex: Auxílio Brasil, Bolsa Família, etc.',
              value: controller.recebeBeneficioSocial,
              onChanged: controller.setRecebeBeneficioSocial,
              required: true,
              showError: controller.showErrors,
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<ImpactoGestacaoTrabalho>(
              decoration: const InputDecoration(
                labelText: 'Como a gestação afetou sua situação de trabalho?',
                border: OutlineInputBorder(),
              ),
              initialValue: controller.impactoGestacaoTrabalho,
              items: ImpactoGestacaoTrabalho.values
                  .map((e) => DropdownMenuItem<ImpactoGestacaoTrabalho>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setImpactoGestacaoTrabalho(v),
            ),
          ],
        ),
      ),
    );
  }

  bool validateTab() => formKey.currentState?.validate() ?? false;
}
