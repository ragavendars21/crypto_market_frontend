import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_views.dart';
import '../../market_stats/application/global_stats_provider.dart';
import '../application/market_list_controller.dart';
import 'widgets/coin_list_tile.dart';
import 'widgets/market_overview_strip.dart';

/// Content stays readable on tablets instead of stretching edge to edge.
const double _maxContentWidth = 840;

/// Start loading the next page when the user is this close to the end.
const double _loadMoreThreshold = 600;

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    try {
      await Future.wait([
        ref.refresh(marketListProvider.future),
        ref.refresh(globalStatsProvider.future),
      ]);
    } catch (_) {
      // Failures are already part of the providers' state and shown by the
      // UI (error view or snackbar); the spinner just needs to stop.
    }
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

    // A failed pull-to-refresh keeps the old list on screen; tell the user.
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
    return switch (listState) {
      // Data is shown whenever we have it, including while refreshing.
      AsyncValue(:final value?) when value.coins.isEmpty => [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            icon: Icons.search_off_rounded,
            title: 'No coins found',
            message: 'Try a different search or clear the filters.',
          ),
        ),
      ],
      AsyncValue(:final value?) => [
        SliverList.builder(
          itemCount: value.coins.length,
          itemBuilder: (context, index) {
            final coin = value.coins[index];
            return CoinListTile(
              coin: coin,
              onTap: () => context.push(AppRoutes.coinDetails(coin.id)),
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

/// Bottom of the list: a spinner while loading more, a retry row if that
/// failed, or the data attribution once everything is loaded.
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
