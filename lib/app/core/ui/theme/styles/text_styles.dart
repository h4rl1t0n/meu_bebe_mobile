import 'package:flutter/material.dart';

import 'colors_app.dart';

class TextStyles {
  static TextStyles? _instance;
  TextStyles._();
  static TextStyles get instance {
    _instance ??= TextStyles._();
    return _instance!;
  }

  static final _c = ColorsApp.instance;

  // ── Display / Titles ──

  /// 32px · w900 · tight leading, for page/hero titles
  TextStyle get titleStyle => TextStyle(
    fontFamily: 'Cabin',
    color: _c.darkText,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    height: 1.15,
    letterSpacing: -0.5,
  );

  /// 24px · w900 · for section headers
  TextStyle get titleSmallStyle => TextStyle(
    fontFamily: 'Cabin',
    color: _c.darkText,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    height: 1.2,
    letterSpacing: -0.3,
  );

  /// 20px · w700 · for card titles / dialogs
  TextStyle get headlineStyle => TextStyle(
    fontFamily: 'Cabin',
    color: _c.darkText,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
  );

  // ── Subtitles ──

  /// 18px · w600 · for subtitles / list tiles
  TextStyle get subTitleStyle => TextStyle(
    fontFamily: 'Cabin',
    color: _c.darkText,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.1,
  );

  /// 16px · w500 · for secondary headings
  TextStyle get subTitleSmallStyle => TextStyle(
    fontFamily: 'Cabin',
    color: _c.onSurfaceVariant,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  // ── Body ──

  /// 16px · w400 · default body / paragraph
  TextStyle get textStyle =>
      TextStyle(fontFamily: 'Cabin', color: _c.text, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);

  /// 14px · w400 · secondary body
  TextStyle get bodySmall =>
      TextStyle(fontFamily: 'Cabin', color: _c.text, fontSize: 14, fontWeight: FontWeight.w400, height: 1.45);

  /// 14px · w500 · emphasized body
  TextStyle get bodyMedium =>
      TextStyle(fontFamily: 'Cabin', color: _c.darkText, fontSize: 14, fontWeight: FontWeight.w500, height: 1.45);

  // ── Captions & Labels ──

  /// 12px · w400 · captions / metadata
  TextStyle get caption => TextStyle(
    fontFamily: 'Cabin',
    color: _c.onSurfaceVariant,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0.2,
  );

  /// 11px · w500 · overlines / small labels
  TextStyle get overline => TextStyle(
    fontFamily: 'Cabin',
    color: _c.onSurfaceVariant,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.8,
  );

  // ── Form ──

  /// 14px · w700 · input labels
  TextStyle get labelTextStyle =>
      TextStyle(fontFamily: 'Cabin', fontSize: 14, color: _c.text, fontWeight: FontWeight.w700, height: 1.3);

  /// 14px · w600 · floating input labels
  TextStyle get floatingLabelTextStyle =>
      TextStyle(fontFamily: 'Cabin', color: _c.darkText, fontWeight: FontWeight.w600, fontSize: 14, height: 1.2);

  /// 13px · w400 · input hint / helper
  TextStyle get hintStyle =>
      TextStyle(fontFamily: 'Cabin', color: _c.gray400, fontSize: 13, fontWeight: FontWeight.w400, height: 1.3);

  /// 12px · w500 · input error
  TextStyle get errorStyle =>
      TextStyle(fontFamily: 'Cabin', color: _c.error, fontSize: 12, fontWeight: FontWeight.w500, height: 1.25);

  // ── Buttons ──

  /// 14px · w700 · button text
  TextStyle get buttonTextStyle =>
      TextStyle(fontSize: 14, fontFamily: 'Cabin', fontWeight: FontWeight.w700, height: 1.2, letterSpacing: 0.3);

  /// 18px · w700 · large button text
  TextStyle get buttonLargeStyle =>
      TextStyle(fontSize: 18, fontFamily: 'Cabin', fontWeight: FontWeight.w700, height: 1.2, letterSpacing: 0.2);

  // ── Tab / Nav ──

  /// 12px · w600 · tab bar labels
  TextStyle get tabLabelStyle =>
      TextStyle(fontFamily: 'Cabin', fontSize: 12, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0.2);

 
}

extension TextStylesExtension on BuildContext {
  TextStyles get textStyles => TextStyles.instance;
}
