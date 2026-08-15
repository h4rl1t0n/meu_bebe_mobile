import 'package:flutter/material.dart';

import '../../../core/extensions/size_extension.dart';
import '../../../core/ui/theme/styles/colors_app.dart';
import '../../../core/ui/theme/styles/design_tokens.dart';
import '../../../core/ui/theme/styles/text_styles.dart';

class ItemTileWithList extends StatelessWidget {
  const ItemTileWithList({super.key, required this.title, required this.list});

  final String title;
  final List<String> list;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textStyles.bodyMedium),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              if (index < list.length) {
                return Container(
                  width: (context.screenWidth - 70) / 2,
                  margin: index == list.length - 1 ? null : EdgeInsets.only(right: Spacing.sm),
                  padding: EdgeInsets.symmetric(horizontal: Spacing.xs),
                  decoration: BoxDecoration(color: colors.secondary, borderRadius: RadiusTokens.mdAll),
                  child: Center(
                    child: Text(list[index], style: textStyles.textStyle, overflow: TextOverflow.ellipsis),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
