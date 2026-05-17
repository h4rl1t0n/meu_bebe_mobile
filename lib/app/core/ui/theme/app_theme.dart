import 'package:flutter/material.dart';

import 'styles/colors_app.dart';
import 'styles/design_tokens.dart';
import 'styles/text_styles.dart';

class AppTheme {
  AppTheme._();

  static final _c = ColorsApp.instance;
  static final _t = TextStyles.instance;

  // ── Shared primitives ──

  static final _colorScheme = ColorScheme.fromSeed(
    seedColor: _c.primary500,
    primary: _c.primary500,
    onPrimary: Colors.white,
    primaryContainer: _c.primary200,
    onPrimaryContainer: _c.primary800,
    secondary: _c.primary300,
    onSecondary: _c.primary800,
    surface: _c.surface,
    onSurface: _c.gray900,
    surfaceContainerHighest: _c.surfaceVariant,
    onSurfaceVariant: _c.gray700,
    outline: _c.gray300,
    outlineVariant: _c.gray200,
    error: _c.error,
    onError: Colors.white,
    errorContainer: _c.errorLight,
  );

  static final _inputBorder = OutlineInputBorder(
    borderRadius: RadiusTokens.mdAll,
    borderSide: BorderSide(color: _c.gray300),
  );

  static final _inputBorderFocused = OutlineInputBorder(
    borderRadius: RadiusTokens.mdAll,
    borderSide: BorderSide(color: _c.primary500, width: 1.5),
  );

  static final _inputBorderError = OutlineInputBorder(
    borderRadius: RadiusTokens.mdAll,
    borderSide: BorderSide(color: _c.error),
  );

  // ── ThemeData ──

  static final lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Cabin',
    colorScheme: _colorScheme,

    // Scaffold
    scaffoldBackgroundColor: _c.scaffoldBackground,

    // ── AppBar ──
    appBarTheme: AppBarTheme(
      backgroundColor: _c.surface,
      foregroundColor: _c.darkText,
      elevation: ElevationTokens.subtle,
      shadowColor: _c.gray900.withValues(alpha: 0.04),
      centerTitle: false,
      titleTextStyle: _t.titleStyle,
      iconTheme: IconThemeData(color: _c.darkText, size: 22),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 1,
    ),

    // ── Icons ──
    iconTheme: IconThemeData(color: _c.icon, size: 22),

    // ── Divider ──
    dividerTheme: DividerThemeData(color: _c.divider, thickness: 1, space: Spacing.sectionGap),

