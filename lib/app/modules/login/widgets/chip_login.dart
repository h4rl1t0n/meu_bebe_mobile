import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ui/theme/styles/text_styles.dart';

enum AmbienteApp { desenvolvimento, homologacao, producao }

class ChipLogin extends StatelessWidget {
  final String label;
  final IconData icon;
  final FutureOr<void> Function()? onTap;

  const ChipLogin({super.key, required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: .center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.primary.withValues(alpha: .25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Icon(icon, size: 16, color: colors.primary),
                  Text(
                    label,
                    style: context.textStyles.bodyMedium.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
