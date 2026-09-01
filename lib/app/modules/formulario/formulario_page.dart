import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../app_module.dart';
import '../../core/constants/images.dart';
import '../../core/helpers/messages.dart';
import '../../core/ui/theme/styles/colors_app.dart';
import '../../core/ui/theme/styles/design_tokens.dart';
import '../../core/ui/theme/styles/text_styles.dart';
import '../../enum/page_status.dart';
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

  static const _dimensions = [
    (icon: Icons.school_outlined, title: 'Educação'),
    (icon: Icons.work_outline, title: 'Trabalho'),
    (icon: Icons.water_drop_outlined, title: 'Saneamento'),
    (icon: Icons.health_and_safety_outlined, title: 'Saúde'),
    (icon: Icons.home_outlined, title: 'Habitação'),
    (icon: Icons.restaurant_outlined, title: 'Alimentação'),
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
        elevation: 0,
        centerTitle: true,
        title: Text('Questionário'),
        // leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _handleBack),
      ),
      body: Column(
        children: [
          Observer(builder: (_) => _buildHeader(controller.currentStep)),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(opacity: .03, fit: BoxFit.contain, image: AssetImage(Images.mother)),
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
          ),
        ],
      ),
      bottomNavigationBar: Observer(builder: (_) => _buildActionButton(controller.currentStep)),
    );
  }

  Widget _buildHeader(int step) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final dimension = _dimensions[step];

    return Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(Spacing.pageH, Spacing.md, Spacing.pageH, Spacing.md / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'DETERMINANTES SOCIAIS DE SAÚDE',
                style: textStyles.overline.copyWith(
                  color: colors.primary500,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 5,
                  children: [
                    Icon(dimension.icon, size: 27.5, color: colors.primary500),
                    Text(dimension.title, style: textStyles.titleSmallStyle.copyWith(color: colors.onSurface)),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.xs),
              _stepBadge(step),
            ],
          ),
          const SizedBox(height: Spacing.md),
          _segmentedProgress(step),
          const SizedBox(height: Spacing.sm),
          Text('A seguir: ${_nextTitle(step)}', style: textStyles.caption.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _stepBadge(int step) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      decoration: BoxDecoration(color: colors.primary50, borderRadius: RadiusTokens.smAll),
      child: Text(
        '${step + 1} de ${_dimensions.length}',
        style: textStyles.caption.copyWith(color: colors.primary600, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Barra de progresso em 6 segmentos: o segmento atual em primary, os
  /// pendentes em cinza.
  Widget _segmentedProgress(int step) {
    final colors = context.colors;
    return Row(
      children: List.generate(_dimensions.length, (i) {
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i < _dimensions.length - 1 ? Spacing.xs : 0),
            decoration: BoxDecoration(
              color: i <= step ? colors.primary500 : colors.gray300,
              borderRadius: RadiusTokens.smAll,
            ),
          ),
        );
      }),
    );
  }

  String _nextTitle(int step) {
    if (step >= _dimensions.length - 1) return 'Enviar avaliação';
    return _dimensions[step + 1].title;
  }

  /// Barra inferior de ação (FASE 9J-PRE-FIX1 — correção).
  ///
  /// Etapa 1: somente "Próximo". Etapas 2–5: "Voltar" (ação secundária,
  /// OutlinedButton) + "Próximo" (primária). Etapa 6: "Voltar" + "Enviar
  /// avaliação". A seta superior do AppBar NÃO substitui o "Voltar" inferior —
  /// aquela navega a rota; este volta à etapa anterior do questionário.
  Widget _buildActionButton(int step) {
    final isFirst = step == 0;
    final isLast = step == _dimensions.length - 1;
    return BottomAppBar(
      color: Colors.white,
      child: Row(
        children: [
          if (!isFirst) ...[Expanded(child: _backButton()), const SizedBox(width: Spacing.md)],
          Expanded(child: _forwardButton(step, isLast)),
        ],
      ),
    );
  }

  /// Botão secundário "← Voltar": retorna à etapa anterior do questionário.
  Widget _backButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, foregroundColor: Colors.grey.shade700),
      onPressed: controller.voltar,
      iconAlignment: IconAlignment.start,
      icon: const Icon(Icons.arrow_back),
      label: const Text('Voltar'),
    );
  }

  /// Botão primário "Próximo →" / "Enviar avaliação →".
  Widget _forwardButton(int step, bool isLast) {
    return ElevatedButton.icon(
      onPressed: isLast ? _handleSubmit : () => _handleNext(step),
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.arrow_forward),
      label: Text(isLast ? 'Enviar avaliação' : 'Próximo'),
    );
  }

  /// Seta superior do AppBar: navegação da PÁGINA/ROTA (não volta a etapa).
  ///
  /// FASE 9J-PRE-FIX1 (correção): a seta NÃO substitui o botão "Voltar"
  /// inferior — quem volta à etapa anterior do questionário é o "Voltar"
  /// inferior (`controller.voltar()`), enquanto esta seta apenas desempilha a
  /// rota atual.
  // void _handleBack() {
  //   Modular.to.pop();
  // }

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
                  Text('Resumo do Formulário', style: context.textStyles.titleSmallStyle),
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
                    margin: EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoria,
                            style: context.textStyles.subTitleStyle.copyWith(color: context.colors.primary500),
                          ),
                          SizedBox(height: Spacing.sm),
                          ...items.entries.map((e) => _buildSummaryItem(e.key, e.value)),
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
                                  await showRiskEstimateResultSheet(context, estimate);
                                }
                                if (mounted) {
                                  _afterResultSheet();
                                }
                              } else {
                                _surfacePersistenceFeedback();
                                Messages.showError(controller.error ?? 'Não foi possível enviar o formulário.');
                              }
                            },
                      icon: controller.loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check_circle),
                      label: Text(controller.loading ? 'Enviando...' : 'Confirmar e Enviar'),
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
      Messages.showWarning('Não foi possível salvar suas respostas. A estimativa não foi afetada.');
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
          style: context.textStyles.textStyle.copyWith(color: context.colors.onSurface),
          children: [
            TextSpan(text: '$label: ', style: context.textStyles.buttonTextStyle),
            TextSpan(text: value.isNotEmpty ? value : 'Não informado'),
          ],
        ),
      ),
    );
  }
}
