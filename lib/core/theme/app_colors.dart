import 'package:flutter/material.dart';

/// Raw color values for both themes.
///
/// Widgets should not use these directly. They read colors from the theme
/// (`Theme.of(context).colorScheme` or [AppColors]) so light and dark mode
/// both work automatically.
abstract final class AppPalette {
  // Dark theme
  static const darkBackground = Color(0xFF0B0F17);
  static const darkSurface = Color(0xFF131A26);
  static const darkSurfaceRaised = Color(0xFF1B2433);
  static const darkOutline = Color(0xFF263042);
  static const darkPrimary = Color(0xFF5B8CFF);
  static const darkPositive = Color(0xFF16C784);
  static const darkNegative = Color(0xFFEA3943);
  static const darkTextPrimary = Color(0xFFE7ECF5);
  static const darkTextSecondary = Color(0xFF8A96AD);

  // Light theme
  static const lightBackground = Color(0xFFF6F7FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceRaised = Color(0xFFEEF1F7);
  static const lightOutline = Color(0xFFDDE2EC);
  static const lightPrimary = Color(0xFF3A6BF0);
  static const lightPositive = Color(0xFF0FA36B);
  static const lightNegative = Color(0xFFD92D3A);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF5B6578);
}

/// Colors that Material's [ColorScheme] has no role for, such as price
/// up/down. Registered on [ThemeData.extensions] and read with
/// `context.appColors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.positive, required this.negative});

  /// Price went up.
  final Color positive;

  /// Price went down.
  final Color negative;

  static const dark = AppColors(
    positive: AppPalette.darkPositive,
    negative: AppPalette.darkNegative,
  );

  static const light = AppColors(
    positive: AppPalette.lightPositive,
    negative: AppPalette.lightNegative,
  );

  @override
  AppColors copyWith({Color? positive, Color? negative}) {
    return AppColors(
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
    );
  }

  /// Used by Flutter to animate smoothly between light and dark themes.
  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
