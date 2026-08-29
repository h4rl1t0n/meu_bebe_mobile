import 'package:flutter/material.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/plano_parto/plano_parto_model.dart';
import '../../../../widgets/base_card.dart';
import '../../../../widgets/custom_item_tile.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';

class DesiresExpectationsCard extends StatelessWidget {
  const DesiresExpectationsCard({super.key, required this.plano, this.onEdit});

  final PlanoPartoModel? plano;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final obs = plano?.observacoes ?? '';
    final text = obs.isNotEmpty ? obs : 'Nenhum outro';

    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.favorite_border, size: 20, color: context.colors.text),
              const SizedBox(width: Spacing.sm),
              Text('Outros desejos e expectativas', style: context.textStyles.titleSmallStyle),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [CustomItemTile(flex: 1, title: '', content: text)],
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
}
