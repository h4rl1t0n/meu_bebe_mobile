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
            SwitchListTile(
              title: const Text(
                textAlign: TextAlign.justify,
                'Já faltou a alguma consulta por dificuldade de transporte ou trabalho?',
              ),
              value: controller.faltouConsulta,
              onChanged: controller.setFaltouConsulta,
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<AcessoUBS>(
              decoration: const InputDecoration(
                labelText: 'Como você costuma chegar à UBS?',
                border: OutlineInputBorder(),
              ),
              validator: SaudeValidator.acessibilidadeUBS,
              initialValue: controller.acessibilidadeUBS,
              items: AcessoUBS.values
                  .map((e) => DropdownMenuItem<AcessoUBS>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setAcessibilidadeUBS(v),
            ),
            SizedBox(height: Spacing.lg),
            if (controller.acessibilidadeUBS != null) ...[
              SwitchListTile(
                title: const Text('Está cadastrada na UBS mais próxima?'),
                value: controller.cadastradaUBS ?? false,
                onChanged: controller.setCadastradaUBS,
              ),
              SizedBox(height: Spacing.lg),
            ],
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
            SwitchListTile(
              title: const Text('Realizou todos os exames solicitados no pré-natal?'),
              value: controller.examesPreNatalCompletos,
              onChanged: controller.setExamesPreNatalCompletos,
            ),
            SwitchListTile(
              title: const Text('Tomou todas as vacinas indicadas para gestantes?'),
              subtitle: const Text('Incluindo dTpa e influenza'),
              value: controller.vacinasEmDia,
              onChanged: controller.setVacinasEmDia,
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
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Quais dificuldades enfrenta no acesso à saúde?',
                border: OutlineInputBorder(),
                hintText: 'Ex: Horários, falta de profissionais, transporte...',
              ),
              maxLines: 3,
              onChanged: controller.setDificuldadesSaude,
            ),
          ],
        ),
      ),
    );
  }

  bool validateTab() => formKey.currentState?.validate() ?? false;
}
