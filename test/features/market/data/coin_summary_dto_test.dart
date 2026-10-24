import 'package:crypto_market/features/market/data/dtos/coin_summary_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoinSummaryDto', () {
    test('parses a complete coin from the API contract', () {
      final coin = CoinSummaryDto.fromJson({
        'id': 'bitcoin',
        'symbol': 'btc',
        'name': 'Bitcoin',
        'imageUrl': 'https://example.com/btc.png',
        'marketCapRank': 1,
        'priceUsd': 67012.5,
        'priceChange24hUsd': 1217.4,
        'priceChangePercentage24h': 1.85,
        'marketCapUsd': 1321000000000,
        'totalVolumeUsd': 31200000000,
        'circulatingSupply': 19712345,
        'lastUpdated': '2026-10-23T10:14:31.000Z',
      }).toDomain();

      expect(coin.id, 'bitcoin');
      expect(coin.displaySymbol, 'BTC');
      expect(coin.marketCapRank, 1);
      expect(coin.priceUsd, 67012.5);
      expect(coin.priceChangePercentage24h, 1.85);
      expect(coin.lastUpdated, DateTime.utc(2026, 10, 23, 10, 14, 31));
    });

    test('accepts whole numbers for decimal fields', () {
      // JSON has one number type; 1321000000000 must still become a double.
      final coin = CoinSummaryDto.fromJson({
        'id': 'x',
        'symbol': 'x',
        'name': 'X',
        'marketCapUsd': 1321000000000,
        'priceUsd': 2,
      }).toDomain();

      expect(coin.marketCapUsd, 1321000000000.0);
      expect(coin.priceUsd, 2.0);
    });

    test('keeps null and missing market values as null, never zero', () {
      final coin = CoinSummaryDto.fromJson({
        'id': 'new-coin',
        'symbol': 'new',
        'name': 'New Coin',
        'priceUsd': null,
        'marketCapUsd': null,
        // circulatingSupply, rank, imageUrl and others are absent entirely.
      }).toDomain();

      expect(coin.priceUsd, isNull);
      expect(coin.marketCapUsd, isNull);
      expect(coin.circulatingSupply, isNull);
      expect(coin.marketCapRank, isNull);
      expect(coin.imageUrl, isNull);
      expect(coin.lastUpdated, isNull);
    });

    test('throws when a required field is missing', () {
      expect(
        () => CoinSummaryDto.fromJson({'symbol': 'btc', 'name': 'Bitcoin'}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('CoinPageResponseDto', () {
    Map<String, Object?> response({required String source}) => {
      'data': [
        {'id': 'bitcoin', 'symbol': 'btc', 'name': 'Bitcoin'},
        {'id': 'ethereum', 'symbol': 'eth', 'name': 'Ethereum'},
      ],
      'meta': {
        'source': source,
        'cachedAt': '2026-10-23T10:15:00.000Z',
        'page': 2,
        'perPage': 2,
        'totalItems': 14,
        'totalPages': 7,
        'hasNextPage': true,
        'universeSize': 250,
      },
    };

    test('maps coins and pagination', () {
      final page = CoinPageResponseDto.fromJson(response(source: 'live'))
          .toDomain();

      expect(page.coins.map((c) => c.id), ['bitcoin', 'ethereum']);
      expect(page.page, 2);
      expect(page.totalItems, 14);
      expect(page.hasNextPage, isTrue);
      expect(page.isStale, isFalse);
    });

    test('flags stale data served from the backend cache', () {
      final page = CoinPageResponseDto.fromJson(response(source: 'stale'))
          .toDomain();

      expect(page.isStale, isTrue);
    });
  });
}
