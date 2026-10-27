import 'dart:math' as math;

enum ChartRange {
  day('1d', '1D'),
  week('7d', '7D'),
  month('30d', '30D'),
  year('1y', '1Y');

  const ChartRange(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ChartRange fromApiValue(String value) {
    return ChartRange.values.firstWhere(
      (range) => range.apiValue == value,
      orElse: () => throw FormatException('Unknown chart range: $value'),
    );
  }
}

class PricePoint {
  const PricePoint({required this.time, required this.priceUsd});

  final DateTime time;
  final double priceUsd;
}

class PriceHistory {
  const PriceHistory({required this.range, required this.points});

  static const int minimumPoints = 2;

  final ChartRange range;
  final List<PricePoint> points;

  bool get hasEnoughData => points.length >= minimumPoints;

  double? get changePercentage {
    if (!hasEnoughData) return null;
    final first = points.first.priceUsd;
    if (first == 0) return null;
    return (points.last.priceUsd - first) / first * 100;
  }

  bool get isUp => (changePercentage ?? 0) >= 0;

  double? get lowestPrice =>
      points.isEmpty ? null : points.map((p) => p.priceUsd).reduce(math.min);

  double? get highestPrice =>
      points.isEmpty ? null : points.map((p) => p.priceUsd).reduce(math.max);
}
