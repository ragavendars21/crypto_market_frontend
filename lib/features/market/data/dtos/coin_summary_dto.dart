import 'package:json_annotation/json_annotation.dart';

import '../../domain/coin_page.dart';
import '../../domain/coin_summary.dart';

part 'coin_summary_dto.g.dart';

@JsonSerializable(createToJson: false)
class CoinSummaryDto {
  const CoinSummaryDto({
    required this.id,
    required this.symbol,
    required this.name,
    this.imageUrl,
    this.marketCapRank,
    this.priceUsd,
    this.priceChange24hUsd,
    this.priceChangePercentage24h,
    this.marketCapUsd,
    this.totalVolumeUsd,
    this.circulatingSupply,
    this.lastUpdated,
  });

  factory CoinSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$CoinSummaryDtoFromJson(json);

  final String id;
  final String symbol;
  final String name;
  final String? imageUrl;
  final int? marketCapRank;
  final double? priceUsd;
  final double? priceChange24hUsd;
  final double? priceChangePercentage24h;
  final double? marketCapUsd;
  final double? totalVolumeUsd;
  final double? circulatingSupply;
  final DateTime? lastUpdated;

  CoinSummary toDomain() {
    return CoinSummary(
      id: id,
      symbol: symbol,
      name: name,
      imageUrl: imageUrl,
      marketCapRank: marketCapRank,
      priceUsd: priceUsd,
      priceChange24hUsd: priceChange24hUsd,
      priceChangePercentage24h: priceChangePercentage24h,
      marketCapUsd: marketCapUsd,
      totalVolumeUsd: totalVolumeUsd,
      circulatingSupply: circulatingSupply,
      lastUpdated: lastUpdated,
    );
  }
}

@JsonSerializable(createToJson: false)
class CoinPageMetaDto {
  const CoinPageMetaDto({
    required this.source,
    required this.page,
    required this.totalItems,
    required this.hasNextPage,
  });

  factory CoinPageMetaDto.fromJson(Map<String, dynamic> json) =>
      _$CoinPageMetaDtoFromJson(json);

  final String source;
  final int page;
  final int totalItems;
  final bool hasNextPage;
}

@JsonSerializable(createToJson: false)
class CoinPageResponseDto {
  const CoinPageResponseDto({required this.data, required this.meta});

  factory CoinPageResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CoinPageResponseDtoFromJson(json);

  final List<CoinSummaryDto> data;
  final CoinPageMetaDto meta;

  CoinPage toDomain() {
    return CoinPage(
      coins: data.map((dto) => dto.toDomain()).toList(),
      page: meta.page,
      totalItems: meta.totalItems,
      hasNextPage: meta.hasNextPage,
      isStale: meta.source == 'stale',
    );
  }
}
