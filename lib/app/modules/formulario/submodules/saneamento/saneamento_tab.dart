import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../catalog/saneamento_options.dart';
import '../../widgets/dss_question.dart';
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
          children: [
            DssQuestionCard(
              child: DssDropdownQuestion<FonteAgua>(
                title: 'Qual a principal fonte de água da sua residência?',
                value: controller.fonteAgua,
                options: FonteAgua.values,
                labelOf: (e) => e.label,
                onChanged: controller.setFonteAgua,
                required: true,
                validator: SaneamentoValidator.fonteAgua,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Há interrupções frequentes no fornecimento de água?',
                value: controller.interrupcoesAgua,
                onChanged: controller.setInterrupcoesAgua,
                required: true,
                showError: controller.showErrors,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssSingleChoiceQuestion<EsgotamentoSanitario>(
                title: 'Como é o esgotamento sanitário na sua residência?',
                value: controller.esgotamentoSanitario,
                options: EsgotamentoSanitario.values,
                labelOf: (e) => e.label,
                onChanged: controller.setEsgotamentoSanitario,
                required: true,
                showError: controller.showErrors,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssDropdownQuestion<FrequenciaColetaLixo>(
                title: 'Com que regularidade o lixo da sua residência é coletado pelo serviço de coleta?',
                value: controller.frequenciaColetaLixo,
                options: FrequenciaColetaLixo.values,
                labelOf: (e) => e.label,
                onChanged: controller.setFrequenciaColetaLixo,
                required: true,
                validator: SaneamentoValidator.frequenciaColetaLixo,
              ),
            ),
            if (controller.frequenciaColetaLixo != null &&
                controller.frequenciaColetaLixo != FrequenciaColetaLixo.regular) ...[
              SizedBox(height: Spacing.lg),
              DssQuestionCard(
                child: DssDropdownQuestion<DestinoLixoSemColeta>(
                  title: 'Quando o lixo não é recolhido pelo serviço de coleta, qual é a principal forma de destinação?',
                  value: controller.destinoLixoSemColeta,
                  options: DestinoLixoSemColeta.values
                      .where((e) =>
                          controller.frequenciaColetaLixo != FrequenciaColetaLixo.naoPossui ||
                          e != DestinoLixoSemColeta.aguardaProximaColeta)
                      .toList(),
                  labelOf: (e) => e.label,
                  onChanged: controller.setDestinoLixoSemColeta,
                  required: true,
                  validator: SaneamentoValidator.destinoLixoSemColeta,
                ),
              ),
            ],
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssBinaryQuestion(
                title: 'Já teve algum problema de saúde por conta da água?',
                value: controller.preocupacaoAgua,
                onChanged: controller.setPreocupacaoAgua,
                required: true,
                showError: controller.showErrors,
              ),
            ),
            SizedBox(height: Spacing.lg),
            DssQuestionCard(
              child: DssMultiChoiceQuestion<CuidadoVetor>(
                title: 'Quais cuidados você adota para evitar mosquitos/vetores?',
                options: CuidadoVetor.values,
                selected: controller.cuidadosVetores,
                labelOf: (c) => c.label,
                onToggle: controller.toggleCuidadoVetor,
                required: true,
                showError: controller.showErrors,
                exclusive: CuidadoVetor.semCuidados,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
