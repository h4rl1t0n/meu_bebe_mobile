import 'package:flutter/material.dart';

import '../../../core/ui/theme/styles/colors_app.dart';
import '../../../core/ui/theme/styles/design_tokens.dart';
import '../../../core/ui/theme/styles/text_styles.dart';

class CustomItemTile extends StatelessWidget {
  const CustomItemTile({super.key, required this.flex, required this.title, required this.content});

  final int flex;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Flexible(
      fit: FlexFit.tight,
      flex: flex,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textStyles.bodyMedium),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 40),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.all(Spacing.xs),
            decoration: BoxDecoration(color: colors.secondary, borderRadius: RadiusTokens.mdAll),
            child: Text(content, style: textStyles.bodyMedium, softWrap: true),
          ),
        ],
      ),
    );
  }
}
