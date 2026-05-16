import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../core/helpers/messages.dart';
import '../../core/ui/widgets/stepper_header/stepper_header.dart';
import 'controllers/formulario_controller.dart';
import 'models/formulario_data.dart';
import 'tabs/alimentacao/alimentacao_tab.dart';
import 'tabs/educacao/educacao_tab.dart';
import 'tabs/habitacao/habitacao_tab.dart';
import 'tabs/saneamento/saneamento_tab.dart';
import 'tabs/saude/saude_tab.dart';
import 'tabs/trabalho/trabalho_tab.dart';

class FormularioPage extends StatefulWidget {
  const FormularioPage({super.key});

  @override
  State<FormularioPage> createState() => _FormularioPageState();
}

class _FormularioPageState extends State<FormularioPage> {
  late final FormularioController controller;

  static const _stepTitles = ['Educação', 'Trabalho', 'Saneamento', 'Saúde', 'Habitação', 'Alimentação'];

  @override
  void initState() {
    super.initState();
    controller = Modular.get<FormularioController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulário'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Observer(
            builder: (_) => StepperHeader(currentStep: controller.currentStep, stepTitles: _stepTitles),
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          image: DecorationImage(opacity: .05, fit: BoxFit.contain, image: AssetImage('assets/images/mother.png')),
        ),
        child: Observer(
          builder: (_) => IndexedStack(
            index: controller.currentStep,
            children: const [
              EducacaoTab(),
              TrabalhoTab(),
              SaneamentoTab(),
              SaudeTab(),
              HabitacaoTab(),
              AlimentacaoTab(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Observer(builder: (_) => _buildNavigation(controller.currentStep)),
    );
  }

  Widget _buildNavigation(int currentStep) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (currentStep > 0)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: controller.voltar,
                icon: const Icon(Icons.navigate_before),
                label: const Text('Voltar'),
              ),
            ),
          if (currentStep < 5)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleNext(currentStep),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.navigate_next),
                label: const Text('Próximo'),
              ),
            ),
          if (currentStep == 5)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleSubmit,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.check_circle),
                label: const Text('Enviar'),
              ),
            ),
        ],
      ),
    );
  }

  void _handleNext(int currentStep) {
    if (controller.isCurrentStepValid()) {
      controller.proximo();
    } else {
      Messages.showWarning('Preencha os campos obrigatórios antes de avançar.');
    }
  }

  void _handleSubmit() {
    if (controller.isCurrentStepValid()) {
      _showSummary(controller.consolidatedData);
    } else {
      Messages.showWarning('Preencha os campos obrigatórios antes de enviar.');
    }
  }

  void _showSummary(FormularioData data) {
    final summary = controller.generateSummary();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Resumo do Formulário', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: summary.length,
                itemBuilder: (_, index) {
                  final section = summary[index];
                  final categoria = section['categoria'] as String;
                  final items = Map<String, String>.from(section)..remove('categoria');

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoria,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFB8336A)),
                          ),
                          const SizedBox(height: 8),
                          ...items.entries.map((e) => _buildSummaryItem(e.key, e.value)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Messages.showSuccess('Formulário enviado com sucesso!');
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Confirmar e Enviar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, color: Colors.black, fontFamily: 'Cabin'),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value.isNotEmpty ? value : 'Não informado'),
          ],
        ),
      ),
    );
  }
}
