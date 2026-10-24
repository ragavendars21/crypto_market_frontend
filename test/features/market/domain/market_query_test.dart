import 'package:crypto_market/features/market/domain/market_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarketQuery', () {
    test('queries that differ only by surrounding spaces are equal', () {
      // Lets the market list skip a request when the user types a space.
      expect(
        const MarketQuery(search: 'btc '),
        const MarketQuery(search: ' btc'),
      );
      expect(
        const MarketQuery(search: 'btc ').hashCode,
        const MarketQuery(search: ' btc').hashCode,
      );
    });

    test('copyWith changes only the given fields', () {
      const original = MarketQuery(search: 'sol');
      final updated = original.copyWith(sort: MarketSort.priceDesc);

      expect(updated.search, 'sol');
      expect(updated.sort, MarketSort.priceDesc);
      expect(updated, isNot(original));
    });

    test('reports active filters', () {
      expect(const MarketQuery().hasActiveFilters, isFalse);
      expect(
        const MarketQuery(tier: MarketCapTier.small).hasActiveFilters,
        isTrue,
      );
    });

    test('sort API values match the backend contract', () {
      expect(MarketSort.values.map((s) => s.apiValue), [
        'market_cap_desc',
        'market_cap_asc',
        'price_desc',
        'price_asc',
        'change_24h_desc',
        'change_24h_asc',
        'volume_desc',
        'volume_asc',
      ]);
    });
  });
}
