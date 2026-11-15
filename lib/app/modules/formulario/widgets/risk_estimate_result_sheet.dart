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
Future<void> showRiskEstimateResultSheet(BuildContext context, RiskEstimateResponseModel estimate) {
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
/// bloco informativo sempre visível. Se disponíveis, exibe também os fatores determinantes (XAI).
class RiskEstimateResultContent extends StatelessWidget {
  final RiskEstimateResponseModel estimate;

  const RiskEstimateResultContent({super.key, required this.estimate});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(Spacing.xl, Spacing.sm, Spacing.xl, Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Estimativa de acompanhamento', textAlign: TextAlign.center, style: textStyles.headlineStyle),
          SizedBox(height: Spacing.xxl),
          Text(
            formatProbabilityPercent(estimate.result.probability),
            textAlign: TextAlign.center,
            style: textStyles.titleStyle.copyWith(fontSize: 48, color: colors.primary500),
          ),
          SizedBox(height: Spacing.sm),
          Text(
            'Probabilidade estimada de descontinuidade do acompanhamento pré-natal',
            textAlign: TextAlign.center,
            style: textStyles.subTitleSmallStyle,
          ),
          if (estimate.factors != null && estimate.factors!.isNotEmpty) ...[
            SizedBox(height: Spacing.xl),
            _FactorsSection(factors: estimate.factors!),
          ],
          SizedBox(height: Spacing.xxl),
          _NoticeCard(notice: estimate.notice),
          SizedBox(height: Spacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendi')),
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
      decoration: BoxDecoration(color: colors.infoLight, borderRadius: RadiusTokens.mdAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.info, size: 20),
          SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(notice, style: textStyles.bodySmall.copyWith(color: colors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _FactorsSection extends StatelessWidget {
  final List<RiskFactorContributionModel> factors;

  const _FactorsSection({required this.factors});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: colors.primary500, size: 20),
            SizedBox(width: Spacing.xs),
            Expanded(
              child: Text(
                'Fatores determinantes (IA Explicável)',
                style: textStyles.titleSmallStyle.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SizedBox(height: Spacing.xs),
        Text(
          'Principais variáveis que influenciaram a estimativa:',
          style: textStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
        ),
        SizedBox(height: Spacing.sm),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: factors.length,
          separatorBuilder: (_, _) => SizedBox(height: Spacing.xs),
          itemBuilder: (context, index) {
            final factor = factors[index];
            final isIncrease = factor.increasesRisk;
            final badgeBg = isIncrease ? colors.warningLight : colors.successLight;
            final badgeColor = isIncrease ? colors.warning : colors.success;
            final badgeIcon = isIncrease ? Icons.trending_up : Icons.verified_user_outlined;
            final badgeLabel = isIncrease ? 'Atenção' : 'Proteção';
            final pct = (factor.contribution.abs() * 100).toStringAsFixed(1);
            final sign = isIncrease ? '+' : '-';

            return Container(
              padding: EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: RadiusTokens.mdAll,
                border: Border.all(
                  color: isIncrease ? colors.warning.withValues(alpha: 0.3) : colors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(Spacing.xs),
                    decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                    child: Icon(badgeIcon, color: badgeColor, size: 18),
                  ),
                  SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                factor.label,
                                style: textStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                '$badgeLabel ($sign$pct%)',
                                style: textStyles.bodySmall.copyWith(
                                  color: badgeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Spacing.xs / 2),
                        Text(
                          factor.description,
                          style: textStyles.bodySmall.copyWith(color: colors.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
