import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/coin_details/data/api_coin_details_repository.dart';
import '../../features/coin_details/data/mock_coin_details_repository.dart';
import '../../features/coin_details/domain/coin_details_repository.dart';
import '../../features/market/data/api_market_repository.dart';
import '../../features/market/data/mock_market_repository.dart';
import '../../features/market/domain/market_repository.dart';
import '../../features/market_stats/data/api_market_stats_repository.dart';
import '../../features/market_stats/data/mock_market_stats_repository.dart';
import '../../features/market_stats/domain/market_stats_repository.dart';
import '../../features/watchlist/data/shared_preferences_watchlist_repository.dart';
import '../../features/watchlist/domain/watchlist_repository.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';

// The single place where mock vs live data is chosen. Everything else asks
// for the interface type, and tests override these providers with fakes:
//
//   ProviderScope(overrides: [
//     marketRepositoryProvider.overrideWithValue(FakeMarketRepository()),
//   ], child: ...)

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return switch (ref.watch(appConfigProvider).dataSource) {
    DataSource.live => ApiMarketRepository(ref.watch(apiClientProvider)),
    DataSource.mock => MockMarketRepository(),
  };
});

final coinDetailsRepositoryProvider = Provider<CoinDetailsRepository>((ref) {
  return switch (ref.watch(appConfigProvider).dataSource) {
    DataSource.live => ApiCoinDetailsRepository(ref.watch(apiClientProvider)),
    DataSource.mock => MockCoinDetailsRepository(),
  };
});

final marketStatsRepositoryProvider = Provider<MarketStatsRepository>((ref) {
  return switch (ref.watch(appConfigProvider).dataSource) {
    DataSource.live => ApiMarketStatsRepository(ref.watch(apiClientProvider)),
    DataSource.mock => MockMarketStatsRepository(),
  };
});

/// Loaded once in `main()` (it needs `await`) and injected with
/// `overrideWithValue`, so everything else can read it synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'Override sharedPreferencesProvider in main() or in the test setup.',
  ),
);

/// The watchlist is stored on the device in both mock and live mode.
final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return SharedPreferencesWatchlistRepository(
    ref.watch(sharedPreferencesProvider),
  );
});
