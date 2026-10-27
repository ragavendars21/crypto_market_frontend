import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/repository_providers.dart';
import '../../market/domain/coin_summary.dart';
import '../../market/domain/market_query.dart';
import '../../market/domain/market_sorting.dart';
import 'watchlist_controller.dart';

class WatchlistCoinsController extends AsyncNotifier<List<CoinSummary>> {
  @override
  Future<List<CoinSummary>> build() async {
    final ids = ref.watch(watchlistProvider);
    if (ids.isEmpty) return const [];

    final loaded = state.value;
    if (loaded != null) {
      final loadedIds = {for (final coin in loaded) coin.id};
      if (ids.every(loadedIds.contains)) {
        return loaded.where((coin) => ids.contains(coin.id)).toList();
      }
    }
    return _fetch(ids);
  }

  Future<void> refresh() async {
    final ids = ref.read(watchlistProvider);
    try {
      final coins = await _fetch(ids);
      if (ref.mounted) state = AsyncData(coins);
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      if (state.hasValue) rethrow;
      state = AsyncError(error, stackTrace);
    }
  }

  Future<List<CoinSummary>> _fetch(List<String> ids) async {
    if (ids.isEmpty) return const [];
    return ref.read(marketRepositoryProvider).getCoinsByIds(ids);
  }
}

final watchlistCoinsProvider =
    AsyncNotifierProvider<WatchlistCoinsController, List<CoinSummary>>(
      WatchlistCoinsController.new,
    );

class WatchlistSortController extends Notifier<MarketSort> {
  @override
  MarketSort build() => MarketSort.marketCapDesc;

  void set(MarketSort sort) => state = sort;
}

final watchlistSortProvider =
    NotifierProvider<WatchlistSortController, MarketSort>(
      WatchlistSortController.new,
    );

final sortedWatchlistProvider = Provider<AsyncValue<List<CoinSummary>>>((ref) {
  final ids = ref.watch(watchlistProvider).toSet();
  final sort = ref.watch(watchlistSortProvider);
  return ref
      .watch(watchlistCoinsProvider)
      .whenData(
        (coins) =>
            sortCoins(coins.where((coin) => ids.contains(coin.id)), sort),
      );
});
