import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/formatters/market_formatters.dart';
import '../../../shared/widgets/market_stat_card.dart';
import '../../../shared/widgets/price_change_indicator.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/global_stats_provider.dart';
import '../domain/global_market_stats.dart';
import 'widgets/dominance_bar.dart';

const double _maxContentWidth = 720;

class MarketStatsScreen extends ConsumerWidget {
  const MarketStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(globalStatsProvider);

    ref.listen(globalStatsProvider, (previous, next) {
      if (next is AsyncError && next.hasValue) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessageFor(next.error!))));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Global market')),
      body: switch (stats) {
        AsyncValue(:final value?) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(globalStatsProvider);
            try {
              await ref.read(globalStatsProvider.future);
            } catch (_) {}
          },
          child: _StatsContent(stats: value),
        ),
        AsyncValue(:final error?) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(globalStatsProvider),
        ),
        _ => const _StatsSkeleton(),
      },
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.stats});

  final GlobalMarketStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final btcDominance = stats.bitcoinDominance;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.max(
          AppSpacing.lg,
          (constraints.maxWidth - _maxContentWidth) / 2,
        );

        return ListView(
          padding: EdgeInsets.fromLTRB(
            side,
            AppSpacing.sm,
            side,
            AppSpacing.xxl,
          ),
          children: [
            _HeroCard(stats: stats),
            const SizedBox(height: AppSpacing.md),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: MarketStatCard(
                      label: '24h trading volume',
                      value: MarketFormatters.compactCurrency(
                        stats.totalVolumeUsd,
                      ),
                      footer: PriceChangeIndicator(
                        percentage: stats.volumeChangePercentage24h,
                        periodLabel: 'in 24 hours',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: MarketStatCard(
                      label: 'Bitcoin dominance',
                      value: btcDominance == null
                          ? MarketFormatters.notAvailable
                          : '${btcDominance.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: MarketStatCard(
                      label: 'Active cryptocurrencies',
                      value: MarketFormatters.count(
                        stats.activeCryptocurrencies,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: MarketStatCard(
                      label: 'Exchanges tracked',
                      value: MarketFormatters.count(stats.markets),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader('Market cap dominance'),
                    if (stats.dominance.isEmpty)
                      Text(
                        'Dominance data is not available right now.',
                        style: theme.textTheme.bodyMedium,
                      )
                    else
                      DominanceBar(stats: stats),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Updated ${MarketFormatters.dateTime(stats.updatedAt)}'
              '\nData provided by CoinGecko',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.stats});

  final GlobalMarketStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total crypto market cap', style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                MarketFormatters.compactCurrency(stats.totalMarketCapUsd),
                style: theme.textTheme.displaySmall?.tabular,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                PriceChangeIndicator(
                  percentage: stats.marketCapChangePercentage24h,
                  periodLabel: 'in 24 hours',
                  filled: true,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('24h', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          SkeletonBox(width: double.infinity, height: 136, radius: 16),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(width: double.infinity, height: 88, radius: 16),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(width: double.infinity, height: 88, radius: 16),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(width: double.infinity, height: 220, radius: 16),
        ],
      ),
    );
  }
}
