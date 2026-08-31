import 'package:flutter/material.dart';

import '../../theme/styles/colors_app.dart';
import '../../theme/styles/design_tokens.dart';

/// Cabeçalho de progresso do formulário DSS (FASE 9J — refinamento visual).
///
/// Indicadores de etapa com três estados: concluída (check ✓), atual (número
/// com anel de destaque) e futura (número apagado). Uma linha conecta os
/// passos e se preenche conforme o avanço.
class StepperHeader extends StatelessWidget {
  final int currentStep;
  final List<String> stepTitles;
  const StepperHeader({super.key, required this.currentStep, required this.stepTitles});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stepTitles.length; i++) ...[
            if (i > 0) _connector(colors, i),
            _step(context, colors, i),
          ],
        ],
      ),
    );
  }

  /// Linha que liga o passo `i - 1` ao passo `i`; fica preenchida quando o
  /// passo anterior já foi concluído.
  Widget _connector(ColorsApp colors, int index) {
    final isDone = index - 1 < currentStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: isDone ? colors.primary500 : colors.primary200,
          borderRadius: RadiusTokens.smAll,
        ),
      ),
    );
  }

  Widget _step(BuildContext context, ColorsApp colors, int index) {
    final isDone = index < currentStep;
    final isCurrent = index == currentStep;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone || isCurrent ? colors.primary500 : colors.surface,
            border: Border.all(
              color: isDone || isCurrent ? colors.primary500 : colors.primary200,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? Colors.white : colors.gray500,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stepTitles[index],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
            color: isCurrent || isDone ? colors.darkText : colors.gray500,
          ),
        ),
      ],
    );
  }
}
