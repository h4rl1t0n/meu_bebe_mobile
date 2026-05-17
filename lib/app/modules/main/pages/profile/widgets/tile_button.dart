import 'package:flutter/material.dart';

import '../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../core/ui/theme/styles/colors_app.dart';

class TileButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  const TileButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.lg),
          child: Row(
            children: [
              Icon(icon, size: 25, color: iconColor ?? colors.onSurface),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor ?? colors.onSurface),
                ),
              ),
              Icon(Icons.chevron_right, color: (textColor ?? colors.onSurface).withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
