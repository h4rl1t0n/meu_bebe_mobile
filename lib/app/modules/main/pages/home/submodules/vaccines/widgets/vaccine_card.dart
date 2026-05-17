import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../widgets/base_card.dart';
import 'vaccine_info_dialog.dart';

class VaccineCard extends StatelessWidget {
  final bool used;
  final int index;
  final VoidCallback onChanged;

  const VaccineCard({super.key, required this.used, required this.onChanged, required this.index});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BaseCard(
          child: SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Text(_getName(index), style: context.textStyles.subTitleStyle)),
                Checkbox(
                  value: used,
                  onChanged: (value) {
                    onChanged();
                  },
                ),
                IconButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => VaccineInfoDialog(index: index),
                  ),
                  icon: Icon(Icons.info, color: context.colors.darkText),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
      ],
    );
  }

  String _getName(int index) {
    switch (index) {
      case 0:
        return 'Hepatite B (HB - recombinante) (Dose 1)';
      case 1:
        return 'Hepatite B (HB - recombinante) (Dose 2)';
      case 2:
        return 'Hepatite B (HB - recombinante) (Dose 3)';
      case 3:
        return 'Difteria e Tétano (dT) (Dose 1)';
      case 4:
        return 'Difteria e Tétano (dT) (Dose 2)';
      case 5:
        return 'Difteria e Tétano (dT) (Dose 3)';
      case 6:
        return 'Vacina Difteria, Tétano, Pertussis (dTpa - acelular)';
    }
    return '';
  }
}
