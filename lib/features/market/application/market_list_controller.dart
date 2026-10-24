import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/repository_providers.dart';
import '../domain/coin_summary.dart';
import '../domain/market_query.dart';
import 'market_query_controller.dart';

/// Everything the market list needs to render, including pagination status.
class MarketListState {
  const MarketListState({
    required this.coins,
    required this.page,
    required this.hasNextPage,
    required this.totalItems,
    this.isStale = false,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<CoinSummary> coins;

  /// Last page that was loaded.
  final int page;
  final bool hasNextPage;
  final int totalItems;
  final bool isStale;

  /// True while the next page is loading (shows a spinner at the bottom).
  final bool isLoadingMore;

  /// Set when loading the next page failed. The coins already shown stay
  /// visible and a retry row appears at the end of the list.
  final Object? loadMoreError;

  MarketListState copyWith({
    List<CoinSummary>? coins,
    int? page,
    bool? hasNextPage,
    int? totalItems,
    bool? isStale,
    bool? isLoadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return MarketListState(
      coins: coins ?? this.coins,
      page: page ?? this.page,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      totalItems: totalItems ?? this.totalItems,
      isStale: isStale ?? this.isStale,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
    );
  }
}

/// Loads the market list page by page.
///
/// `build` loads page 1. Riverpod exposes the result as an `AsyncValue`, so
/// the screen can show loading, error or data. Because `build` watches
/// [marketQueryProvider], any change to search, sort or filters rebuilds
/// this controller and starts again from page 1.
class MarketListController extends AsyncNotifier<MarketListState> {
  late MarketQuery _query;

  @override
  Future<MarketListState> build() async {
    _query = ref.watch(marketQueryProvider);
    final repository = ref.watch(marketRepositoryProvider);

    final firstPage = await repository.getCoins(query: _query);
    return MarketListState(
      coins: firstPage.coins,
      page: firstPage.page,
      hasNextPage: firstPage.hasNextPage,
      totalItems: firstPage.totalItems,
      isStale: firstPage.isStale,
    );
  }

  /// Appends the next page. Safe to call repeatedly while scrolling: it does
  /// nothing if a page is already loading or there are no more pages.
  ///
  /// After a failure, scrolling no longer triggers new attempts (that would
  /// fire a request on every scroll event); the user retries explicitly,
  /// which passes [isRetry].
  Future<void> loadNextPage({bool isRetry = false}) async {
    final current = state.value;
    if (current == null ||
        state.isLoading ||
        current.isLoadingMore ||
        !current.hasNextPage ||
        (current.loadMoreError != null && !isRetry)) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );

    try {
      final nextPage = await ref
          .read(marketRepositoryProvider)
          .getCoins(query: _query, page: current.page + 1);
      // The query may have changed while we waited; that rebuild replaced
      // this controller, so its result must be discarded.
      if (!ref.mounted) return;

      state = AsyncData(
        current.copyWith(
          coins: [...current.coins, ...nextPage.coins],
          page: nextPage.page,
          hasNextPage: nextPage.hasNextPage,
          totalItems: nextPage.totalItems,
          isStale: current.isStale || nextPage.isStale,
          isLoadingMore: false,
          clearLoadMoreError: true,
        ),
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: error),
      );
    }
  }
}

final marketListProvider =
    AsyncNotifierProvider<MarketListController, MarketListState>(
      MarketListController.new,
    );
