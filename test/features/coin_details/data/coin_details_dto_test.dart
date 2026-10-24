import 'package:crypto_market/features/coin_details/data/dtos/coin_details_dto.dart';
import 'package:crypto_market/features/coin_details/domain/coin_details.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoinDetailsDto', () {
    test('parses supply, extremes and every change period', () {
      final details = CoinDetailsDto.fromJson({
        'id': 'bitcoin',
        'symbol': 'btc',
        'name': 'Bitcoin',
        'priceUsd': 67012.5,
        'circulatingSupply': 19712345,
        'totalSupply': 21000000,
        'maxSupply': 21000000,
        'priceChangePercentages': {
          '1h': 0.12,
          '24h': 1.85,
          '7d': -2.4,
          '14d': 3.1,
          '30d': 8.9,
          '60d': 12.3,
          '200d': 25.6,
          '1y': 98.7,
        },
        'allTimeHigh': {
          'priceUsd': 73738,
          'changePercentage': -9.1,
          'date': '2024-03-14T07:10:36.635Z',
        },
        'lastUpdated': '2026-10-23T10:14:31.000Z',
      }).toDomain();

      expect(details.maxSupply, 21000000);
      expect(details.priceChangePercentage24h, 1.85);
      expect(details.priceChangePercentages[ChangePeriod.y1], 98.7);
      expect(details.allTimeHigh?.priceUsd, 73738);
      expect(details.allTimeHigh?.date?.year, 2024);
      expect(details.allTimeLow, isNull);
      expect(details.circulatingSupplyRatio, closeTo(0.9387, 0.0001));
    });

    test('handles a coin with no supply cap and missing periods', () {
      final details = CoinDetailsDto.fromJson({
        'id': 'ethereum',
        'symbol': 'eth',
        'name': 'Ethereum',
        'circulatingSupply': 120280000,
        'maxSupply': null,
        'priceChangePercentages': {'24h': -0.92, '1y': null},
      }).toDomain();

      expect(details.maxSupply, isNull);
      // No cap means no progress bar — not a 0% or 100% guess.
      expect(details.circulatingSupplyRatio, isNull);
      // Every period is present as a key, unknown ones are null.
      expect(details.priceChangePercentages.keys, ChangePeriod.values);
      expect(details.priceChangePercentages[ChangePeriod.h24], -0.92);
      expect(details.priceChangePercentages[ChangePeriod.d7], isNull);
      expect(details.priceChangePercentages[ChangePeriod.y1], isNull);
    });

    test('tolerates a missing priceChangePercentages object', () {
      final details = CoinDetailsDto.fromJson({
        'id': 'x',
        'symbol': 'x',
        'name': 'X',
      }).toDomain();

      expect(details.priceChangePercentages.values, everyElement(isNull));
    });
  });
}
