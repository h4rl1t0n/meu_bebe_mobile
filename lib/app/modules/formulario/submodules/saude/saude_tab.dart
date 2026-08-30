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
          title: 'Saúde',
          children: [
            DropdownButtonFormField<DistanciaUBS>(
              decoration: const InputDecoration(
                labelText: 'Há uma UBS próxima da sua casa? *',
                border: OutlineInputBorder(),
              ),
              validator: SaudeValidator.distanciaUBS,
              initialValue: controller.distanciaUBS,
              items: DistanciaUBS.values
                  .map((e) => DropdownMenuItem<DistanciaUBS>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setDistanciaUBS(v),
            ),
            SizedBox(height: Spacing.lg),
            DssBinaryQuestion(
              title: 'Já faltou a alguma consulta por dificuldade de transporte ou trabalho?',
              value: controller.faltouConsulta,
              onChanged: controller.setFaltouConsulta,
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<AcessoUBS>(
              decoration: const InputDecoration(
                labelText: 'Como você costuma chegar à UBS? *',
                border: OutlineInputBorder(),
              ),
              validator: SaudeValidator.acessoUBS,
              initialValue: controller.acessoUBS,
              items: AcessoUBS.values.map((e) => DropdownMenuItem<AcessoUBS>(value: e, child: Text(e.label))).toList(),
              onChanged: (v) => controller.setAcessoUBS(v),
            ),
            SizedBox(height: Spacing.lg),
            DssBinaryQuestion(
              title: 'Você possui cadastro em uma Unidade Básica de Saúde (UBS)?',
              value: controller.cadastradaUBS,
              onChanged: controller.setCadastradaUBS,
              required: true,
              showError: controller.showErrors,
            ),
            SizedBox(height: Spacing.lg),
            DssMultiChoiceQuestion<ServicoPreNatal>(
              title: 'Quais serviços de pré-natal você utiliza?',
              options: ServicoPreNatal.values,
              selected: controller.servicosPreNatal,
              labelOf: (s) => s.label,
              onToggle: controller.toggleServicoPreNatal,
              required: true,
              showError: controller.showErrors,
              exclusive: ServicoPreNatal.nenhumDosListados,
            ),
            SizedBox(height: Spacing.lg),
            DssBinaryQuestion(
              title: 'Realizou todos os exames solicitados no pré-natal?',
              value: controller.examesPreNatalCompletos,
              onChanged: controller.setExamesPreNatalCompletos,
            ),
            DssBinaryQuestion(
              title: 'Tomou todas as vacinas indicadas para gestantes?',
              value: controller.vacinasEmDia,
              onChanged: controller.setVacinasEmDia,
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<AvaliacaoPreNatal>(
              decoration: const InputDecoration(
                labelText: 'Como avalia o atendimento de pré-natal? *',
                border: OutlineInputBorder(),
              ),
              validator: SaudeValidator.avaliacaoPreNatal,
              initialValue: controller.avaliacaoPreNatal,
              items: AvaliacaoPreNatal.values
                  .map((e) => DropdownMenuItem<AvaliacaoPreNatal>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setAvaliacaoPreNatal(v),
            ),
            SizedBox(height: Spacing.lg),
            DssMultiChoiceQuestion<DificuldadeSaude>(
              title: 'Quais dificuldades você enfrenta para acessar/utilizar os serviços de saúde?',
              options: DificuldadeSaude.values,
              selected: controller.dificuldadesSaude,
              labelOf: (d) => d.label,
              onToggle: controller.toggleDificuldadeSaude,
              required: true,
              showError: controller.showErrors,
              exclusive: DificuldadeSaude.semDificuldades,
            ),
          ],
        ),
      ),
    );
  }

  bool validateTab() => formKey.currentState?.validate() ?? false;
}
