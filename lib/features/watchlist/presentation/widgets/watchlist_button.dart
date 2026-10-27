import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/watchlist_controller.dart';
import '../../domain/watchlist_repository.dart';

class WatchlistButton extends ConsumerWidget {
  const WatchlistButton({
    super.key,
    required this.coinId,
    required this.coinName,
  });

  final String coinId;
  final String coinName;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(watchlistProvider.notifier).toggle(coinId);
      if (result == WatchlistToggleResult.full) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Your watchlist is full (${WatchlistRepository.maxCoins} coins). '
              'Remove a coin to add another.',
            ),
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not update your watchlist. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaved = ref.watch(
      watchlistProvider.select((ids) => ids.contains(coinId)),
    );

    return IconButton(
      isSelected: isSaved,
      icon: const Icon(Icons.star_outline_rounded),
      selectedIcon: Icon(Icons.star_rounded, color: context.appColors.star),
      tooltip: isSaved
          ? 'Remove $coinName from watchlist'
          : 'Add $coinName to watchlist',
      onPressed: () => _toggle(context, ref),
    );
  }
}
