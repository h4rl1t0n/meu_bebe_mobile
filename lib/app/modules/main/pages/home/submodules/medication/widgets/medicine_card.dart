import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../widgets/base_card.dart';

class MedicineCard extends StatelessWidget {
  const MedicineCard({
    super.key,
    required this.name,
    required this.dose,
    required this.frequencia,
    required this.onTap,
  });

  final String name;
  final String dose;
  final String frequencia;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;

    return Column(
      children: [
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Deseja excluir esse medicamento?'),
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
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, overflow: TextOverflow.ellipsis, style: context.textStyles.subTitleStyle),
                    Text(dose, style: textStyles.textStyle),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(frequencia, style: textStyles.textStyle),
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
