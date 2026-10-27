import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/formatters/market_formatters.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_views.dart';
import '../../watchlist/presentation/widgets/watchlist_button.dart';
import '../application/coin_details_providers.dart';
import '../domain/coin_details.dart';
import '../domain/price_history.dart';
import 'widgets/coin_detail_sections.dart';
import 'widgets/price_chart_card.dart';

const double _maxContentWidth = 720;

class CoinDetailsScreen extends ConsumerStatefulWidget {
  const CoinDetailsScreen({super.key, required this.coinId});

  final String coinId;

  @override
  ConsumerState<CoinDetailsScreen> createState() => _CoinDetailsScreenState();
}

class _CoinDetailsScreenState extends ConsumerState<CoinDetailsScreen> {
  ChartRange _range = ChartRange.week;

  Future<void> _refresh() async {
    try {
      await Future.wait([
        ref.refresh(coinDetailsProvider(widget.coinId).future),
        ref.refresh(
          priceHistoryProvider((coinId: widget.coinId, range: _range)).future,
        ),
      ]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(coinDetailsProvider(widget.coinId));

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back to markets',
                onPressed: () => context.go(AppRoutes.markets),
              ),
        title: Text(details.value?.name ?? ''),
        actions: [
          if (details.value case final coin?)
            WatchlistButton(coinId: coin.id, coinName: coin.name),
        ],
      ),
      body: switch (details) {
        AsyncValue(:final value?) => RefreshIndicator(
          onRefresh: _refresh,
          child: _DetailsContent(
            details: value,
            range: _range,
            onRangeChanged: (range) => setState(() => _range = range),
          ),
        ),
        AsyncValue(error: NotFoundFailure()) => EmptyStateView(
          icon: Icons.search_off_rounded,
          title: 'Coin not found',
          message: 'We couldn\'t find a coin with the ID "${widget.coinId}".',
          action: FilledButton(
            onPressed: () => context.go(AppRoutes.markets),
            child: const Text('Back to markets'),
          ),
        ),
        AsyncValue(:final error?) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(coinDetailsProvider(widget.coinId)),
        ),
        _ => const _DetailsSkeleton(),
      },
    );
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({
    required this.details,
    required this.range,
    required this.onRangeChanged,
  });

  final CoinDetails details;
  final ChartRange range;
  final ValueChanged<ChartRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpacing.lg);

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
            CoinPriceHeader(details: details),
            const SizedBox(height: AppSpacing.xl),
            PriceChartCard(
              coinId: details.id,
              range: range,
              onRangeChanged: onRangeChanged,
            ),
            gap,
            DetailSectionCard(
              title: 'Performance',
              children: [
                PerformanceGrid(changes: details.priceChangePercentages),
              ],
            ),
            gap,
            DetailSectionCard(
              title: 'Market data',
              children: [
                StatRow(
                  label: 'Market cap',
                  value: MarketFormatters.compactCurrency(details.marketCapUsd),
                ),
                StatRow(
                  label: 'Fully diluted valuation',
                  value: MarketFormatters.compactCurrency(
                    details.fullyDilutedValuationUsd,
                  ),
                ),
                StatRow(
                  label: '24h trading volume',
                  value: MarketFormatters.compactCurrency(
                    details.totalVolumeUsd,
                  ),
                ),
                StatRow(
                  label: '24h high',
                  value: MarketFormatters.price(details.high24hUsd),
                ),
                StatRow(
                  label: '24h low',
                  value: MarketFormatters.price(details.low24hUsd),
                ),
              ],
            ),
            gap,
            SupplySection(details: details),
            gap,
            PriceExtremesSection(details: details),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Last updated ${MarketFormatters.dateTime(details.lastUpdated)}'
              '\nData provided by CoinGecko',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(
                    width: AppSizes.coinLogoHeader,
                    height: AppSizes.coinLogoHeader,
                    radius: AppSizes.coinLogoHeader / 2,
                  ),
                  SizedBox(width: AppSpacing.md),
                  SkeletonBox(width: 140, height: 24),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              SkeletonBox(width: 200, height: 36),
              SizedBox(height: AppSpacing.xl),
              SkeletonBox(width: double.infinity, height: 300, radius: 16),
              SizedBox(height: AppSpacing.lg),
              SkeletonBox(width: double.infinity, height: 140, radius: 16),
            ],
          ),
        ],
      ),
    );
  }
}
