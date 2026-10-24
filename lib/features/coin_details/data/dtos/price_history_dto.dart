import 'package:json_annotation/json_annotation.dart';

import '../../domain/price_history.dart';

part 'price_history_dto.g.dart';

/// JSON shape of `GET /api/v1/coins/:coinId/market-chart` → `data`.
@JsonSerializable(createToJson: false)
class PriceHistoryDto {
  const PriceHistoryDto({
    required this.coinId,
    required this.range,
    required this.points,
  });

  factory PriceHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$PriceHistoryDtoFromJson(json);

  final String coinId;
  final String range;
  final List<PricePointDto> points;

  /// Drops points without a price (never interpolates them) and sorts the
  /// rest oldest-first, so the chart can trust the order.
  PriceHistory toDomain() {
    final validPoints = <PricePoint>[
      for (final point in points)
        if (point.priceUsd case final price? when price.isFinite)
          PricePoint(
            time: DateTime.fromMillisecondsSinceEpoch(
              point.timestamp,
              isUtc: true,
            ),
            priceUsd: price,
          ),
    ]..sort((a, b) => a.time.compareTo(b.time));

    return PriceHistory(
      range: ChartRange.fromApiValue(range),
      points: validPoints,
    );
  }
}

@JsonSerializable(createToJson: false)
class PricePointDto {
  const PricePointDto({required this.timestamp, this.priceUsd});

  factory PricePointDto.fromJson(Map<String, dynamic> json) =>
      _$PricePointDtoFromJson(json);

  /// Milliseconds since the Unix epoch (UTC).
  final int timestamp;
  final double? priceUsd;
}
