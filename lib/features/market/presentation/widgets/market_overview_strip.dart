import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/formatters/market_formatters.dart';
import '../../../../shared/widgets/market_stat_card.dart';
import '../../../../shared/widgets/price_change_indicator.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../market_stats/application/global_stats_provider.dart';
import '../../../market_stats/domain/global_market_stats.dart';

class MarketOverviewStrip extends ConsumerWidget {
  const MarketOverviewStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(globalStatsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: switch (stats) {
        AsyncValue(:final value?) => _StatsRow(stats: value),
        AsyncValue(:final error?) => _OverviewError(
          error: error,
          onRetry: () => ref.invalidate(globalStatsProvider),
        ),
        _ => const _StatsRowSkeleton(),
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final GlobalMarketStats stats;

  @override
  Widget build(BuildContext context) {
    final dominance = stats.bitcoinDominance;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MarketStatCard(
              label: 'Market cap',
              value: MarketFormatters.compactCurrency(stats.totalMarketCapUsd),
              footer: PriceChangeIndicator(
                percentage: stats.marketCapChangePercentage24h,
                periodLabel: 'in 24 hours',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: MarketStatCard(
              label: '24h volume',
              value: MarketFormatters.compactCurrency(stats.totalVolumeUsd),
              footer: PriceChangeIndicator(
                percentage: stats.volumeChangePercentage24h,
                periodLabel: 'in 24 hours',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: MarketStatCard(
              label: 'BTC dominance',
              value: dominance == null
                  ? MarketFormatters.notAvailable
                  : '${dominance.toStringAsFixed(1)}%',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRowSkeleton extends StatelessWidget {
  const _StatsRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonPulse(
      child: Row(
        children: [
          Expanded(child: SkeletonBox(width: 100, height: 76, radius: 16)),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: SkeletonBox(width: 100, height: 76, radius: 16)),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: SkeletonBox(width: 100, height: 76, radius: 16)),
        ],
      ),
    );
  }
}

class _OverviewError extends StatelessWidget {
  const _OverviewError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            'Market overview unavailable. ${errorMessageFor(error)}',
            style: theme.textTheme.bodySmall,
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
