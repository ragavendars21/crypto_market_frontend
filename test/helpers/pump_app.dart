import 'package:crypto_market/app.dart';
import 'package:crypto_market/core/di/repository_providers.dart';
import 'package:crypto_market/features/coin_details/data/mock_coin_details_repository.dart';
import 'package:crypto_market/features/coin_details/domain/coin_details_repository.dart';
import 'package:crypto_market/features/market/domain/market_repository.dart';
import 'package:crypto_market/features/market_stats/data/mock_market_stats_repository.dart';
import 'package:crypto_market/features/market_stats/domain/market_stats_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'fake_market_repository.dart';

/// Pumps the whole app (router, theme, providers) with test repositories.
/// Returns the provider container so tests can inspect or drive state.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  MarketRepository? marketRepository,
  MarketStatsRepository? marketStatsRepository,
  CoinDetailsRepository? coinDetailsRepository,
  List<Override> overrides = const [],
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      // Same as the real app: no automatic retries.
      retry: (_, _) => null,
      overrides: [
        marketRepositoryProvider.overrideWithValue(
          marketRepository ?? FakeMarketRepository(),
        ),
        marketStatsRepositoryProvider.overrideWithValue(
          marketStatsRepository ??
              MockMarketStatsRepository(latency: Duration.zero),
        ),
        coinDetailsRepositoryProvider.overrideWithValue(
          coinDetailsRepository ??
              MockCoinDetailsRepository(latency: Duration.zero),
        ),
        ...overrides,
      ],
      child: const CryptoMarketApp(),
    ),
  );
  if (settle) await tester.pumpAndSettle();

  return ProviderScope.containerOf(
    tester.element(find.byType(CryptoMarketApp)),
  );
}
