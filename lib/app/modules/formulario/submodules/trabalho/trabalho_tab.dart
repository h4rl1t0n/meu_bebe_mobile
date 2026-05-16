import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

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
            SwitchListTile(
              title: const Text('Você está trabalhando atualmente?'),
              value: controller.empregado,
              onChanged: controller.setEmpregado,
            ),
            if (controller.empregado) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Qual o tipo do seu emprego?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  RadioGroup<String>(
                    groupValue: controller.tipoEmprego,
                    onChanged: (v) => controller.setTipoEmprego(v ?? ''),
                    child: Column(
                      children: const [
                        RadioListTile<String>(title: Text('CLT (carteira assinada)'), value: 'CLT'),
                        RadioListTile<String>(title: Text('Autônoma'), value: 'Autônoma'),
                        RadioListTile<String>(title: Text('Informal'), value: 'Informal'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Qual sua faixa de renda mensal?',
                  border: OutlineInputBorder(),
                ),
                initialValue: controller.faixaRenda.isNotEmpty ? controller.faixaRenda : null,
                items: const [
                  DropdownMenuItem(value: 'Até 1 salário mínimo', child: Text('Até 1 salário mínimo')),
                  DropdownMenuItem(value: '1-2 salários', child: Text('1-2 salários mínimos')),
                  DropdownMenuItem(value: '2-3 salários', child: Text('2-3 salários mínimos')),
                  DropdownMenuItem(value: 'Mais de 3 salários', child: Text('Mais de 3 salários mínimos')),
                  DropdownMenuItem(value: 'Prefiro não informar', child: Text('Prefiro não informar')),
                ],
                onChanged: (v) => controller.setFaixaRenda(v ?? ''),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Seu trabalho permite ir às consultas de pré-natal?'),
                value: controller.permitePreNatal,
                onChanged: controller.setPermitePreNatal,
              ),
              SwitchListTile(
                title: const Text('Seu ambiente de trabalho é seguro para gestante?'),
                subtitle: const Text('Considerando esforço físico, produtos químicos, etc.'),
                value: controller.ambienteSeguro,
                onChanged: controller.setAmbienteSeguro,
              ),
              SwitchListTile(
                title: const Text('Tem pausas para descanso e alimentação adequada?'),
                value: controller.temPausas,
                onChanged: controller.setTemPausas,
              ),
              const SizedBox(height: 16),
              const Text('Quais benefícios você recebe?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              CheckboxListTile(
                title: const Text('Auxílio-maternidade'),
                value: controller.recebeAuxilioMaternidade,
                onChanged: (v) => controller.setRecebeAuxilioMaternidade(v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Vale-transporte'),
                value: controller.recebeValeTransporte,
                onChanged: (v) => controller.setRecebeValeTransporte(v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Vale-alimentação/refeição'),
                value: controller.recebeValeAlimentacao,
                onChanged: (v) => controller.setRecebeValeAlimentacao(v ?? false),
              ),
            ],
            if (!controller.empregado) ...[
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Por que não está trabalhando atualmente?',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Demissão, licença saúde, por causa da gravidez...',
                ),
                maxLines: 2,
                onChanged: controller.setMotivoDesemprego,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Já solicitou ou recebe algum benefício social?'),
                subtitle: const Text('Ex: Auxílio Brasil, Bolsa Família, etc.'),
                value: controller.recebeBeneficioSocial,
                onChanged: controller.setRecebeBeneficioSocial,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Como a gestação afetou sua situação de trabalho?',
                border: OutlineInputBorder(),
                hintText: 'Ex: Mudou de função, reduziu carga horária...',
              ),
              maxLines: 3,
              onChanged: controller.setImpactoGestacaoTrabalho,
            ),
          ],
        ),
      ),
    );
  }

  bool validateTab() => formKey.currentState?.validate() ?? false;
}
