import 'package:flutter/material.dart';

import '../../../../core/extensions/size_extension.dart';
import '../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../core/ui/theme/styles/design_tokens.dart';
import 'widgets/childbirth_resume_card.dart';
import 'widgets/update_childbirth_card.dart';

class ChildbirthPage extends StatelessWidget {
  const ChildbirthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: context.screenWidth,
      color: colors.secondary,
      padding: EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
      child: ListView(children: const [ChildbirthResumeCard(), SizedBox(height: Spacing.lg), UpdateChildbirthCard()]),
    );
  }
}
