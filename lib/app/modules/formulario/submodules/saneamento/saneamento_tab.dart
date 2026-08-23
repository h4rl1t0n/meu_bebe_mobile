import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../core/ui/theme/styles/text_styles.dart';
import '../../catalog/saneamento_options.dart';
import '../../widgets/item_tab_page.dart';
import 'saneamento_controller.dart';
import 'saneamento_validator.dart';

class SaneamentoTab extends StatefulWidget {
  const SaneamentoTab({super.key});

  @override
  State<SaneamentoTab> createState() => _SaneamentoTabState();
}

class _SaneamentoTabState extends State<SaneamentoTab> {
  final formKey = GlobalKey<FormState>();
  final controller = Modular.get<SaneamentoController>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Observer(
        builder: (_) => ItemTabPage(
          title: 'Saneamento Básico',
          children: [
            DropdownButtonFormField<FonteAgua>(
              decoration: const InputDecoration(
                labelText: 'Qual a principal fonte de água da sua residência?',
                border: OutlineInputBorder(),
              ),
              validator: SaneamentoValidator.fonteAgua,
              initialValue: controller.fonteAgua,
              items: FonteAgua.values
                  .map((e) => DropdownMenuItem<FonteAgua>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setFonteAgua(v),
            ),
            SizedBox(height: Spacing.lg),
            _simNao(
              'Há interrupções frequentes no fornecimento de água?',
              controller.interrupcoesAgua,
              controller.setInterrupcoesAgua,
            ),
            SizedBox(height: Spacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Como é o esgotamento sanitário na sua residência?',
                  style: context.textStyles.subTitleSmallStyle.copyWith(color: context.colors.onSurface),
                ),
                SizedBox(height: Spacing.sm),
                RadioGroup<EsgotamentoSanitario>(
                  groupValue: controller.esgotamentoSanitario,
                  onChanged: (v) => controller.setEsgotamentoSanitario(v),
                  child: Column(
                    children: EsgotamentoSanitario.values
                        .map((e) => RadioListTile<EsgotamentoSanitario>(title: Text(e.label), value: e))
                        .toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<FrequenciaColetaLixo>(
              decoration: const InputDecoration(
                labelText: 'Com que regularidade o lixo da sua residência é coletado pelo serviço de coleta?',
                border: OutlineInputBorder(),
              ),
              validator: SaneamentoValidator.frequenciaColetaLixo,
              initialValue: controller.frequenciaColetaLixo,
              items: FrequenciaColetaLixo.values
                  .map((e) => DropdownMenuItem<FrequenciaColetaLixo>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setFrequenciaColetaLixo(v),
            ),
            SizedBox(height: Spacing.lg),
            if (controller.frequenciaColetaLixo != null &&
                controller.frequenciaColetaLixo != FrequenciaColetaLixo.regular)
              DropdownButtonFormField<DestinoLixoSemColeta>(
                decoration: const InputDecoration(
                  labelText: 'Quando o lixo não é recolhido pelo serviço de coleta, qual é a principal forma de destinação?',
                  border: OutlineInputBorder(),
                ),
                validator: SaneamentoValidator.destinoLixoSemColeta,
                initialValue: controller.destinoLixoSemColeta,
                items: DestinoLixoSemColeta.values
                    .where((e) =>
                        controller.frequenciaColetaLixo != FrequenciaColetaLixo.naoPossui ||
                        e != DestinoLixoSemColeta.aguardaProximaColeta)
                    .map((e) => DropdownMenuItem<DestinoLixoSemColeta>(value: e, child: Text(e.label)))
                    .toList(),
                onChanged: (v) => controller.setDestinoLixoSemColeta(v),
              ),
            SizedBox(height: Spacing.lg),
            _simNao(
              'Já teve algum problema de saúde por conta da água?',
              controller.preocupacaoAgua,
              controller.setPreocupacaoAgua,
            ),
            SizedBox(height: Spacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quais cuidados você adota para evitar mosquitos/vetores?',
                  style: context.textStyles.subTitleSmallStyle.copyWith(color: context.colors.onSurface),
                ),
                ...CuidadoVetor.values.map(
                  (c) => CheckboxListTile(
                    title: Text(c.label),
                    value: controller.cuidadosVetores.contains(c),
                    onChanged: (_) => controller.toggleCuidadoVetor(c),
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
