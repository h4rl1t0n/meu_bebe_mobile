import 'package:flutter/material.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';

class SobreAppPage extends StatelessWidget {
  const SobreAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.secondary,
      appBar: AppBar(title: const Text('Sobre o app'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: context.colors.primary,
                child: const Icon(Icons.child_care, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Text('Meu Bebe', style: context.textStyles.titleSmallStyle.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text('Versao 1.0.0', style: context.textStyles.subTitleStyle),
            const SizedBox(height: 24),
            Text(
              'Aplicativo desenvolvido para auxiliar gestantes no acompanhamento do pre-natal, plano de parto e cuidados com o bebe.',
              textAlign: TextAlign.center,
              style: context.textStyles.subTitleStyle,
            ),
          ],
        ),
      ),
    );
  }
}
