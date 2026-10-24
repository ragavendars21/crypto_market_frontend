// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_market_stats_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlobalMarketStatsDto _$GlobalMarketStatsDtoFromJson(
  Map<String, dynamic> json,
) => GlobalMarketStatsDto(
  totalMarketCapUsd: (json['totalMarketCapUsd'] as num?)?.toDouble(),
  totalVolumeUsd: (json['totalVolumeUsd'] as num?)?.toDouble(),
  marketCapChangePercentage24h: (json['marketCapChangePercentage24h'] as num?)
      ?.toDouble(),
  volumeChangePercentage24h: (json['volumeChangePercentage24h'] as num?)
      ?.toDouble(),
  activeCryptocurrencies: (json['activeCryptocurrencies'] as num?)?.toInt(),
  markets: (json['markets'] as num?)?.toInt(),
  dominance:
      (json['dominance'] as List<dynamic>?)
          ?.map((e) => DominanceEntryDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

DominanceEntryDto _$DominanceEntryDtoFromJson(Map<String, dynamic> json) =>
    DominanceEntryDto(
      symbol: json['symbol'] as String,
      percentage: (json['percentage'] as num).toDouble(),
    );
