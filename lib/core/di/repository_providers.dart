import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/coin_details/data/mock_coin_details_repository.dart';
import '../../features/coin_details/domain/coin_details_repository.dart';
import '../../features/market/data/mock_market_repository.dart';
import '../../features/market/domain/market_repository.dart';
import '../../features/market_stats/data/mock_market_stats_repository.dart';
import '../../features/market_stats/domain/market_stats_repository.dart';
import '../config/app_config.dart';

// The single place where mock vs live data is chosen. Everything else asks
// for the interface type, and tests override these providers with fakes:
//
//   ProviderScope(overrides: [
//     marketRepositoryProvider.overrideWithValue(FakeMarketRepository()),
//   ], child: ...)

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return switch (ref.watch(appConfigProvider).dataSource) {
    DataSource.mock => MockMarketRepository(),
    DataSource.live => throw _liveDataNotConnected,
  };
});

final coinDetailsRepositoryProvider = Provider<CoinDetailsRepository>((ref) {
  return switch (ref.watch(appConfigProvider).dataSource) {
    DataSource.mock => MockCoinDetailsRepository(),
    DataSource.live => throw _liveDataNotConnected,
  };
});

final marketStatsRepositoryProvider = Provider<MarketStatsRepository>((ref) {
  return switch (ref.watch(appConfigProvider).dataSource) {
    DataSource.mock => MockMarketStatsRepository(),
    DataSource.live => throw _liveDataNotConnected,
  };
});

// Temporary until Phase 10 adds the Dio-backed repositories.
final _liveDataNotConnected = UnimplementedError(
  'Live data is connected in Phase 10. Run with DATA_SOURCE=mock for now.',
);
