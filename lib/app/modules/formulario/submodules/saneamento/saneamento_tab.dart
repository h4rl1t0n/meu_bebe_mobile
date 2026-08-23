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
            SwitchListTile(
              title: const Text('Há interrupções frequentes no fornecimento de água?'),
              value: controller.interrupcoesAgua,
              onChanged: controller.setInterrupcoesAgua,
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
                  groupValue: controller.destinoEsgoto,
                  onChanged: (v) => controller.setDestinoEsgoto(v),
                  child: Column(
                    children: EsgotamentoSanitario.values
                        .map((e) => RadioListTile<EsgotamentoSanitario>(title: Text(e.label), value: e))
                        .toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<ColetaLixo>(
              decoration: const InputDecoration(
                labelText: 'Como é feita a coleta de lixo na sua comunidade?',
                border: OutlineInputBorder(),
              ),
              validator: SaneamentoValidator.coletaLixo,
              initialValue: controller.coletaLixo,
              items: ColetaLixo.values
                  .map((e) => DropdownMenuItem<ColetaLixo>(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => controller.setColetaLixo(v),
            ),
            SizedBox(height: Spacing.lg),
            SwitchListTile(
              title: const Text(textAlign: TextAlign.justify, 'Já teve algum problema de saúde por conta da água?'),
              value: controller.preocupacaoAgua,
              onChanged: controller.setPreocupacaoAgua,
            ),
            SizedBox(height: Spacing.lg),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Quais cuidados toma contra mosquitos/doenças?',
                border: OutlineInputBorder(),
                hintText: 'Ex: Telas, repelente, eliminação de criadouros...',
              ),
              maxLines: 2,
              onChanged: controller.setCuidadosVetores,
            ),
          ],
        ),
      ),
    );
  }

  bool validateTab() => formKey.currentState?.validate() ?? false;
}
