import 'package:flutter/material.dart';

import '../../../../../../../core/extensions/size_extension.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';

class VaccineInfoDialog extends StatelessWidget {
  final String title;
  final String info;

  const VaccineInfoDialog({super.key, required this.title, required this.info});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sobre a vacina'),
      content: SizedBox(
        width: context.screenWidth,
        child: Text(info, textAlign: TextAlign.justify, style: context.textStyles.textStyle),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Voltar'))],
    );
  }
}
