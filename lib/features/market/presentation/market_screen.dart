import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_views.dart';
import '../../market_stats/application/global_stats_provider.dart';
import '../../watchlist/presentation/widgets/watchlist_button.dart';
import '../application/market_list_controller.dart';
import '../application/market_query_controller.dart';
import 'widgets/coin_list_tile.dart';
import 'widgets/market_overview_strip.dart';
import 'widgets/search_and_filter_bar.dart';

const double _maxContentWidth = 840;

const double _loadMoreThreshold = 600;

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    try {
      await Future.wait([
        ref.refresh(marketListProvider.future),
        ref.refresh(globalStatsProvider.future),
      ]);
    } catch (_) {}
  }

  bool _onScroll(ScrollNotification notification, WidgetRef ref) {
    if (notification.metrics.extentAfter < _loadMoreThreshold) {
      ref.read(marketListProvider.notifier).loadNextPage();
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(marketListProvider);

    ref.listen(marketListProvider, (previous, next) {
      if (next is AsyncError && next.hasValue) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessageFor(next.error!))));
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sidePadding = math.max(
              0.0,
              (constraints.maxWidth - _maxContentWidth) / 2,
            );

            return RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) => _onScroll(notification, ref),
                child: CustomScrollView(
                  slivers: [
                    const SliverAppBar(floating: true, title: Text('Markets')),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: sidePadding),
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          const SliverToBoxAdapter(
                            child: MarketOverviewStrip(),
                          ),
                          const PinnedHeaderSliver(child: SearchAndFilterBar()),
                          SliverToBoxAdapter(
                            child: _ReloadingIndicator(
                              visible:
                                  listState.isLoading && listState.hasValue,
                            ),
                          ),
                          if (listState.value?.isStale ?? false)
                            const SliverToBoxAdapter(child: StaleDataBanner()),
                          ..._listSlivers(context, ref, listState),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _listSlivers(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<MarketListState> listState,
  ) {
    final query = ref.watch(marketQueryProvider);
    void clearSearchAndFilters() =>
        ref.read(marketQueryProvider.notifier).clearSearchAndFilters();

    return switch (listState) {
      AsyncValue(:final value?) when value.coins.isEmpty => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            icon: Icons.search_off_rounded,
            title: query.trimmedSearch.isEmpty
                ? 'No coins match these filters'
                : 'No results for "${query.trimmedSearch}"',
            message:
                'Search covers the top 250 coins by market cap. '
                'Try another name or symbol, or clear the filters.',
            action: query.isNarrowed
                ? OutlinedButton(
                    onPressed: clearSearchAndFilters,
                    child: const Text('Clear search and filters'),
                  )
                : null,
          ),
        ),
      ],
      AsyncValue(:final value?) => [
        if (query.isNarrowed)
          SliverToBoxAdapter(
            child: _ResultsSummary(
              totalItems: value.totalItems,
              onClear: clearSearchAndFilters,
            ),
          ),
        SliverList.builder(
          itemCount: value.coins.length,
          itemBuilder: (context, index) {
            final coin = value.coins[index];
            return CoinListTile(
              coin: coin,
              onTap: () => context.push(AppRoutes.coinDetails(coin.id)),
              trailing: WatchlistButton(coinId: coin.id, coinName: coin.name),
            );
          },
        ),
        SliverToBoxAdapter(
          child: _ListFooter(
            state: value,
            onRetry: () => ref
                .read(marketListProvider.notifier)
                .loadNextPage(isRetry: true),
          ),
        ),
      ],
      AsyncValue(:final error?) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            error: error,
            onRetry: () => ref.invalidate(marketListProvider),
          ),
        ),
      ],
      _ => [
        SliverToBoxAdapter(
          child: SkeletonPulse(
            child: Column(
              children: List.generate(8, (_) => const CoinListTileSkeleton()),
            ),
          ),
        ),
      ],
    };
  }
}

class _ReloadingIndicator extends StatelessWidget {
  const _ReloadingIndicator({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: visible ? const LinearProgressIndicator(minHeight: 2) : null,
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.totalItems, required this.onClear});

  final int totalItems;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              totalItems == 1 ? '1 result' : '$totalItems results',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.state, required this.onRetry});

  final MarketListState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadMoreError = state.loadMoreError;

    final Widget child;
    if (state.isLoadingMore) {
      child = const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    } else if (loadMoreError != null) {
      child = Column(
        children: [
          Text(
            "Couldn't load more coins. ${errorMessageFor(loadMoreError)}",
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      );
    } else if (!state.hasNextPage) {
      child = Text(
        'Showing ${state.totalItems} coins · Data provided by CoinGecko',
        style: theme.textTheme.bodySmall,
        textAlign: TextAlign.center,
      );
    } else {
      child = const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Center(child: child),
    );
  }
}
