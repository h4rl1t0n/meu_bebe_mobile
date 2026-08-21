import 'package:flutter/material.dart';

import 'styles/colors_app.dart';
import 'styles/design_tokens.dart';
import 'styles/text_styles.dart';

class AppTheme {
  AppTheme._();

  static final colors = ColorsApp.instance;
  static final textStyles = TextStyles.instance;

  static final colorsolorScheme = ColorScheme.fromSeed(
    seedColor: colors.primary500,
    primary: colors.primary500,
    onPrimary: Colors.white,
    primaryContainer: colors.primary200,
    onPrimaryContainer: colors.primary800,
    secondary: colors.primary300,
    onSecondary: colors.primary800,
    surface: colors.surface,
    onSurface: colors.gray900,
    surfaceContainerHighest: colors.surfaceVariant,
    onSurfaceVariant: colors.gray700,
    outline: colors.gray300,
    outlineVariant: colors.gray200,
    error: colors.error,
    onError: Colors.white,
    errorContainer: colors.errorLight,
  );

  static final _inputBorder = OutlineInputBorder(
    borderRadius: RadiusTokens.mdAll,
    borderSide: BorderSide(color: colors.gray300),
  );

  static final _inputBorderFocused = OutlineInputBorder(
    borderRadius: RadiusTokens.mdAll,
    borderSide: BorderSide(color: colors.primary500, width: 1.5),
  );

  static final _inputBorderError = OutlineInputBorder(
    borderRadius: RadiusTokens.mdAll,
    borderSide: BorderSide(color: colors.error),
  );

  // ── ThemeData ──

  static final lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Cabin',
    colorScheme: colorsolorScheme,

    // Scaffold
    scaffoldBackgroundColor: colors.scaffoldBackground,

