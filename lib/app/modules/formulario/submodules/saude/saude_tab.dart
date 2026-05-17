import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../core/ui/theme/styles/text_styles.dart';
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
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Há uma UBS próxima da sua casa?',
                border: OutlineInputBorder(),
              ),
              validator: SaudeValidator.distanciaUBS,
              initialValue: controller.distanciaUBS.isNotEmpty ? controller.distanciaUBS : null,
              items: const [
                DropdownMenuItem(value: 'Sim, muito próxima', child: Text('Sim, muito próxima')),
                DropdownMenuItem(value: 'Sim, razoavelmente próxima', child: Text('Sim, razoavelmente próxima')),
                DropdownMenuItem(value: 'Não, é distante', child: Text('Não, é distante')),
              ],
              onChanged: (v) => controller.setDistanciaUBS(v ?? ''),
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
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Como você costuma chegar à UBS?',
                border: OutlineInputBorder(),
              ),
              validator: SaudeValidator.acessibilidadeUBS,
              initialValue: controller.acessibilidadeUBS.isNotEmpty ? controller.acessibilidadeUBS : null,
              items: const [
                DropdownMenuItem(value: 'A pé', child: Text('A pé')),
                DropdownMenuItem(value: 'Transporte público', child: Text('Transporte público')),
                DropdownMenuItem(value: 'Carro/moto', child: Text('Carro/moto')),
                DropdownMenuItem(value: 'Outro', child: Text('Outro')),
              ],
              onChanged: (v) => controller.setAcessibilidadeUBS(v ?? ''),
            ),
            SizedBox(height: Spacing.lg),
            if (controller.acessibilidadeUBS.isNotEmpty) ...[
              SwitchListTile(
                title: const Text('Está cadastrada na UBS mais próxima?'),
                value: controller.cadastradaUBS,
                onChanged: controller.setCadastradaUBS,
              ),
              SizedBox(height: Spacing.lg),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quais serviços de pré-natal você utiliza?', style: context.textStyles.subTitleSmallStyle),
                CheckboxListTile(
                  title: const Text('Consulta médica regular'),
                  value: controller.preNatalMedico,
                  onChanged: (v) => controller.setPreNatalMedico(v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Consulta com enfermeiro'),
                  value: controller.preNatalEnfermagem,
                  onChanged: (v) => controller.setPreNatalEnfermagem(v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Grupo de gestantes'),
                  value: controller.participaGrupoGestantes,
                  onChanged: (v) => controller.setParticipaGrupoGestantes(v ?? false),
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
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Como avalia o atendimento de pré-natal?',
                border: OutlineInputBorder(),
              ),
              validator: SaudeValidator.avaliacaoPreNatal,
              initialValue: controller.avaliacaoPreNatal.isNotEmpty ? controller.avaliacaoPreNatal : null,
              items: const [
                DropdownMenuItem(value: 'Excelente', child: Text('Excelente')),
                DropdownMenuItem(value: 'Bom', child: Text('Bom')),
                DropdownMenuItem(value: 'Regular', child: Text('Regular')),
                DropdownMenuItem(value: 'Ruim', child: Text('Ruim')),
                DropdownMenuItem(value: 'Péssimo', child: Text('Péssimo')),
              ],
              onChanged: (v) => controller.setAvaliacaoPreNatal(v ?? ''),
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
