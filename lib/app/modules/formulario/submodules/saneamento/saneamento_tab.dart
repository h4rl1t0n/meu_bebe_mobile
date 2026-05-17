import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../core/ui/theme/styles/text_styles.dart';
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
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Qual a principal fonte de água da sua residência?',
                border: OutlineInputBorder(),
              ),
              validator: SaneamentoValidator.fonteAgua,
              initialValue: controller.fonteAgua.isNotEmpty ? controller.fonteAgua : null,
              items: const [
                DropdownMenuItem(value: 'Rede pública', child: Text('Rede pública')),
                DropdownMenuItem(value: 'Poço/Nascente', child: Text('Poço ou nascente')),
                DropdownMenuItem(value: 'Cisterna', child: Text('Cisterna')),
                DropdownMenuItem(value: 'Carro-pipa', child: Text('Carro-pipa')),
                DropdownMenuItem(value: 'Outra', child: Text('Outra fonte')),
              ],
              onChanged: (v) => controller.setFonteAgua(v ?? ''),
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Há interrupções frequentes no fornecimento de água?',
                border: OutlineInputBorder(),
              ),
              validator: SaneamentoValidator.interrupcoesAgua,
              initialValue: controller.interrupcoesAgua.isNotEmpty ? controller.interrupcoesAgua : null,
              items: const [
                DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                DropdownMenuItem(value: 'Não', child: Text('Não')),
              ],
              onChanged: (v) => controller.setInterrupcoesAgua(v ?? ''),
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
                RadioGroup<String>(
                  groupValue: controller.destinoEsgoto,
                  onChanged: (v) => controller.setDestinoEsgoto(v ?? ''),
                  child: Column(
                    children: const [
                      RadioListTile<String>(title: Text('Rede coletora'), value: 'Rede coletora'),
                      RadioListTile<String>(title: Text('Céu aberto/rio'), value: 'Céu aberto'),
                      RadioListTile<String>(title: Text('Fossa séptica'), value: 'Fossa séptica'),
                      RadioListTile<String>(title: Text('Outro'), value: 'Outro'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: Spacing.lg),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Como é feita a coleta de lixo na sua comunidade?',
                border: OutlineInputBorder(),
              ),
              validator: SaneamentoValidator.coletaLixo,
              initialValue: controller.coletaLixo.isNotEmpty ? controller.coletaLixo : null,
              items: const [
                DropdownMenuItem(value: 'Coleta regular', child: Text('Coleta regular')),
                DropdownMenuItem(value: 'Coleta irregular', child: Text('Coleta irregular')),
                DropdownMenuItem(value: 'Queima', child: Text('Queima do lixo')),
                DropdownMenuItem(value: 'Terreno baldio', child: Text('Joga em terreno baldio')),
                DropdownMenuItem(value: 'Outro', child: Text('Outro método')),
              ],
              onChanged: (v) => controller.setColetaLixo(v ?? ''),
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
