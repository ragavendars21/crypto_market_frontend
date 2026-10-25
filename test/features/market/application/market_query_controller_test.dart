import 'package:crypto_market/core/di/repository_providers.dart';
import 'package:crypto_market/features/market/application/market_list_controller.dart';
import 'package:crypto_market/features/market/application/market_query_controller.dart';
import 'package:crypto_market/features/market/domain/market_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_market_repository.dart';

void main() {
  const debounce = Duration(milliseconds: 20);
  late FakeMarketRepository repository;
  late ProviderContainer container;
  late List<MarketQuery> emitted;

  setUp(() {
    repository = FakeMarketRepository();
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        searchDebounceProvider.overrideWithValue(debounce),
        marketRepositoryProvider.overrideWithValue(repository),
      ],
    );
    emitted = [];
    container.listen(marketQueryProvider, (_, next) => emitted.add(next));
  });

  MarketQueryController notifier() =>
      container.read(marketQueryProvider.notifier);
  MarketQuery query() => container.read(marketQueryProvider);
  Future<void> waitForDebounce() => Future<void>.delayed(debounce * 3);

  group('search', () {
    test('applies only the last text once typing pauses', () async {
      notifier()
        ..updateSearch('b')
        ..updateSearch('bt')
        ..updateSearch('btc');
      expect(query().search, '');

      await waitForDebounce();

      expect(query().search, 'btc');
      expect(emitted, hasLength(1));
    });

    test('submit applies immediately and cancels pending typing', () async {
      notifier()
        ..updateSearch('bit')
        ..submitSearch('eth');
      expect(query().search, 'eth');

      await waitForDebounce();

      expect(query().search, 'eth');
      expect(emitted, hasLength(1));
    });

    test('ignores text that produces an equal query', () async {
      notifier().submitSearch('btc');
      notifier().submitSearch('btc ');
      notifier().submitSearch(' btc');

      expect(emitted, hasLength(1));
    });
  });

  group('filters and sort', () {
    test('toggling the active filter turns it off', () {
      notifier().toggleMovement(MarketMovement.gainers);
      expect(query().movement, MarketMovement.gainers);

      notifier().toggleMovement(MarketMovement.losers);
      expect(query().movement, MarketMovement.losers);

      notifier().toggleMovement(MarketMovement.losers);
      expect(query().movement, MarketMovement.all);

      notifier().toggleTier(MarketCapTier.mid);
      notifier().toggleTier(MarketCapTier.mid);
      expect(query().tier, MarketCapTier.all);
    });

    test('setting the current sort again does nothing', () {
      notifier().setSort(MarketSort.marketCapDesc);
      expect(emitted, isEmpty);

      notifier().setSort(MarketSort.priceAsc);
      expect(query().sort, MarketSort.priceAsc);
    });

    test('clear resets search and filters but keeps the sort', () async {
      notifier()
        ..setSort(MarketSort.volumeDesc)
        ..submitSearch('sol')
        ..toggleTier(MarketCapTier.large)
        ..updateSearch('pending text');

      notifier().clearSearchAndFilters();
      await waitForDebounce();

      expect(query(), const MarketQuery(sort: MarketSort.volumeDesc));
    });
  });

  test('a query change reloads the market list from page 1', () async {
    await container.read(marketListProvider.future);

    notifier().submitSearch('eth');
    await container.read(marketListProvider.future);

    expect(repository.requests, hasLength(2));
    expect(repository.requests.last.page, 1);
    expect(repository.requests.last.query.search, 'eth');
  });
}
