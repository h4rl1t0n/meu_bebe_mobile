import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../widgets/base_card.dart';
import '../../../../../widgets/custom_item_tile.dart';

/// Card "Minha história" do resumo. Recebe os contadores do histórico já
/// vindos da API. `null` (não informado) difere de `0` (zero ocorrências).
class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.pregnancyNumber,
    required this.givenBirthNumber,
    required this.abortionsNumber,
    this.onEdit,
  });

  final int? pregnancyNumber;
  final int? givenBirthNumber;
  final int? abortionsNumber;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 20, color: context.colors.text),
              const SizedBox(width: Spacing.sm),
              Text('Minha história', style: context.textStyles.titleSmallStyle),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Gestações', content: _getCount(pregnancyNumber)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Partos', content: _getCount(givenBirthNumber)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Abortos', content: _getCount(abortionsNumber)),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'História das gestações anteriores', content: _getHistorySummary()),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Editar'),
            ),
          ),
        ],
      ),
    );
  }

  String _getCount(int? value) => value == null ? 'Sem dados' : '$value';

  /// Compõe o resumo "História das gestações anteriores" a partir dos três
  /// contadores reais do histórico (FASE 8E). Todos nulos → "Não informado".
  String _getHistorySummary() {
    final parts = <String>[
      if (pregnancyNumber != null)
        '$pregnancyNumber ${_plural(pregnancyNumber!, 'gestação', 'gestações')}',
      if (givenBirthNumber != null)
        '$givenBirthNumber ${_plural(givenBirthNumber!, 'parto', 'partos')}',
      if (abortionsNumber != null)
        '$abortionsNumber ${_plural(abortionsNumber!, 'aborto', 'abortos')}',
    ];
    return parts.isEmpty ? 'Não informado' : parts.join(', ');
  }

  String _plural(int n, String singular, String plural) =>
      n == 1 ? singular : plural;
}
