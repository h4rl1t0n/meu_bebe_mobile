import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../app_module.dart';
import '../../core/constants/images.dart';
import '../../core/helpers/messages.dart';
import '../../enum/page_status.dart';
import '../../core/ui/theme/styles/colors_app.dart';
import '../../core/ui/theme/styles/design_tokens.dart';
import '../../core/ui/theme/styles/text_styles.dart';
import '../../core/ui/widgets/stepper_header/stepper_header.dart';
import '../onboarding/onboarding_resolver.dart';
import '../onboarding/onboarding_route_args.dart';
import 'controllers/formulario_controller.dart';
import 'models/formulario_data.dart';
import 'submodules/alimentacao/alimentacao_tab.dart';
import 'submodules/educacao/educacao_tab.dart';
import 'submodules/habitacao/habitacao_tab.dart';
import 'submodules/saneamento/saneamento_tab.dart';
import 'submodules/saude/saude_tab.dart';
import 'submodules/trabalho/trabalho_tab.dart';
import 'widgets/risk_estimate_result_sheet.dart';

class FormularioPage extends StatefulWidget {
  const FormularioPage({super.key});

  @override
  State<FormularioPage> createState() => _FormularioPageState();
}

class _FormularioPageState extends State<FormularioPage> {
  late final FormularioController controller;

  static const _stepTitles = [
    'Educação',
    'Trabalho',
    'Saneamento',
    'Saúde',
    'Habitação',
    'Alimentação',
  ];

  @override
  void initState() {
    super.initState();
    controller = Modular.get<FormularioController>();
    // Nova avaliação nunca pré-preenche (FASE 9G): os controllers são
    // singletons e podem carregar a resposta anterior.
    controller.resetForNewAvaliacao();
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
            builder: (_) => StepperHeader(
              currentStep: controller.currentStep,
              stepTitles: _stepTitles,
            ),
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          image: DecorationImage(
            opacity: .05,
            fit: BoxFit.contain,
            image: AssetImage(Images.mother),
          ),
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
      bottomNavigationBar: Observer(
        builder: (_) => _buildNavigation(controller.currentStep),
      ),
    );
  }

  Widget _buildNavigation(int currentStep) {
    return BottomAppBar(
      // FASE 9G-FIX3 (visual): Voltar secundário (outlined), Próximo/Enviar
      // primário (elevated), com espaçamento claro entre os botões e padding
      // que os afasta das bordas do BottomAppBar.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
        child: Row(
          children: [
            if (currentStep > 0) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.voltar,
                  icon: const Icon(Icons.navigate_before),
                  label: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: Spacing.md),
            ],
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
      ),
    );
  }

  void _handleNext(int currentStep) {
    if (controller.isCurrentStepValid()) {
      controller.clearStepErrors(currentStep);
      controller.proximo();
    } else {
      controller.markStepErrors(currentStep);
      Messages.showWarning('Preencha os campos obrigatórios antes de avançar.');
    }
  }

  void _handleSubmit() {
    // FASE 9G-FIX2 (item 13/14): o "Enviar" valida TODAS as dimensões; se
    // qualquer uma estiver inválida, salta até o primeiro passo com erro,
    // marca os erros e NÃO dispara HTTP.
    if (controller.validateAll()) {
      _showSummary(controller.consolidatedData);
    } else {
      controller.markAllErrors();
      controller.goToStep(controller.firstInvalidStep ?? 0);
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
              padding: EdgeInsets.all(Spacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Resumo do Formulário',
                    style: context.textStyles.titleSmallStyle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
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
                  final items = Map<String, String>.from(section)
                    ..remove('categoria');

                  return Card(
                    margin: EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.xs,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoria,
                            style: context.textStyles.subTitleStyle.copyWith(
                              color: context.colors.primary500,
                            ),
                          ),
                          SizedBox(height: Spacing.sm),
                          ...items.entries.map(
                            (e) => _buildSummaryItem(e.key, e.value),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(Spacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: Observer(
                  builder: (_) {
                    return ElevatedButton.icon(
                      onPressed: controller.loading
                          ? null
                          : () async {
                              await controller.enviarFormulario();
                              if (!ctx.mounted) return;
                              if (controller.status == PageStatus.success) {
                                final estimate = controller.riskEstimate;
                                Navigator.pop(ctx);
                                _surfacePersistenceFeedback();
                                if (estimate != null && mounted) {
                                  await showRiskEstimateResultSheet(
                                    context,
                                    estimate,
                                  );
                                }
                                if (mounted) {
                                  _afterResultSheet();
                                }
                              } else {
                                _surfacePersistenceFeedback();
                                Messages.showError(
                                  controller.error ??
                                      'Não foi possível enviar o formulário.',
                                );
                              }
                            },
                      icon: controller.loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(
                        controller.loading
                            ? 'Enviando...'
                            : 'Confirmar e Enviar',
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Superfície do estado de persistência operacional (FASE 9F), independente
  /// do resultado da estimativa. Lê os campos PLAIN do controller (não
  /// reativos) após `await enviarFormulario()`.
  void _surfacePersistenceFeedback() {
    if (controller.noActiveGestacao) {
      Messages.showInfo(
        'Nenhuma gestação ativa foi encontrada. Suas respostas não foram '
        'salvas, mas você ainda pode visualizar a estimativa.',
      );
    } else if (controller.persistenceError != null) {
      Messages.showWarning(
        'Não foi possível salvar suas respostas. A estimativa não foi afetada.',
      );
    } else if (controller.persisted) {
      Messages.showSuccess('Respostas salvas com sucesso.');
    }
  }

  /// Navegação pós-resultado (FASE 9G), após o fechamento do sheet "Entendi".
  ///
  /// Onboarding (primeiro DSS): libera o Main SOMENTE se a persistência
  /// operacional sucedeu (`persisted`). Persistência falha NÃO libera o Main —
  /// permanece no formulário para nova tentativa. Reavaliação (modo normal):
  /// apenas volta para a área DSS (Perfil).
  void _afterResultSheet() {
    if (isOnboardingRoute()) {
      if (controller.persisted) {
        // Primeiro DSS persistido: invalida a resolução em cache para que o
        // guard da Main re-consulte o backend e libere a tab.
        Modular.get<OnboardingResolver>().invalidate();
        Modular.to.pushReplacementNamed(routeTab);
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          style: context.textStyles.textStyle.copyWith(
            color: context.colors.onSurface,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: context.textStyles.buttonTextStyle,
            ),
            TextSpan(text: value.isNotEmpty ? value : 'Não informado'),
          ],
        ),
      ),
    );
  }
}
