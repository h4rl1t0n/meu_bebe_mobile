import 'package:flutter/material.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';

class SobreAppPage extends StatelessWidget {
  const SobreAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: context.colors.secondary,
      appBar: AppBar(title: const Text('Sobre o app'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: Spacing.xxxl),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  ElevationTokens.raisedShadow(colors.onSurface),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: context.colors.primary,
                child: const Icon(Icons.child_care, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: Spacing.xxl),
            Text('Meu Bebe', style: context.textStyles.titleSmallStyle.copyWith(fontSize: 24)),
            const SizedBox(height: Spacing.sm),
            Text('Versao 1.0.0', style: context.textStyles.subTitleStyle),
            const SizedBox(height: Spacing.xxl),
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
