import 'package:flutter/material.dart';

import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../widgets/base_card.dart';
import '../../../../widgets/custom_item_tile.dart';

class MaternityCard extends StatelessWidget {
  const MaternityCard({super.key, required this.prenatalPlace, this.onEdit});

  final String? prenatalPlace;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Maternidade', style: context.textStyles.titleSmallStyle),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [CustomItemTile(flex: 1, title: 'Maternidade de referencia', content: _getData(prenatalPlace))],
          ),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Alterar'),
            ),
          ),
        ],
      ),
    );
  }

  String _getData(String? raw) {
    if (raw == null || raw.isEmpty) return 'Nao informado';
    return raw;
  }
}
