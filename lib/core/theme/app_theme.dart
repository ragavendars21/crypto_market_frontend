import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Builds the light and dark [ThemeData] from the same design tokens, so
/// both themes always have identical shapes, spacing and typography.
abstract final class AppTheme {
  static final ThemeData dark = _build(
    const _ThemeTokens(
      brightness: Brightness.dark,
      background: AppPalette.darkBackground,
      surface: AppPalette.darkSurface,
      surfaceRaised: AppPalette.darkSurfaceRaised,
      outline: AppPalette.darkOutline,
      primary: AppPalette.darkPrimary,
      textPrimary: AppPalette.darkTextPrimary,
      textSecondary: AppPalette.darkTextSecondary,
      appColors: AppColors.dark,
    ),
  );

  static final ThemeData light = _build(
    const _ThemeTokens(
      brightness: Brightness.light,
      background: AppPalette.lightBackground,
      surface: AppPalette.lightSurface,
      surfaceRaised: AppPalette.lightSurfaceRaised,
      outline: AppPalette.lightOutline,
      primary: AppPalette.lightPrimary,
      textPrimary: AppPalette.lightTextPrimary,
      textSecondary: AppPalette.lightTextSecondary,
      appColors: AppColors.light,
    ),
  );

  static ThemeData _build(_ThemeTokens tokens) {
    final colorScheme = ColorScheme(
      brightness: tokens.brightness,
      primary: tokens.primary,
      onPrimary: Colors.white,
      secondary: tokens.primary,
      onSecondary: Colors.white,
      error: tokens.appColors.negative,
      onError: Colors.white,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      onSurfaceVariant: tokens.textSecondary,
      surfaceContainerHighest: tokens.surfaceRaised,
      outline: tokens.outline,
      outlineVariant: tokens.outline,
    );

    final textTheme = _textTheme(tokens);
    final selectedTint = tokens.primary.withValues(alpha: 0.16);

    return ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.background,
      textTheme: textTheme,
      extensions: [tokens.appColors],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: tokens.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surface,
        indicatorColor: selectedTint,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceRaised,
        selectedColor: selectedTint,
        side: BorderSide.none,
        labelStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceRaised,
        hintStyle: textTheme.bodyLarge?.copyWith(color: tokens.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(color: tokens.outline, thickness: 1),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _textTheme(_ThemeTokens tokens) {
    TextStyle style(double size, FontWeight weight, {Color? color}) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color ?? tokens.textPrimary,
        letterSpacing: 0,
      );
    }

    return TextTheme(
      displaySmall: style(32, FontWeight.w700),
      headlineSmall: style(24, FontWeight.w700),
      titleLarge: style(20, FontWeight.w600),
      titleMedium: style(16, FontWeight.w600),
      bodyLarge: style(15, FontWeight.w400),
      bodyMedium: style(14, FontWeight.w400),
      bodySmall: style(12, FontWeight.w400, color: tokens.textSecondary),
      labelLarge: style(13, FontWeight.w500),
      labelMedium: style(12, FontWeight.w500),
      labelSmall: style(11, FontWeight.w500, color: tokens.textSecondary),
    );
  }
}

/// Numbers (prices, percentages) use tabular figures so every digit has the
/// same width and values don't shift sideways when they update.
extension TabularFigures on TextStyle {
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

class _ThemeTokens {
  const _ThemeTokens({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.outline,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.appColors,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color outline;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final AppColors appColors;
}
