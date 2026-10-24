import 'package:json_annotation/json_annotation.dart';

import '../../domain/global_market_stats.dart';

part 'global_market_stats_dto.g.dart';

/// JSON shape of `GET /api/v1/market/global` → `data`.
@JsonSerializable(createToJson: false)
class GlobalMarketStatsDto {
  const GlobalMarketStatsDto({
    this.totalMarketCapUsd,
    this.totalVolumeUsd,
    this.marketCapChangePercentage24h,
    this.volumeChangePercentage24h,
    this.activeCryptocurrencies,
    this.markets,
    this.dominance = const [],
    this.updatedAt,
  });

  factory GlobalMarketStatsDto.fromJson(Map<String, dynamic> json) =>
      _$GlobalMarketStatsDtoFromJson(json);

  final double? totalMarketCapUsd;
  final double? totalVolumeUsd;
  final double? marketCapChangePercentage24h;
  final double? volumeChangePercentage24h;
  final int? activeCryptocurrencies;
  final int? markets;
  final List<DominanceEntryDto> dominance;
  final DateTime? updatedAt;

  GlobalMarketStats toDomain() {
    final entries = dominance.map((dto) => dto.toDomain()).toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));

    return GlobalMarketStats(
      totalMarketCapUsd: totalMarketCapUsd,
      totalVolumeUsd: totalVolumeUsd,
      marketCapChangePercentage24h: marketCapChangePercentage24h,
      volumeChangePercentage24h: volumeChangePercentage24h,
      activeCryptocurrencies: activeCryptocurrencies,
      markets: markets,
      dominance: entries,
      updatedAt: updatedAt,
    );
  }
}

@JsonSerializable(createToJson: false)
class DominanceEntryDto {
  const DominanceEntryDto({required this.symbol, required this.percentage});

  factory DominanceEntryDto.fromJson(Map<String, dynamic> json) =>
      _$DominanceEntryDtoFromJson(json);

  final String symbol;
  final double percentage;

  DominanceEntry toDomain() =>
      DominanceEntry(symbol: symbol, percentage: percentage);
}
