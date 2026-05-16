import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

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
          title: 'Educação',
          children: [
            SwitchListTile(
              title: const Text('Está estudando atualmente?'),
              value: controller.estuda,
              onChanged: controller.setEstuda,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Qual seu grau de escolaridade?',
                border: OutlineInputBorder(),
                hintText: 'Ex: Ensino Médio Completo',
              ),
              validator: EducacaoValidator.escolaridade,
              onChanged: controller.setEscolaridade,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Já teve que interromper os estudos por causa da gestação?'),
              value: controller.interrompeuEstudos,
              onChanged: controller.setInterrompeuEstudos,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Que dificuldades enfrenta no acesso à educação?',
                border: OutlineInputBorder(),
                hintText: 'Ex: Distância, custos, falta de vagas...',
              ),
              maxLines: 3,
              onChanged: controller.setDificuldadesEscolares,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Você consegue entender bem as orientações dos profissionais de saúde?'),
              value: controller.entendeOrientacoes,
              onChanged: controller.setEntendeOrientacoes,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Faz ou fez algum curso extracurricular?',
                border: OutlineInputBorder(),
                hintText: 'Ex: Idiomas, informática, cursos profissionalizantes...',
              ),
              onChanged: controller.setCursosExtracurriculares,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Quais são suas expectativas/projetos educacionais?',
                border: OutlineInputBorder(),
                hintText: 'Ex: Concluir o ensino médio, entrar na faculdade...',
              ),
              maxLines: 3,
              onChanged: controller.setExpectativasEducacionais,
            ),
          ],
        ),
      ),
    );
  }

  bool validateTab() => formKey.currentState?.validate() ?? false;
}
