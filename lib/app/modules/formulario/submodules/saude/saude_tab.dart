import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../core/ui/theme/styles/text_styles.dart';
import '../../catalog/saude_options.dart';
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
                labelText: 'Há uma UBS próxima da sua casa?',
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
            _simNao(
              'Já faltou a alguma consulta por dificuldade de transporte ou trabalho?',
              controller.faltouConsulta,
              controller.setFaltouConsulta,
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<AcessoUBS>(
              decoration: const InputDecoration(
                labelText: 'Como você costuma chegar à UBS?',
                border: OutlineInputBorder(),
              ),
              validator: SaudeValidator.acessoUBS,
              initialValue: controller.acessoUBS,
              items: AcessoUBS.values
                  .map((e) => DropdownMenuItem<AcessoUBS>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setAcessoUBS(v),
            ),
            SizedBox(height: Spacing.lg),
            SwitchListTile(
              title: const Text('Você possui cadastro em uma Unidade Básica de Saúde (UBS)?'),
              value: controller.cadastradaUBS ?? false,
              onChanged: controller.setCadastradaUBS,
            ),
            SizedBox(height: Spacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quais serviços de pré-natal você utiliza?', style: context.textStyles.subTitleSmallStyle),
                ...ServicoPreNatal.values.map(
                  (s) => CheckboxListTile(
                    title: Text(s.label),
                    value: controller.servicosPreNatal.contains(s),
                    onChanged: (_) => controller.toggleServicoPreNatal(s),
                  ),
                ),
              ],
            ),
            SizedBox(height: Spacing.lg),
            _simNao(
              'Realizou todos os exames solicitados no pré-natal?',
              controller.examesPreNatalCompletos,
              controller.setExamesPreNatalCompletos,
            ),
            _simNao(
              'Tomou todas as vacinas indicadas para gestantes?',
              controller.vacinasEmDia,
              controller.setVacinasEmDia,
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<AvaliacaoPreNatal>(
              decoration: const InputDecoration(
                labelText: 'Como avalia o atendimento de pré-natal?',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quais dificuldades você enfrenta para acessar/utilizar os serviços de saúde?',
                  style: context.textStyles.subTitleSmallStyle,
                ),
                ...DificuldadeSaude.values.map(
                  (d) => CheckboxListTile(
                    title: Text(d.label),
                    value: controller.dificuldadesSaude.contains(d),
                    onChanged: (_) => controller.toggleDificuldadeSaude(d),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pergunta de Sim/Não com três estados: `null` (ainda não respondido),
  /// `true` (Sim) e `false` (Não). Nada fica pré-selecionado.
  Widget _simNao(String title, bool? value, ValueChanged<bool?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        SizedBox(height: Spacing.sm),
        RadioGroup<bool>(
          groupValue: value,
          onChanged: onChanged,
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(title: const Text('Sim'), value: true),
              ),
              Expanded(
                child: RadioListTile<bool>(title: const Text('Não'), value: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool validateTab() => formKey.currentState?.validate() ?? false;
}
