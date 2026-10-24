// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_history_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceHistoryDto _$PriceHistoryDtoFromJson(Map<String, dynamic> json) =>
    PriceHistoryDto(
      coinId: json['coinId'] as String,
      range: json['range'] as String,
      points: (json['points'] as List<dynamic>)
          .map((e) => PricePointDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

PricePointDto _$PricePointDtoFromJson(Map<String, dynamic> json) =>
    PricePointDto(
      timestamp: (json['timestamp'] as num).toInt(),
      priceUsd: (json['priceUsd'] as num?)?.toDouble(),
    );
