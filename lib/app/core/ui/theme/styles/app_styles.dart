import 'package:flutter/material.dart';

import 'colors_app.dart';
import 'design_tokens.dart';

class AppStyles {
  static AppStyles? _instance;
  AppStyles._();
  static AppStyles get instance {
    _instance ??= AppStyles._();
    return _instance!;
  }

  static final _c = ColorsApp.instance;

  // ── Cards ──

  BoxDecoration get cardDecoration => BoxDecoration(
    color: _c.surface,
    borderRadius: RadiusTokens.lgAll,
    boxShadow: [ElevationTokens.cardShadow(_c.gray900)],
  );

  BoxDecoration get cardDecorationSubtle => BoxDecoration(
    color: _c.surface,
    borderRadius: RadiusTokens.lgAll,
    boxShadow: [ElevationTokens.subtleShadow(_c.gray900)],
  );

  EdgeInsets get cardPadding => const EdgeInsets.all(Spacing.cardPadding);

  // ── Containers ──

  BoxDecoration get surfaceDecoration => BoxDecoration(color: _c.surface, borderRadius: RadiusTokens.lgAll);

  BoxDecoration get surfaceVariantDecoration =>
      BoxDecoration(color: _c.surfaceVariant, borderRadius: RadiusTokens.mdAll);

  BoxDecoration get primaryTintDecoration => BoxDecoration(color: _c.primary100, borderRadius: RadiusTokens.mdAll);

  // ── Section ──

  EdgeInsets get sectionPadding => const EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.md);

  EdgeInsets get pagePadding => const EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV);

  // ── Button styles (for use with styleFrom overrides) ──

  ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    elevation: ElevationTokens.subtle,
    backgroundColor: _c.primary500,
    foregroundColor: Colors.white,
    disabledBackgroundColor: _c.gray300,
    disabledForegroundColor: _c.gray500,
    padding: const EdgeInsets.symmetric(vertical: Spacing.md + 2, horizontal: Spacing.xxl),
    shape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll),
    minimumSize: const Size(0, Spacing.buttonHeight),
  );

  ButtonStyle get secondaryButton => OutlinedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: _c.primary500,
    side: BorderSide(color: _c.primary500),
    padding: const EdgeInsets.symmetric(vertical: Spacing.md + 2, horizontal: Spacing.xxl),
    shape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll),
    minimumSize: const Size(0, Spacing.buttonHeight),
  );

  ButtonStyle get dangerButton => ElevatedButton.styleFrom(
    elevation: ElevationTokens.subtle,
    backgroundColor: _c.error,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: Spacing.md + 2, horizontal: Spacing.xxl),
    shape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll),
    minimumSize: const Size(0, Spacing.buttonHeight),
  );

  ButtonStyle get textButton => TextButton.styleFrom(
    foregroundColor: _c.primary500,
    padding: const EdgeInsets.symmetric(vertical: Spacing.sm + 2, horizontal: Spacing.lg),
    shape: RoundedRectangleBorder(borderRadius: RadiusTokens.smAll),
  );

  // ── Form field ──

  BoxDecoration get inputDecoration => BoxDecoration(
    color: _c.surface,
    borderRadius: RadiusTokens.mdAll,
    border: Border.all(color: _c.gray300),
  );

  BoxDecoration get inputDecorationFocused => BoxDecoration(
    color: _c.surface,
    borderRadius: RadiusTokens.mdAll,
    border: Border.all(color: _c.primary500, width: 1.5),
  );
}

extension AppStylesExtension on BuildContext {
  AppStyles get appStyles => AppStyles.instance;
}
