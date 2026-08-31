import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../catalog/saude_options.dart';
import '../../widgets/dss_question.dart';
import '../../widgets/item_tab_page.dart';
import 'saude_controller.dart';
import 'saude_validator.dart';

class SaudeTab extends StatefulWidget {
  const SaudeTab({super.key});

  @override
  State<SaudeTab> createState() => _SaudeTabState();
}

class _SaudeTabState extends State<SaudeTab> {
  final formKey = GlobalKey<FormState>();
  final controller = Modular.get<SaudeController>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Observer(
        builder: (_) => ItemTabPage(
          children: [
            DssQuestionCard(
              child: DssDropdownQuestion<DistanciaUBS>(
                title: 'Há uma UBS próxima da sua casa?',
                value: controller.distanciaUBS,
                options: DistanciaUBS.values,
                labelOf: (e) => e.label,
                onChanged: controller.setDistanciaUBS,
                required: true,
                validator: SaudeValidator.distanciaUBS,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Já faltou a alguma consulta por dificuldade de transporte ou trabalho?',
                value: controller.faltouConsulta,
                onChanged: controller.setFaltouConsulta,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssDropdownQuestion<AcessoUBS>(
                title: 'Como você costuma chegar à UBS?',
                value: controller.acessoUBS,
                options: AcessoUBS.values,
                labelOf: (e) => e.label,
                onChanged: controller.setAcessoUBS,
                required: true,
                validator: SaudeValidator.acessoUBS,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Você possui cadastro em uma Unidade Básica de Saúde (UBS)?',
                value: controller.cadastradaUBS,
                onChanged: controller.setCadastradaUBS,
                required: true,
                showError: controller.showErrors,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssMultiChoiceQuestion<ServicoPreNatal>(
                title: 'Quais serviços de pré-natal você utiliza?',
                options: ServicoPreNatal.values,
                selected: controller.servicosPreNatal,
                labelOf: (s) => s.label,
                onToggle: controller.toggleServicoPreNatal,
                required: true,
                showError: controller.showErrors,
                exclusive: ServicoPreNatal.nenhumDosListados,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Realizou todos os exames solicitados no pré-natal?',
                value: controller.examesPreNatalCompletos,
                onChanged: controller.setExamesPreNatalCompletos,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Tomou todas as vacinas indicadas para gestantes?',
                value: controller.vacinasEmDia,
                onChanged: controller.setVacinasEmDia,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssDropdownQuestion<AvaliacaoPreNatal>(
                title: 'Como avalia o atendimento de pré-natal?',
                value: controller.avaliacaoPreNatal,
                options: AvaliacaoPreNatal.values,
                labelOf: (e) => e.label,
                onChanged: controller.setAvaliacaoPreNatal,
                required: true,
                validator: SaudeValidator.avaliacaoPreNatal,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssMultiChoiceQuestion<DificuldadeSaude>(
                title: 'Quais dificuldades você enfrenta para acessar/utilizar os serviços de saúde?',
                options: DificuldadeSaude.values,
                selected: controller.dificuldadesSaude,
                labelOf: (d) => d.label,
                onToggle: controller.toggleDificuldadeSaude,
                required: true,
                showError: controller.showErrors,
                exclusive: DificuldadeSaude.semDificuldades,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
