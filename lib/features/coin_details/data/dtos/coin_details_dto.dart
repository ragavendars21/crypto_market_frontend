import 'package:json_annotation/json_annotation.dart';

import '../../domain/coin_details.dart';

part 'coin_details_dto.g.dart';

@JsonSerializable(createToJson: false)
class CoinDetailsDto {
  const CoinDetailsDto({
    required this.id,
    required this.symbol,
    required this.name,
    this.imageUrl,
    this.marketCapRank,
    this.priceUsd,
    this.marketCapUsd,
    this.fullyDilutedValuationUsd,
    this.totalVolumeUsd,
    this.high24hUsd,
    this.low24hUsd,
    this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    this.priceChangePercentages,
    this.allTimeHigh,
    this.allTimeLow,
    this.lastUpdated,
  });

  factory CoinDetailsDto.fromJson(Map<String, dynamic> json) =>
      _$CoinDetailsDtoFromJson(json);

  final String id;
  final String symbol;
  final String name;
  final String? imageUrl;
  final int? marketCapRank;
  final double? priceUsd;
  final double? marketCapUsd;
  final double? fullyDilutedValuationUsd;
  final double? totalVolumeUsd;
  final double? high24hUsd;
  final double? low24hUsd;
  final double? circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;
  final Map<String, double?>? priceChangePercentages;
  final PriceExtremeDto? allTimeHigh;
  final PriceExtremeDto? allTimeLow;
  final DateTime? lastUpdated;

  CoinDetails toDomain() {
    final changes = priceChangePercentages ?? const <String, double?>{};

    return CoinDetails(
      id: id,
      symbol: symbol,
      name: name,
      imageUrl: imageUrl,
      marketCapRank: marketCapRank,
      priceUsd: priceUsd,
      marketCapUsd: marketCapUsd,
      fullyDilutedValuationUsd: fullyDilutedValuationUsd,
      totalVolumeUsd: totalVolumeUsd,
      high24hUsd: high24hUsd,
      low24hUsd: low24hUsd,
      circulatingSupply: circulatingSupply,
      totalSupply: totalSupply,
      maxSupply: maxSupply,
      priceChangePercentages: {
        for (final period in ChangePeriod.values)
          period: changes[period.apiKey],
      },
      allTimeHigh: allTimeHigh?.toDomain(),
      allTimeLow: allTimeLow?.toDomain(),
      lastUpdated: lastUpdated,
    );
  }
}

@JsonSerializable(createToJson: false)
class PriceExtremeDto {
  const PriceExtremeDto({this.priceUsd, this.changePercentage, this.date});

  factory PriceExtremeDto.fromJson(Map<String, dynamic> json) =>
      _$PriceExtremeDtoFromJson(json);

  final double? priceUsd;
  final double? changePercentage;
  final DateTime? date;

  PriceExtreme toDomain() => PriceExtreme(
    priceUsd: priceUsd,
    changePercentage: changePercentage,
    date: date,
  );
}
