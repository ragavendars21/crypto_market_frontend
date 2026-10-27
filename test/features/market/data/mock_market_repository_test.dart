import 'package:crypto_market/features/market/data/mock_market_repository.dart';
import 'package:crypto_market/features/market/domain/market_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repository = MockMarketRepository(latency: Duration.zero);

  group('MockMarketRepository.getCoins', () {
    test('returns the first page ordered by market cap by default', () async {
      final page = await repository.getCoins(
        query: const MarketQuery(),
        perPage: 5,
      );

      expect(page.coins.map((c) => c.id), [
        'bitcoin',
        'ethereum',
        'tether',
        'binancecoin',
        'solana',
      ]);
      expect(page.page, 1);
      expect(page.totalItems, 24);
      expect(page.hasNextPage, isTrue);
    });

    test('paginates until the last page', () async {
      final lastPage = await repository.getCoins(
        query: const MarketQuery(),
        page: 3,
        perPage: 10,
      );

      expect(lastPage.coins, hasLength(4));
      expect(lastPage.hasNextPage, isFalse);
    });

    test('searches name and symbol, ignoring case', () async {
      final byName = await repository.getCoins(
        query: const MarketQuery(search: 'BITCOIN'),
      );
      final bySymbol = await repository.getCoins(
        query: const MarketQuery(search: ' xLm '),
      );
      final partial = await repository.getCoins(
        query: const MarketQuery(search: 'eth'),
      );

      expect(byName.coins.map((c) => c.id), ['bitcoin', 'bitcoin-cash']);
      expect(bySymbol.coins.map((c) => c.id), ['stellar']);
      expect(partial.coins.map((c) => c.id), ['ethereum', 'tether']);
    });

    test('returns an empty page when nothing matches', () async {
      final page = await repository.getCoins(
        query: const MarketQuery(search: 'zzz-no-match'),
      );

      expect(page.coins, isEmpty);
      expect(page.totalItems, 0);
      expect(page.hasNextPage, isFalse);
    });

    test('sorts by price in both directions', () async {
      final highest = await repository.getCoins(
        query: const MarketQuery(sort: MarketSort.priceDesc),
        perPage: 2,
      );
      final lowest = await repository.getCoins(
        query: const MarketQuery(sort: MarketSort.priceAsc),
        perPage: 2,
      );

      expect(highest.coins.map((c) => c.id), ['bitcoin', 'ethereum']);
      expect(lowest.coins.map((c) => c.id), ['pepe', 'shiba-inu']);
    });

    test('puts coins with an unknown sort value last', () async {
      for (final sort in [MarketSort.change24hDesc, MarketSort.change24hAsc]) {
        final page = await repository.getCoins(
          query: MarketQuery(sort: sort),
          perPage: 100,
        );
        final lastTwo = page.coins.skip(page.coins.length - 2);

        expect(
          lastTwo.map((c) => c.priceChangePercentage24h),
          everyElement(isNull),
          reason: '$sort',
        );
      }
    });

    test('filters gainers and losers by 24h change', () async {
      final gainers = await repository.getCoins(
        query: const MarketQuery(movement: MarketMovement.gainers),
        perPage: 100,
      );
      final losers = await repository.getCoins(
        query: const MarketQuery(movement: MarketMovement.losers),
        perPage: 100,
      );

      expect(
        gainers.coins.map((c) => c.priceChangePercentage24h),
        everyElement(greaterThan(0)),
      );
      expect(
        losers.coins.map((c) => c.priceChangePercentage24h),
        everyElement(lessThan(0)),
      );
      expect(gainers.totalItems + losers.totalItems, 22);
    });

    test('filters by market-cap tier and excludes unknown caps', () async {
      Future<List<double?>> capsFor(MarketCapTier tier) async {
        final page = await repository.getCoins(
          query: MarketQuery(tier: tier),
          perPage: 100,
        );
        return page.coins.map((c) => c.marketCapUsd).toList();
      }

      expect(
        await capsFor(MarketCapTier.large),
        everyElement(greaterThanOrEqualTo(10e9)),
      );
      expect(
        await capsFor(MarketCapTier.mid),
        everyElement(allOf(greaterThanOrEqualTo(1e9), lessThan(10e9))),
      );
      expect(await capsFor(MarketCapTier.small), everyElement(lessThan(1e9)));
      expect(await capsFor(MarketCapTier.small), hasLength(2));
    });

    test('combines search, filter and sort', () async {
      final page = await repository.getCoins(
        query: const MarketQuery(
          search: 'coin',
          movement: MarketMovement.gainers,
          sort: MarketSort.change24hDesc,
        ),
      );

      expect(page.coins.map((c) => c.id), [
        'dogecoin',
        'bitcoin',
        'bitcoin-cash',
        'litecoin',
      ]);
    });

    test('rejects invalid pagination arguments', () {
      expect(
        () => repository.getCoins(query: const MarketQuery(), page: 0),
        throwsArgumentError,
      );
    });
  });

  group('MockMarketRepository.getCoinsByIds', () {
    test('returns known coins in rank order and skips unknown IDs', () async {
      final coins = await repository.getCoinsByIds([
        'solana',
        'does-not-exist',
        'bitcoin',
      ]);

      expect(coins.map((c) => c.id), ['bitcoin', 'solana']);
    });
  });
}
