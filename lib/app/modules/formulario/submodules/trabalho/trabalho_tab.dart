import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../core/ui/theme/styles/text_styles.dart';
import '../../catalog/trabalho_options.dart';
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
            _simNao('Você está trabalhando atualmente?', controller.empregado, controller.setEmpregado),
            if (controller.empregado == true) ...[
              SizedBox(height: Spacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qual o tipo do seu emprego?',
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
              SwitchListTile(
                title: const Text('Seu trabalho permite ir às consultas de pré-natal?'),
                value: controller.permitePreNatal ?? false,
                onChanged: controller.setPermitePreNatal,
              ),
              SwitchListTile(
                title: const Text('Seu ambiente de trabalho é seguro para gestante?'),
                subtitle: const Text('Considerando esforço físico, produtos químicos, etc.'),
                value: controller.ambienteSeguro ?? false,
                onChanged: controller.setAmbienteSeguro,
              ),
              SwitchListTile(
                title: const Text('Tem pausas para descanso e alimentação adequada?'),
                value: controller.temPausas ?? false,
                onChanged: controller.setTemPausas,
              ),
              SizedBox(height: Spacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quais benefícios você recebe?', style: context.textStyles.subTitleSmallStyle),
                  ...BeneficioTrabalho.values.map(
                    (b) => CheckboxListTile(
                      title: Text(b.label),
                      value: controller.beneficios.contains(b),
                      onChanged: (_) => controller.toggleBeneficio(b),
                    ),
                  ),
                ],
              ),
            ],
            if (controller.empregado == false) ...[
              SizedBox(height: Spacing.lg),
              DropdownButtonFormField<MotivoDesemprego>(
                decoration: const InputDecoration(
                  labelText: 'Por que não está trabalhando atualmente?',
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
                labelText: 'Qual é a faixa de renda mensal familiar?',
                border: OutlineInputBorder(),
              ),
              initialValue: controller.faixaRenda,
              items: FaixaRenda.values
                  .map((e) => DropdownMenuItem<FaixaRenda>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setFaixaRenda(v),
            ),
            SizedBox(height: Spacing.lg),
            SwitchListTile(
              title: const Text('Já solicitou ou recebe algum benefício social?'),
              subtitle: const Text('Ex: Auxílio Brasil, Bolsa Família, etc.'),
              value: controller.recebeBeneficioSocial ?? false,
              onChanged: controller.setRecebeBeneficioSocial,
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
