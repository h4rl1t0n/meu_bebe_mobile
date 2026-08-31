import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../catalog/alimentacao_options.dart';
import '../../widgets/dss_question.dart';
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
          children: [
            DssQuestionCard(
              child: DssSingleChoiceQuestion<RefeicoesPorDia>(
                title: 'Quantas refeições completas você faz por dia?',
                value: controller.refeicoesPorDia,
                options: RefeicoesPorDia.values,
                labelOf: (e) => e.label,
                onChanged: controller.setRefeicoesPorDia,
                required: true,
                showError: controller.showErrors,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Nos últimos 3 meses, deixou de comer por falta de dinheiro?',
                value: controller.deixouDeComerFaltaDinheiro,
                onChanged: controller.setDeixouComerFaltaDinheiro,
                required: true,
                showError: controller.showErrors,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssMultiChoiceQuestion<AlimentoConsumido>(
                title: 'Quais alimentos você consome regularmente?',
                options: AlimentoConsumido.values,
                selected: controller.alimentosConsumidos,
                labelOf: (a) => a.label,
                onToggle: controller.toggleAlimento,
                required: true,
                showError: controller.showErrors,
                exclusive: AlimentoConsumido.nenhumDosListados,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssMultiChoiceQuestion<FonteAlimentos>(
                title: 'De onde vêm os alimentos que você consome?',
                options: FonteAlimentos.values,
                selected: controller.fonteAlimentos,
                labelOf: (f) => f.label,
                onToggle: controller.toggleFonteAlimento,
                required: true,
                showError: controller.showErrors,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Sua alimentação mudou durante a gestação?',
                value: controller.mudancaAlimentacaoGestacao,
                onChanged: controller.setMudancaAlimentacaoGestacao,
                required: true,
                showError: controller.showErrors,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Está tomando suplementos vitamínicos ou de ferro?',
                value: controller.usaSuplementos,
                onChanged: controller.setUsaSuplementos,
                required: true,
                showError: controller.showErrors,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssSingleChoiceQuestion<AvaliacaoAlimentacao>(
                title: 'Como você avalia sua alimentação durante a gestação?',
                value: controller.avaliacaoAlimentacao,
                options: AvaliacaoAlimentacao.values,
                labelOf: (e) => e.label,
                onChanged: controller.setAvaliacaoAlimentacao,
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
