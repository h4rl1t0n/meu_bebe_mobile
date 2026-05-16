import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../../model/previous_pregnancy.dart';
import '../../../../../widgets/base_card.dart';
import '../../../../../widgets/custom_item_tile.dart';

class HistoryCard extends StatelessWidget {
  const HistoryCard({super.key, required this.history, this.onEdit});

  final PreviousPregnancy? history;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 20, color: context.colors.text),
              const SizedBox(width: 8),
              Text('Minha história', style: context.textStyles.titleSmallStyle),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Gestações', content: getData(history?.pregnancyNumber.toString())),
              const SizedBox(width: 10),
              CustomItemTile(flex: 1, title: 'Partos', content: getData(history?.givenBirthNumber.toString())),
              const SizedBox(width: 10),
              CustomItemTile(flex: 1, title: 'Abortos', content: getData(history?.abortionsNumber.toString())),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [CustomItemTile(flex: 1, title: 'História das gestações anteriores', content: '')],
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

  String getData(String? raw) {
    if (raw == null || raw.contains('null')) {
      return 'Sem dados';
    } else {
      return raw;
    }
  }
}
