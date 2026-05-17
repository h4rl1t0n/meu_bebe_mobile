import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';

class InformationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const InformationCard({super.key, required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(Spacing.md),
            width: double.infinity,
            decoration: BoxDecoration(color: colors.surface, borderRadius: RadiusTokens.mdAll, boxShadow: [ElevationTokens.subtleShadow(Theme.of(context).colorScheme.onSurface)]),
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .center,
              spacing: Spacing.lg,
              children: [
                Icon(icon, size: 40, color: colors.darkText),
                Text(title, style: textStyles.subTitleStyle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