    // ── Card ──
    cardTheme: CardThemeData(
      elevation: ElevationTokens.card,
      shadowColor: _c.gray900.withValues(alpha: 0.05),
      color: _c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.lgAll),
      margin: const EdgeInsets.symmetric(vertical: Spacing.xs, horizontal: 0),
    ),

    // ── ListTile ──
    listTileTheme: ListTileThemeData(
      iconColor: _c.darkText,
      textColor: _c.darkText,
      titleTextStyle: _t.subTitleStyle,
      subtitleTextStyle: _t.textStyle,
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xs),
    ),

    // ── Dialog ──
    dialogTheme: DialogThemeData(
      elevation: ElevationTokens.dialog,
      shadowColor: _c.gray900.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.xxlAll),
      titleTextStyle: _t.headlineStyle,
      contentTextStyle: _t.bodySmall,
      insetPadding: const EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: Spacing.xxl),
    ),

    // ── SnackBar ──
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _c.gray800,
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontFamily: 'Cabin',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll),
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.lg),
    ),

    // ── Chip ──
    chipTheme: ChipThemeData(
      backgroundColor: _c.primary100,
      selectedColor: _c.primary500,
      disabledColor: _c.gray100,
      labelStyle: _t.buttonTextStyle.copyWith(color: _c.onSurface, fontSize: 13),
      secondaryLabelStyle: _t.caption,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.smAll),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
    ),

    // ── BottomSheet ──
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: ElevationTokens.dialog,
      shadowColor: _c.gray900.withValues(alpha: 0.1),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(RadiusTokens.xxl))),
    ),

    // ── FAB ──
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _c.primary500,
      foregroundColor: Colors.white,
      elevation: ElevationTokens.raised,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.lgAll),
    ),

    // ── Input Decoration ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
      labelStyle: _t.labelTextStyle,
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
        if (states.contains(WidgetState.error)) {
          return _t.floatingLabelTextStyle.copyWith(color: _c.error);
        }
        if (states.contains(WidgetState.focused)) {
          return _t.floatingLabelTextStyle;
        }
        return _t.floatingLabelTextStyle.copyWith(color: _c.gray500);
      }),
      hintStyle: _t.hintStyle,
      errorStyle: _t.errorStyle,
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorderFocused,
      errorBorder: _inputBorderError,
      focusedErrorBorder: _inputBorderError.copyWith(borderSide: BorderSide(color: _c.error, width: 1.5)),
      disabledBorder: _inputBorder.copyWith(borderSide: BorderSide(color: _c.gray200)),
    ),

    // ── Elevated Button ──
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: ElevationTokens.subtle,
        shadowColor: _c.primary500.withValues(alpha: 0.15),
        backgroundColor: _c.primary500,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _c.gray300,
        disabledForegroundColor: _c.gray500,
        padding: const EdgeInsets.symmetric(vertical: Spacing.md + 2, horizontal: Spacing.xxl),
        shape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll),
        textStyle: _t.buttonTextStyle,
        minimumSize: const Size(0, Spacing.buttonHeight),
      ),
    ),

    // ── Outlined Button ──
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: _c.primary500,
        side: BorderSide(color: _c.primary500),
        disabledForegroundColor: _c.gray400,
        padding: const EdgeInsets.symmetric(vertical: Spacing.md + 2, horizontal: Spacing.xxl),
        shape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll),
        textStyle: _t.buttonTextStyle,
        minimumSize: const Size(0, Spacing.buttonHeight),
      ),
    ),

    // ── Text Button ──
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _c.primary500,
        disabledForegroundColor: _c.gray400,
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm + 2, horizontal: Spacing.lg),
        shape: RoundedRectangleBorder(borderRadius: RadiusTokens.smAll),
        textStyle: _t.buttonTextStyle,
      ),
    ),

    // ── Progress Indicator ──
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _c.primary500,
      linearTrackColor: _c.primary100,
      circularTrackColor: _c.primary100,
      strokeCap: StrokeCap.round,
      strokeWidth: 3,
      borderRadius: BorderRadius.circular(RadiusTokens.md),
    ),

    // ── TabBar ──
    tabBarTheme: TabBarThemeData(
      labelColor: _c.primary500,
      unselectedLabelColor: _c.gray500,
      indicatorColor: _c.primary500,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: _t.tabLabelStyle,
      unselectedLabelStyle: _t.tabLabelStyle.copyWith(fontWeight: FontWeight.w500),
      tabAlignment: TabAlignment.fill,
      dividerColor: Colors.transparent,
    ),

    // ── Switch ──
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _c.primary500;
        if (states.contains(WidgetState.disabled)) return _c.gray300;
        return _c.gray400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _c.primary300;
        if (states.contains(WidgetState.disabled)) return _c.gray200;
        return _c.gray300;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.transparent;
        return _c.gray300;
      }),
    ),

    // ── Radio ──
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _c.primary500;
        if (states.contains(WidgetState.disabled)) return _c.gray300;
        return _c.gray400;
      }),
    ),

    // ── Checkbox ──
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _c.primary500;
        if (states.contains(WidgetState.disabled)) return _c.gray200;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(color: _c.gray400, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.smAll),
    ),

    // ── DropdownMenu ──
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
        labelStyle: _t.labelTextStyle,
        floatingLabelStyle: _t.floatingLabelTextStyle,
        hintStyle: _t.hintStyle,
        border: _inputBorder,
        enabledBorder: _inputBorder,
        focusedBorder: _inputBorderFocused,
        errorBorder: _inputBorderError,
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(_c.surface),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(ElevationTokens.card),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: RadiusTokens.lgAll)),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: Spacing.xs, vertical: Spacing.xs)),
      ),
    ),

    // ── ExpansionTile ──
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: _c.darkText,
      collapsedIconColor: _c.darkText,
      textColor: _c.darkText,
      collapsedTextColor: _c.darkText,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll),
      collapsedShape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll),
    ),

    // ── NavigationBar ──
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _c.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: _c.primary100,
      elevation: ElevationTokens.raised,
      shadowColor: _c.gray900.withValues(alpha: 0.06),
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _t.tabLabelStyle.copyWith(color: _c.primary500);
        }
        return _t.tabLabelStyle.copyWith(color: _c.gray500);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: _c.primary500, size: 22);
        }
        return IconThemeData(color: _c.gray500, size: 22);
      }),
    ),

    // ── BottomNavigationBar ──
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _c.surface,
      selectedItemColor: _c.primary500,
      unselectedItemColor: _c.gray500,
      type: BottomNavigationBarType.fixed,
      elevation: ElevationTokens.raised,
      selectedLabelStyle: _t.tabLabelStyle,
      unselectedLabelStyle: _t.tabLabelStyle.copyWith(fontWeight: FontWeight.w500),
    ),

    // ── Badge ──
    badgeTheme: BadgeThemeData(
      backgroundColor: _c.error,
      textColor: Colors.white,
      textStyle: _t.overline.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
    ),

    // ── Tooltip ──
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: _c.gray800, borderRadius: RadiusTokens.smAll),
      textStyle: _t.caption.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
    ),
  );

  static final darkTheme = lightTheme;
}
