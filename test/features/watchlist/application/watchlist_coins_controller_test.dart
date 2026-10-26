import 'package:crypto_market/core/di/repository_providers.dart';
import 'package:crypto_market/core/errors/app_failure.dart';
import 'package:crypto_market/features/market/domain/market_query.dart';
import 'package:crypto_market/features/watchlist/application/watchlist_coins_controller.dart';
import 'package:crypto_market/features/watchlist/application/watchlist_controller.dart';
import 'package:crypto_market/features/watchlist/domain/watchlist_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_market_repository.dart';

class _MemoryWatchlistRepository implements WatchlistRepository {
  _MemoryWatchlistRepository(this.saved);

  List<String> saved;

  @override
  List<String> loadIds() => saved;

  @override
  Future<void> saveIds(List<String> ids) async => saved = [...ids];
}

void main() {
  late FakeMarketRepository market;
  late ProviderContainer container;

  setUp(() {
    market = FakeMarketRepository(coins: testCoins(5));
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        marketRepositoryProvider.overrideWithValue(market),
        watchlistRepositoryProvider.overrideWithValue(
          _MemoryWatchlistRepository(['coin-3', 'coin-1']),
        ),
      ],
    );
  });

  Future<List<String>> loadedIds() async =>
      (await container.read(watchlistCoinsProvider.future))
          .map((coin) => coin.id)
          .toList();

  WatchlistController watchlist() => container.read(watchlistProvider.notifier);

  test('loads the saved coins with one request', () async {
    expect(await loadedIds(), containsAll(['coin-1', 'coin-3']));
    expect(market.idsRequests, hasLength(1));
  });

  test('removing a coin filters locally without a request', () async {
    await loadedIds();

    await watchlist().remove('coin-3');

    expect(await loadedIds(), ['coin-1']);
    expect(market.idsRequests, hasLength(1));
  });

  test('adding a coin fetches the data it does not have yet', () async {
    await loadedIds();

    await watchlist().toggle('coin-5');

    expect(await loadedIds(), containsAll(['coin-1', 'coin-3', 'coin-5']));
    expect(market.idsRequests, hasLength(2));
  });

  test('refresh always fetches fresh data', () async {
    await loadedIds();

    await container.read(watchlistCoinsProvider.notifier).refresh();

    expect(market.idsRequests, hasLength(2));
  });

  test('a failed refresh keeps the shown data and reports the error', () async {
    await loadedIds();
    market.failNextRequestWith = const NetworkFailure();

    await expectLater(
      container.read(watchlistCoinsProvider.notifier).refresh(),
      throwsA(isA<NetworkFailure>()),
    );
    expect(container.read(watchlistCoinsProvider).value, hasLength(2));
  });

  test('an empty watchlist makes no request at all', () async {
    await watchlist().remove('coin-3');
    await watchlist().remove('coin-1');

    expect(await loadedIds(), isEmpty);
    expect(market.idsRequests, isEmpty);
  });

  test('sorts on the device by the chosen order', () async {
    await loadedIds();

    container.read(watchlistSortProvider.notifier).set(MarketSort.marketCapAsc);
    final sorted = container.read(sortedWatchlistProvider).requireValue;

    // Coin 3 has the smaller market cap (1e9 / 3).
    expect(sorted.map((coin) => coin.id), ['coin-3', 'coin-1']);
  });
}
