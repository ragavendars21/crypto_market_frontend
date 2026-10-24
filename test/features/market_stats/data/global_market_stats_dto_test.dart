import 'package:crypto_market/features/market_stats/data/dtos/global_market_stats_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GlobalMarketStatsDto', () {
    test('parses totals and sorts dominance largest first', () {
      final stats = GlobalMarketStatsDto.fromJson({
        'totalMarketCapUsd': 2410000000000,
        'totalVolumeUsd': 98700000000,
        'marketCapChangePercentage24h': 1.42,
        'activeCryptocurrencies': 17321,
        'markets': 1287,
        'dominance': [
          {'symbol': 'eth', 'percentage': 13.2},
          {'symbol': 'btc', 'percentage': 54.8},
        ],
        'updatedAt': '2026-10-23T10:12:00.000Z',
      }).toDomain();

      expect(stats.totalMarketCapUsd, 2.41e12);
      expect(stats.volumeChangePercentage24h, isNull);
      expect(stats.dominance.map((d) => d.symbol), ['btc', 'eth']);
      expect(stats.bitcoinDominance, 54.8);
      expect(stats.othersDominance, closeTo(32.0, 0.0001));
    });

    test('handles an empty response without inventing values', () {
      final stats = GlobalMarketStatsDto.fromJson({}).toDomain();

      expect(stats.totalMarketCapUsd, isNull);
      expect(stats.dominance, isEmpty);
      expect(stats.bitcoinDominance, isNull);
      expect(stats.othersDominance, isNull);
    });
  });
}
