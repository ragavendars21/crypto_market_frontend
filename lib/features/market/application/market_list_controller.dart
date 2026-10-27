import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/repository_providers.dart';
import '../domain/coin_summary.dart';
import '../domain/market_query.dart';
import 'market_query_controller.dart';

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

  final int page;
  final bool hasNextPage;
  final int totalItems;
  final bool isStale;

  final bool isLoadingMore;

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
