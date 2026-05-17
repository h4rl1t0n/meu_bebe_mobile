import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../widgets/base_card.dart';

class CardWithDate extends StatelessWidget {
  const CardWithDate({
    super.key,
    required this.title,
    required this.date,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String date;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Deseja excluir?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Não')),
                  TextButton(
                    onPressed: () {
                      onTap();
                      Navigator.pop(context);
                    },
                    child: const Text('Sim'),
                  ),
                ],
              ),
            );
          },
          child: BaseCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, overflow: TextOverflow.ellipsis, style: context.textStyles.subTitleStyle),
                    Text(date, style: context.textStyles.textStyle),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(description, style: context.textStyles.textStyle),
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