    // ── AppBar ──
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.darkText,
      elevation: ElevationTokens.subtle,
      shadowColor: colors.gray900.withValues(alpha: 0.04),
      centerTitle: false,
      titleTextStyle: textStyles.titleStyle,
      iconTheme: IconThemeData(color: colors.darkText, size: 22),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 1,
    ),

    // ── Icons ──
    iconTheme: IconThemeData(color: colors.icon, size: 22),

    // ── Divider ──
    dividerTheme: DividerThemeData(color: colors.divider, thickness: 1, space: Spacing.sectionGap),

    // ── Card ──
    cardTheme: CardThemeData(
      elevation: ElevationTokens.card,
      shadowColor: colors.gray900.withValues(alpha: 0.05),
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.lgAll),
      margin: const EdgeInsets.symmetric(vertical: Spacing.xs, horizontal: 0),
    ),

    // ── ListTile ──
    listTileTheme: ListTileThemeData(
      iconColor: colors.darkText,
      textColor: colors.darkText,
      titleTextStyle: textStyles.subTitleStyle,
      subtitleTextStyle: textStyles.textStyle,
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xs),
    ),

    // ── Dialog ──
    dialogTheme: DialogThemeData(
      elevation: ElevationTokens.dialog,
      shadowColor: colors.gray900.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.xxlAll),
      titleTextStyle: textStyles.headlineStyle,
      contentTextStyle: textStyles.bodySmall,
      insetPadding: const EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: Spacing.xxl),
    ),

    // ── SnackBar ──
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.gray800,
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
      backgroundColor: colors.primary100,
      selectedColor: colors.primary500,
      disabledColor: colors.gray100,
      labelStyle: textStyles.buttonTextStyle.copyWith(color: colors.onSurface, fontSize: 13),
      secondaryLabelStyle: textStyles.caption,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.smAll),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
    ),

    // ── BottomSheet ──
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: ElevationTokens.dialog,
      shadowColor: colors.gray900.withValues(alpha: 0.1),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(RadiusTokens.xxl))),
    ),

    // ── FAB ──
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.primary500,
      foregroundColor: Colors.white,
      elevation: ElevationTokens.raised,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.lgAll),
    ),

    // ── Input Decoration ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
      labelStyle: textStyles.labelTextStyle,
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
        if (states.contains(WidgetState.error)) {
          return textStyles.floatingLabelTextStyle.copyWith(color: colors.error);
        }
        if (states.contains(WidgetState.focused)) {
          return textStyles.floatingLabelTextStyle;
        }
        return textStyles.floatingLabelTextStyle.copyWith(color: colors.gray500);
      }),
      hintStyle: textStyles.hintStyle,
      errorStyle: textStyles.errorStyle,
      border: _inputBorder,
      enabledBorder: _inputBorder,
      focusedBorder: _inputBorderFocused,
      errorBorder: _inputBorderError,
      focusedErrorBorder: _inputBorderError.copyWith(borderSide: BorderSide(color: colors.error, width: 1.5)),
      disabledBorder: _inputBorder.copyWith(borderSide: BorderSide(color: colors.gray200)),
    ),

    // ── Elevated Button ──
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: ElevationTokens.subtle,
        shadowColor: colors.primary500.withValues(alpha: 0.15),
        backgroundColor: colors.primary500,
        foregroundColor: Colors.white,
        disabledBackgroundColor: colors.gray300,
        disabledForegroundColor: colors.gray500,
        padding: const EdgeInsets.symmetric(vertical: Spacing.md + 2, horizontal: Spacing.xxl),
        shape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll),
        textStyle: textStyles.buttonTextStyle,
        minimumSize: const Size(0, Spacing.buttonHeight),
      ),
    ),

    // ── Outlined Button ──
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: colors.primary500,
        side: BorderSide(color: colors.primary500),
        disabledForegroundColor: colors.gray400,
        padding: const EdgeInsets.symmetric(vertical: Spacing.md + 2, horizontal: Spacing.xxl),
        shape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll),
        textStyle: textStyles.buttonTextStyle,
        minimumSize: const Size(0, Spacing.buttonHeight),
      ),
    ),

    // ── Text Button ──
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary500,
        disabledForegroundColor: colors.gray400,
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm + 2, horizontal: Spacing.lg),
        shape: RoundedRectangleBorder(borderRadius: RadiusTokens.smAll),
        textStyle: textStyles.buttonTextStyle,
      ),
    ),

    // ── Progress Indicator ──
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.primary500,
      linearTrackColor: colors.primary100,
      circularTrackColor: colors.primary100,
      strokeCap: StrokeCap.round,
      strokeWidth: 3,
      borderRadius: BorderRadius.circular(RadiusTokens.md),
    ),

    // ── TabBar ──
    tabBarTheme: TabBarThemeData(
      labelColor: colors.primary500,
      unselectedLabelColor: colors.gray500,
      indicatorColor: colors.primary500,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: textStyles.tabLabelStyle,
      unselectedLabelStyle: textStyles.tabLabelStyle.copyWith(fontWeight: FontWeight.w500),
      tabAlignment: TabAlignment.fill,
      dividerColor: Colors.transparent,
    ),

    // ── Switch ──
    // switchTheme: SwitchThemeData(
    //   thumbColor: WidgetStateProperty.resolveWith((states) {
    //     if (states.contains(WidgetState.selected)) {
    //       return colors.primary500;
    //     }

    //     if (states.contains(WidgetState.disabled)) {
    //       return colors.gray300;
    //     }

    //     return colors.gray500;
    //   }),

    //   trackColor: WidgetStateProperty.resolveWith((states) {
    //     if (states.contains(WidgetState.selected)) {
    //       return colors.primary200;
    //     }

    //     if (states.contains(WidgetState.disabled)) {
    //       return colors.gray200;
    //     }

    //     return colors.gray200;
    //   }),

    //   trackOutlineColor: WidgetStateProperty.resolveWith((states) {
    //     if (states.contains(WidgetState.selected)) {
    //       return Colors.transparent;
    //     }

    //     if (states.contains(WidgetState.disabled)) {
    //       return colors.gray300;
    //     }

    //     return colors.gray300;
    //   }),
    // ),

    // ── Radio ──
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colors.primary500;
        if (states.contains(WidgetState.disabled)) return colors.gray300;
        return colors.gray400;
      }),
    ),

    // ── Checkbox ──
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colors.primary500;
        if (states.contains(WidgetState.disabled)) return colors.gray200;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(color: colors.gray400, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.smAll),
    ),

    // ── DropdownMenu ──
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
        labelStyle: textStyles.labelTextStyle,
        floatingLabelStyle: textStyles.floatingLabelTextStyle,
        hintStyle: textStyles.hintStyle,
        border: _inputBorder,
        enabledBorder: _inputBorder,
        focusedBorder: _inputBorderFocused,
        errorBorder: _inputBorderError,
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(colors.surface),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(ElevationTokens.card),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: RadiusTokens.lgAll)),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: Spacing.xs, vertical: Spacing.xs)),
      ),
    ),

    // ── ExpansionTile ──
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: colors.darkText,
      collapsedIconColor: colors.darkText,
      textColor: colors.darkText,
      collapsedTextColor: colors.darkText,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll),
      collapsedShape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll),
    ),

    // ── NavigationBar ──
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colors.primary100,
      elevation: ElevationTokens.raised,
      shadowColor: colors.gray900.withValues(alpha: 0.06),
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return textStyles.tabLabelStyle.copyWith(color: colors.primary500);
        }
        return textStyles.tabLabelStyle.copyWith(color: colors.gray600);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colors.primary500, size: 22);
        }
        return IconThemeData(color: colors.gray600, size: 22);
      }),
    ),

    // ── BottomNavigationBar ──
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colors.surface,
      selectedItemColor: colors.primary500,
      unselectedItemColor: colors.gray500,
      type: BottomNavigationBarType.fixed,
      elevation: ElevationTokens.raised,
      selectedLabelStyle: textStyles.tabLabelStyle,
      unselectedLabelStyle: textStyles.tabLabelStyle.copyWith(fontWeight: FontWeight.w500),
    ),

    // ── Badge ──
    badgeTheme: BadgeThemeData(
      backgroundColor: colors.error,
      textColor: Colors.white,
      textStyle: textStyles.overline.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
    ),

    // ── Tooltip ──
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: colors.gray800, borderRadius: RadiusTokens.smAll),
      textStyle: textStyles.caption.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
    ),
  );

  static final darkTheme = lightTheme;
}
