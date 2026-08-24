import 'package:flutter/material.dart';

import '../../../core/ui/theme/styles/colors_app.dart';
import '../../../core/ui/theme/styles/design_tokens.dart';
import '../../../core/ui/theme/styles/text_styles.dart';
import '../models/risk_estimate/risk_estimate_response_model.dart';

/// Converte a probabilidade `[0, 1]` em um percentual pt-BR com 1 casa decimal.
///
/// Formatação **somente visual** — o `double` original em
/// `RiskEstimateResponseModel.result.probability` permanece intacto.
///
/// Ex.: `0.238` → `"23,8%"`, `1.0` → `"100,0%"`.
String formatProbabilityPercent(double probability) {
  final percent = probability * 100;
  final value = percent.toStringAsFixed(1);
  return '${value.replaceAll('.', ',')}%';
}

/// Abre o bottom sheet de resultado da estimativa, reutilizando o tema
/// `bottomSheetTheme` já configurado no app.
Future<void> showRiskEstimateResultSheet(
  BuildContext context,
  RiskEstimateResponseModel estimate,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => RiskEstimateResultContent(estimate: estimate),
  );
}

/// Conteúdo visual da estimativa.
///
/// Apresenta a `probability` em destaque (sem classificar, sem threshold e sem
/// variar a cor pelo valor), o rótulo semântico e o `notice` metodológico em um
/// bloco informativo sempre visível. O botão "Entendi" apenas fecha o sheet.
class RiskEstimateResultContent extends StatelessWidget {
  final RiskEstimateResponseModel estimate;

  const RiskEstimateResultContent({super.key, required this.estimate});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.sm,
        Spacing.xl,
        Spacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Estimativa de acompanhamento',
            textAlign: TextAlign.center,
            style: textStyles.headlineStyle,
          ),
          SizedBox(height: Spacing.xxl),
          Text(
            formatProbabilityPercent(estimate.result.probability),
            textAlign: TextAlign.center,
            style: textStyles.titleStyle.copyWith(
              fontSize: 48,
              color: colors.primary500,
            ),
          ),
          SizedBox(height: Spacing.sm),
          Text(
            'Probabilidade estimada de descontinuidade do acompanhamento pré-natal',
            textAlign: TextAlign.center,
            style: textStyles.subTitleSmallStyle,
          ),
          SizedBox(height: Spacing.xxl),
          _NoticeCard(notice: estimate.notice),
          SizedBox(height: Spacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final String notice;

  const _NoticeCard({required this.notice});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Container(
      padding: EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: colors.infoLight,
        borderRadius: RadiusTokens.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.info, size: 20),
          SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              notice,
              style: textStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
