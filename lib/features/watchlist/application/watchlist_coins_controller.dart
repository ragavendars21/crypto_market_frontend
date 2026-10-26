import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/repository_providers.dart';
import '../../market/domain/coin_summary.dart';
import '../../market/domain/market_query.dart';
import '../../market/domain/market_sorting.dart';
import 'watchlist_controller.dart';

/// Latest market data for the saved coins.
///
/// Rebuilds whenever the saved IDs change, but avoids needless requests:
/// if coins were only removed, the already-loaded data is filtered locally.
/// A request is made only when there are coins we have no data for, or when
/// the user pulls to refresh.
class WatchlistCoinsController extends AsyncNotifier<List<CoinSummary>> {
  @override
  Future<List<CoinSummary>> build() async {
    final ids = ref.watch(watchlistProvider);
    if (ids.isEmpty) return const [];

    // On a rebuild, `state` still holds the previous result.
    final loaded = state.value;
    if (loaded != null) {
      final loadedIds = {for (final coin in loaded) coin.id};
      if (ids.every(loadedIds.contains)) {
        return loaded.where((coin) => ids.contains(coin.id)).toList();
      }
    }
    return _fetch(ids);
  }

  /// Pull-to-refresh: always fetches fresh prices. If it fails while data is
  /// already on screen, the data stays and the error is rethrown for a
  /// snackbar; otherwise the screen shows the error state.
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

/// Sort order for the watchlist. Sorting happens on the device because the
/// list is small (at most 50 coins) and already loaded, so asking the server
/// would only add a request.
class WatchlistSortController extends Notifier<MarketSort> {
  @override
  MarketSort build() => MarketSort.marketCapDesc;

  void set(MarketSort sort) => state = sort;
}

final watchlistSortProvider =
    NotifierProvider<WatchlistSortController, MarketSort>(
      WatchlistSortController.new,
    );

/// What the watchlist screen shows: loaded coins, limited to the IDs that
/// are saved right now, in the chosen order.
///
/// Filtering by the current IDs here (synchronously) makes a removal
/// disappear instantly, which a swipe-to-dismiss list requires.
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
