import 'package:flutter/material.dart';

/// Design tokens de spacing, radius e elevation.
/// Uso: `Spacing.md`, `Radius.lg`, `Elevation.card`.
abstract final class Spacing {
  Spacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double pageH = 16;
  static const double pageV = 20;
  static const double cardPadding = 16;
  static const double sectionGap = 16;
  static const double formFieldGap = 14;
  static const double buttonHeight = 50;
}

abstract final class RadiusTokens {
  RadiusTokens._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
}

abstract final class ElevationTokens {
  ElevationTokens._();

  static const double none = 0;
  static const double subtle = 2;
  static const double card = 4;
  static const double raised = 6;
  static const double dialog = 12;

  static BoxShadow subtleShadow(Color color) => BoxShadow(
        color: color.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      );

  static BoxShadow cardShadow(Color color) => BoxShadow(
        color: color.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      );

  static BoxShadow raisedShadow(Color color) => BoxShadow(
        color: color.withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
      );

  static BoxShadow dialogShadow(Color color) => BoxShadow(
        color: color.withValues(alpha: 0.12),
        blurRadius: 32,
        offset: const Offset(0, 12),
      );
}
