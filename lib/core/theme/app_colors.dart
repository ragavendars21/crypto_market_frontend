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
  const AppColors({
    required this.positive,
    required this.negative,
    required this.star,
    required this.chartSeries,
    required this.chartOther,
  });

  /// Price went up.
  final Color positive;

  /// Price went down.
  final Color negative;

  /// Filled watchlist star.
  final Color star;

  /// Categorical colors for charts, used in this fixed order. Each mode's
  /// set was checked with a palette validator against that mode's card
  /// color (lightness band, color-blind separation, contrast).
  final List<Color> chartSeries;

  /// Neutral color for an "Others" bucket, so it never looks like a series.
  final Color chartOther;

  static const dark = AppColors(
    positive: AppPalette.darkPositive,
    negative: AppPalette.darkNegative,
    star: Color(0xFFF5B83D),
    chartSeries: [
      Color(0xFF3987E5), // blue
      Color(0xFFD95926), // orange
      Color(0xFF199E70), // aqua
      Color(0xFFC98500), // yellow
      Color(0xFFD55181), // magenta
    ],
    chartOther: Color(0xFF6B7589), // 3.8:1 on the dark card
  );

  static const light = AppColors(
    positive: AppPalette.lightPositive,
    negative: AppPalette.lightNegative,
    star: Color(0xFFB87700),
    chartSeries: [
      Color(0xFF2A78D6), // blue
      Color(0xFFEB6834), // orange
      Color(0xFF1BAF7A), // aqua
      Color(0xFFEDA100), // yellow
      Color(0xFFE87BA4), // magenta
    ],
    chartOther: Color(0xFF858E9E), // 3.3:1 on the light card
  );

  @override
  AppColors copyWith({
    Color? positive,
    Color? negative,
    Color? star,
    List<Color>? chartSeries,
    Color? chartOther,
  }) {
    return AppColors(
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      star: star ?? this.star,
      chartSeries: chartSeries ?? this.chartSeries,
      chartOther: chartOther ?? this.chartOther,
    );
  }

  /// Used by Flutter to animate smoothly between light and dark themes.
  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      star: Color.lerp(star, other.star, t)!,
      chartSeries: [
        for (var i = 0; i < chartSeries.length; i++)
          Color.lerp(chartSeries[i], other.chartSeries[i], t)!,
      ],
      chartOther: Color.lerp(chartOther, other.chartOther, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
