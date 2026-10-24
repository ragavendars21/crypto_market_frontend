// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coin_details_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoinDetailsDto _$CoinDetailsDtoFromJson(
  Map<String, dynamic> json,
) => CoinDetailsDto(
  id: json['id'] as String,
  symbol: json['symbol'] as String,
  name: json['name'] as String,
  imageUrl: json['imageUrl'] as String?,
  marketCapRank: (json['marketCapRank'] as num?)?.toInt(),
  priceUsd: (json['priceUsd'] as num?)?.toDouble(),
  marketCapUsd: (json['marketCapUsd'] as num?)?.toDouble(),
  fullyDilutedValuationUsd: (json['fullyDilutedValuationUsd'] as num?)
      ?.toDouble(),
  totalVolumeUsd: (json['totalVolumeUsd'] as num?)?.toDouble(),
  high24hUsd: (json['high24hUsd'] as num?)?.toDouble(),
  low24hUsd: (json['low24hUsd'] as num?)?.toDouble(),
  circulatingSupply: (json['circulatingSupply'] as num?)?.toDouble(),
  totalSupply: (json['totalSupply'] as num?)?.toDouble(),
  maxSupply: (json['maxSupply'] as num?)?.toDouble(),
  priceChangePercentages:
      (json['priceChangePercentages'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num?)?.toDouble()),
      ),
  allTimeHigh: json['allTimeHigh'] == null
      ? null
      : PriceExtremeDto.fromJson(json['allTimeHigh'] as Map<String, dynamic>),
  allTimeLow: json['allTimeLow'] == null
      ? null
      : PriceExtremeDto.fromJson(json['allTimeLow'] as Map<String, dynamic>),
  lastUpdated: json['lastUpdated'] == null
      ? null
      : DateTime.parse(json['lastUpdated'] as String),
);

PriceExtremeDto _$PriceExtremeDtoFromJson(Map<String, dynamic> json) =>
    PriceExtremeDto(
      priceUsd: (json['priceUsd'] as num?)?.toDouble(),
      changePercentage: (json['changePercentage'] as num?)?.toDouble(),
      date: json['date'] == null
          ? null
          : DateTime.parse(json['date'] as String),
    );
