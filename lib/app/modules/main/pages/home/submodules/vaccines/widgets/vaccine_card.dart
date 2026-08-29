import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../widgets/base_card.dart';
import 'vaccine_info_dialog.dart';

class VaccineCard extends StatelessWidget {
  final String title;
  final String info;
  final bool used;
  final VoidCallback onChanged;

  const VaccineCard({
    super.key,
    required this.title,
    required this.info,
    required this.used,
    required this.onChanged,
  });

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
                Expanded(child: Text(title, style: context.textStyles.subTitleStyle)),
                Checkbox(
                  value: used,
                  onChanged: (value) {
                    onChanged();
                  },
                ),
                IconButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => VaccineInfoDialog(title: title, info: info),
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
}
