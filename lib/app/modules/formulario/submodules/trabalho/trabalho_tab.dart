import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
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
          children: [
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Você está trabalhando atualmente?',
                value: controller.empregado,
                onChanged: controller.setEmpregado,
                required: true,
                showError: controller.showErrors,
              ),
            ),
            if (controller.empregado == true) ...[
              SizedBox(height: Spacing.lg),
              DssQuestionCard(
                child: DssSingleChoiceQuestion<TipoEmprego>(
                  title: 'Qual o tipo do seu emprego?',
                  value: controller.tipoEmprego,
                  options: TipoEmprego.values,
                  labelOf: (e) => e.label,
                  onChanged: controller.setTipoEmprego,
                  required: true,
                  showError: controller.showErrors,
                ),
              ),
              SizedBox(height: Spacing.lg),
              DssQuestionCard(
                child: DssBinaryQuestion(
                  title: 'Seu trabalho permite ir às consultas de pré-natal?',
                  value: controller.permitePreNatal,
                  onChanged: controller.setPermitePreNatal,
                ),
              ),
              SizedBox(height: Spacing.lg),
              DssQuestionCard(
                child: DssBinaryQuestion(
                  title: 'Seu ambiente de trabalho é seguro para gestante?',
                  instruction: 'Considerando esforço físico, produtos químicos, etc.',
                  value: controller.ambienteSeguro,
                  onChanged: controller.setAmbienteSeguro,
                ),
              ),
              SizedBox(height: Spacing.lg),
              DssQuestionCard(
                child: DssBinaryQuestion(
                  title: 'Tem pausas para descanso e alimentação adequada?',
                  value: controller.temPausas,
                  onChanged: controller.setTemPausas,
                ),
              ),
              SizedBox(height: Spacing.lg),
              DssQuestionCard(
                child: DssMultiChoiceQuestion<BeneficioTrabalho>(
                  title: 'Quais benefícios você recebe?',
                  options: BeneficioTrabalho.values,
                  selected: controller.beneficios,
                  labelOf: (b) => b.label,
                  onToggle: controller.toggleBeneficio,
                  required: true,
                  showError: controller.showErrors,
                  exclusive: BeneficioTrabalho.semBeneficios,
                ),
              ),
            ],
            if (controller.empregado == false) ...[
              SizedBox(height: Spacing.lg),
              DssQuestionCard(
                child: DssDropdownQuestion<MotivoDesemprego>(
                  title: 'Por que não está trabalhando atualmente?',
                  value: controller.motivoDesemprego,
                  options: MotivoDesemprego.values,
                  labelOf: (e) => e.label,
                  onChanged: controller.setMotivoDesemprego,
                  required: true,
                ),
              ),
            ],
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssDropdownQuestion<FaixaRenda>(
                title: 'Qual é a faixa de renda mensal familiar?',
                value: controller.faixaRenda,
                options: FaixaRenda.values,
                labelOf: (e) => e.label,
                onChanged: controller.setFaixaRenda,
                required: true,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Já solicitou ou recebe algum benefício social?',
                instruction: 'Ex: Auxílio Brasil, Bolsa Família, etc.',
                value: controller.recebeBeneficioSocial,
                onChanged: controller.setRecebeBeneficioSocial,
                required: true,
                showError: controller.showErrors,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssDropdownQuestion<ImpactoGestacaoTrabalho>(
                title: 'Como a gestação afetou sua situação de trabalho?',
                value: controller.impactoGestacaoTrabalho,
                options: ImpactoGestacaoTrabalho.values,
                labelOf: (e) => e.label,
                onChanged: controller.setImpactoGestacaoTrabalho,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
