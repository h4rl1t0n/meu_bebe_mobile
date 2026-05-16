import 'package:flutter/material.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';

class NotificacoesPage extends StatelessWidget {
  const NotificacoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.secondary,
      appBar: AppBar(title: const Text('Notificacoes'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_outlined, size: 80, color: context.colors.darkText.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Em breve', style: context.textStyles.titleSmallStyle),
          ],
        ),
      ),
    );
  }
}
