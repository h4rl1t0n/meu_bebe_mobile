import 'package:flutter/material.dart';

class ColorsApp {
  static ColorsApp? _instance;

  ColorsApp._();

  static ColorsApp get instance {
    _instance ??= ColorsApp._();
    return _instance!;
  }

  // ── Primary Scale (Rose) ──
  Color get primary50 => const Color(0xFFFFF1F5);
  Color get primary100 => const Color(0xFFFFE0E9);
  Color get primary200 => const Color(0xFFFFC2D1);
  Color get primary300 => const Color(0xFFFF99B3);
  Color get primary400 => const Color(0xFFE75480);
  Color get primary500 => const Color(0xFFB8336A);
  Color get primary600 => const Color(0xFF9C1F55);
  Color get primary700 => const Color(0xFF7A1444);
  Color get primary800 => const Color(0xFF5C0D33);
  Color get primary900 => const Color(0xFF3D0821);

  // ── Semantic aliases ──
  Color get primary => primary50;
  Color get secondary => primary100;
  Color get text => primary400;
  Color get darkText => primary500;
  Color get icon => primary500;
  Color get divider => primary200;

  // ── Surfaces ──
  Color get surface => Colors.white;
  Color get surfaceVariant => const Color(0xFFFAFAFA);
  Color get scaffoldBackground => primary50;

  // ── Neutral Gray Scale ──
  Color get gray50 => const Color(0xFFF8F9FA);
  Color get gray100 => const Color(0xFFF1F3F5);
  Color get gray200 => const Color(0xFFE9ECEF);
  Color get gray300 => const Color(0xFFDEE2E6);
  Color get gray400 => const Color(0xFFCED4DA);
  Color get gray500 => const Color(0xFFADB5BD);
  Color get gray600 => const Color(0xFF6C757D);
  Color get gray700 => const Color(0xFF495057);
  Color get gray800 => const Color(0xFF343A40);
  Color get gray900 => const Color(0xFF212529);

  // ── Semantic Colors ──
  Color get success => const Color(0xFF2E7D32);
  Color get successLight => const Color(0xFFE8F5E9);
  Color get warning => const Color(0xFFE65100);
  Color get warningLight => const Color(0xFFFFF3E0);
  Color get error => const Color(0xFFC62828);
  Color get errorLight => const Color(0xFFFFEBEE);
  Color get info => const Color(0xFF1565C0);
  Color get infoLight => const Color(0xFFE3F2FD);

  // ── On-colors ──
  Color get onPrimary => primary900;
  Color get onSecondary => primary800;
  Color get onDarkText => Colors.white;
  Color get onSurface => gray900;
  Color get onSurfaceVariant => gray700;
}

extension ColorsAppExtensions on BuildContext {
  ColorsApp get colors => ColorsApp.instance;
}
