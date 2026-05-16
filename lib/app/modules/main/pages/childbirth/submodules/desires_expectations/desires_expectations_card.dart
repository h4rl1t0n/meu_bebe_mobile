import 'package:flutter/material.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/observations.dart';
import '../../../../widgets/base_card.dart';
import '../../../../widgets/custom_item_tile.dart';

class DesiresExpectationsCard extends StatelessWidget {
  const DesiresExpectationsCard({super.key, required this.observations, this.onEdit});

  final Observations? observations;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final text = observations?.observations.isNotEmpty == true ? observations!.observations : 'Nenhum outro';

    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.favorite_border, size: 20, color: context.colors.text),
              const SizedBox(width: 8),
              Text('Outros desejos e expectativas', style: context.textStyles.titleSmallStyle),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [CustomItemTile(flex: 1, title: '', content: text)],
          ),
          const SizedBox(height: 16),
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
