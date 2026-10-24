import 'package:crypto_market/core/di/repository_providers.dart';
import 'package:crypto_market/core/errors/app_failure.dart';
import 'package:crypto_market/features/market/application/market_list_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_market_repository.dart';

void main() {
  late FakeMarketRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeMarketRepository(coins: testCoins(45));
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [marketRepositoryProvider.overrideWithValue(repository)],
    );
  });

  Future<MarketListState> loadFirstPage() =>
      container.read(marketListProvider.future);

  MarketListController controller() =>
      container.read(marketListProvider.notifier);

  test('loads the first page', () async {
    final state = await loadFirstPage();

    expect(state.coins, hasLength(20));
    expect(state.page, 1);
    expect(state.hasNextPage, isTrue);
    expect(state.totalItems, 45);
  });

  test('appends pages until there are no more', () async {
    await loadFirstPage();

    await controller().loadNextPage();
    await controller().loadNextPage();
    final state = container.read(marketListProvider).requireValue;

    expect(state.coins, hasLength(45));
    expect(state.coins.last.id, 'coin-45');
    expect(state.hasNextPage, isFalse);

    // Nothing left to load: no further request is made.
    await controller().loadNextPage();
    expect(repository.requests, hasLength(3));
  });

  test('ignores repeated calls while a page is already loading', () async {
    await loadFirstPage();

    await Future.wait([
      controller().loadNextPage(),
      controller().loadNextPage(),
    ]);

    expect(repository.requests.map((r) => r.page), [1, 2]);
  });

  test('keeps loaded coins when the next page fails, then retries', () async {
    await loadFirstPage();
    repository.failNextRequestWith = const TimeoutFailure();

    await controller().loadNextPage();
    var state = container.read(marketListProvider).requireValue;
    expect(state.coins, hasLength(20));
    expect(state.loadMoreError, isA<TimeoutFailure>());
    expect(state.isLoadingMore, isFalse);

    // Further scrolling does not retry on its own...
    await controller().loadNextPage();
    expect(repository.requests, hasLength(2));

    // ...an explicit retry does, and clears the error on success.
    await controller().loadNextPage(isRetry: true);
    state = container.read(marketListProvider).requireValue;
    expect(state.coins, hasLength(40));
    expect(state.loadMoreError, isNull);
  });

  test('exposes a first-page failure as an error state', () async {
    repository.failNextRequestWith = const NetworkFailure();

    await expectLater(loadFirstPage(), throwsA(isA<NetworkFailure>()));
    expect(container.read(marketListProvider).error, isA<NetworkFailure>());
  });

  test('marks the list stale when the backend served cached data', () async {
    repository.isStale = true;

    expect((await loadFirstPage()).isStale, isTrue);
  });
}
