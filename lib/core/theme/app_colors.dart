import 'package:flutter/material.dart';

abstract final class AppPalette {
  static const darkBackground = Color(0xFF0B0F17);
  static const darkSurface = Color(0xFF131A26);
  static const darkSurfaceRaised = Color(0xFF1B2433);
  static const darkOutline = Color(0xFF263042);
  static const darkPrimary = Color(0xFF5B8CFF);
  static const darkPositive = Color(0xFF16C784);
  static const darkNegative = Color(0xFFEA3943);
  static const darkTextPrimary = Color(0xFFE7ECF5);
  static const darkTextSecondary = Color(0xFF8A96AD);

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

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.positive,
    required this.negative,
    required this.star,
    required this.chartSeries,
    required this.chartOther,
  });

  final Color positive;

  final Color negative;

  final Color star;

  final List<Color> chartSeries;

  final Color chartOther;

  static const dark = AppColors(
    positive: AppPalette.darkPositive,
    negative: AppPalette.darkNegative,
    star: Color(0xFFF5B83D),
    chartSeries: [
      Color(0xFF3987E5),
      Color(0xFFD95926),
      Color(0xFF199E70),
      Color(0xFFC98500),
      Color(0xFFD55181),
    ],
    chartOther: Color(0xFF6B7589),
  );

  static const light = AppColors(
    positive: AppPalette.lightPositive,
    negative: AppPalette.lightNegative,
    star: Color(0xFFB87700),
    chartSeries: [
      Color(0xFF2A78D6),
      Color(0xFFEB6834),
      Color(0xFF1BAF7A),
      Color(0xFFEDA100),
      Color(0xFFE87BA4),
    ],
    chartOther: Color(0xFF858E9E),
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
