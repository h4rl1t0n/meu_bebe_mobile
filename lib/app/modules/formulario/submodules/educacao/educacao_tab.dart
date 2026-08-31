import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../catalog/educacao_options.dart';
import '../../widgets/dss_question.dart';
import '../../widgets/item_tab_page.dart';
import 'educacao_controller.dart';
import 'educacao_validator.dart';

class EducacaoTab extends StatefulWidget {
  const EducacaoTab({super.key});

  @override
  State<EducacaoTab> createState() => _EducacaoTabState();
}

class _EducacaoTabState extends State<EducacaoTab> {
  final formKey = GlobalKey<FormState>();
  final controller = Modular.get<EducacaoController>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Observer(
        builder: (_) => ItemTabPage(
          children: [
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Está estudando atualmente?',
                value: controller.estuda,
                onChanged: controller.setEstuda,
                required: true,
                showError: controller.showErrors,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssDropdownQuestion<Escolaridade>(
                title: 'Qual seu grau de escolaridade?',
                value: controller.escolaridade,
                options: Escolaridade.values,
                labelOf: (e) => e.label,
                onChanged: controller.setEscolaridade,
                required: true,
                validator: EducacaoValidator.escolaridade,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssSingleChoiceQuestion<SituacaoEstudosGestacao>(
                title: 'Qual situação melhor descreve seus estudos durante esta gestação?',
                value: controller.situacaoEstudosGestacao,
                options: SituacaoEstudosGestacao.values,
                labelOf: (e) => e.label,
                onChanged: controller.setSituacaoEstudosGestacao,
                required: true,
                showError: controller.showErrors,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssMultiChoiceQuestion<DificuldadeEducacao>(
                title: 'Que dificuldades enfrenta no acesso à educação?',
                options: DificuldadeEducacao.values,
                selected: controller.dificuldadesEscolares,
                labelOf: (d) => d.label,
                onToggle: controller.toggleDificuldade,
                required: true,
                showError: controller.showErrors,
                exclusive: DificuldadeEducacao.semDificuldades,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Você consegue entender bem as orientações dos profissionais de saúde?',
                value: controller.entendeOrientacoes,
                onChanged: controller.setEntendeOrientacoes,
                required: true,
                showError: controller.showErrors,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Faz ou fez algum curso profissionalizante ou de qualificação?',
                value: controller.fezCursoQualificacaoProfissional,
                onChanged: controller.setFezCursoQualificacaoProfissional,
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
