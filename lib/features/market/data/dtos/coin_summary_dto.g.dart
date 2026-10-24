// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coin_summary_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoinSummaryDto _$CoinSummaryDtoFromJson(Map<String, dynamic> json) =>
    CoinSummaryDto(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      marketCapRank: (json['marketCapRank'] as num?)?.toInt(),
      priceUsd: (json['priceUsd'] as num?)?.toDouble(),
      priceChange24hUsd: (json['priceChange24hUsd'] as num?)?.toDouble(),
      priceChangePercentage24h: (json['priceChangePercentage24h'] as num?)
          ?.toDouble(),
      marketCapUsd: (json['marketCapUsd'] as num?)?.toDouble(),
      totalVolumeUsd: (json['totalVolumeUsd'] as num?)?.toDouble(),
      circulatingSupply: (json['circulatingSupply'] as num?)?.toDouble(),
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

CoinPageMetaDto _$CoinPageMetaDtoFromJson(Map<String, dynamic> json) =>
    CoinPageMetaDto(
      source: json['source'] as String,
      page: (json['page'] as num).toInt(),
      totalItems: (json['totalItems'] as num).toInt(),
      hasNextPage: json['hasNextPage'] as bool,
    );

CoinPageResponseDto _$CoinPageResponseDtoFromJson(Map<String, dynamic> json) =>
    CoinPageResponseDto(
      data: (json['data'] as List<dynamic>)
          .map((e) => CoinSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: CoinPageMetaDto.fromJson(json['meta'] as Map<String, dynamic>),
    );
