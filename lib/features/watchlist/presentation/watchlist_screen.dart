import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_views.dart';
import '../../market/domain/coin_summary.dart';
import '../../market/domain/market_query.dart';
import '../../market/presentation/widgets/coin_list_tile.dart';
import '../application/watchlist_coins_controller.dart';
import '../application/watchlist_controller.dart';
import 'widgets/watchlist_button.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(watchlistCoinsProvider.notifier).refresh();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessageFor(error))));
    }
  }

  /// Removes the coin and offers Undo, which puts it back where it was.
  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    CoinSummary coin,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(watchlistProvider.notifier);
    final index = ref.read(watchlistProvider).indexOf(coin.id);

    try {
      await controller.remove(coin.id);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not remove the coin. Try again.')),
      );
      return;
    }

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('${coin.name} removed from watchlist'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => controller.restore(coin.id, index),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSavedCoins = ref.watch(
      watchlistProvider.select((ids) => ids.isNotEmpty),
    );
    final coins = ref.watch(sortedWatchlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [if (hasSavedCoins) const _SortMenu()],
      ),
      body: !hasSavedCoins
          ? EmptyStateView(
              icon: Icons.star_outline_rounded,
              title: 'Your watchlist is empty',
              message:
                  'Tap the star next to any coin to follow its price here. '
                  'Your list is saved on this device.',
              action: FilledButton.icon(
                onPressed: () => context.go(AppRoutes.markets),
                icon: const Icon(Icons.show_chart_rounded),
                label: const Text('Explore markets'),
              ),
            )
          : switch (coins) {
              AsyncValue(:final value?) => RefreshIndicator(
                onRefresh: () => _refresh(context, ref),
                child: _WatchlistList(
                  coins: value,
                  onRemove: (coin) => _remove(context, ref, coin),
                ),
              ),
              AsyncValue(:final error?) => ErrorView(
                error: error,
                onRetry: () => _refresh(context, ref),
              ),
              _ => SkeletonPulse(
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(
                    4,
                    (_) => const CoinListTileSkeleton(),
                  ),
                ),
              ),
            },
    );
  }
}

class _WatchlistList extends StatelessWidget {
  const _WatchlistList({required this.coins, required this.onRemove});

  final List<CoinSummary> coins;
  final ValueChanged<CoinSummary> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      // Always scrollable so pull-to-refresh works with a short list.
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: coins.length + 1,
      itemBuilder: (context, index) {
        if (index == coins.length) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Swipe left to remove · Saved on this device\n'
              'Data provided by CoinGecko',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          );
        }

        final coin = coins[index];
        return Dismissible(
          key: ValueKey(coin.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: context.appColors.negative,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.xl),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
            ),
          ),
          onDismissed: (_) => onRemove(coin),
          child: CoinListTile(
            coin: coin,
            onTap: () => context.push(AppRoutes.coinDetails(coin.id)),
            trailing: WatchlistButton(coinId: coin.id, coinName: coin.name),
          ),
        );
      },
    );
  }
}

/// Sort menu in the app bar. Sorting is done on the device.
class _SortMenu extends ConsumerWidget {
  const _SortMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(watchlistSortProvider);

    return PopupMenuButton<MarketSort>(
      icon: const Icon(Icons.sort_rounded),
      tooltip: 'Sort watchlist (${current.label})',
      initialValue: current,
      onSelected: ref.read(watchlistSortProvider.notifier).set,
      itemBuilder: (context) => [
        for (final option in MarketSort.values)
          CheckedPopupMenuItem(
            value: option,
            checked: option == current,
            child: Text(option.label),
          ),
      ],
    );
  }
}
