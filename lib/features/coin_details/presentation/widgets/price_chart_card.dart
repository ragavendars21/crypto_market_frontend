import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/formatters/market_formatters.dart';
import '../../../../shared/widgets/price_change_indicator.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../application/coin_details_providers.dart';
import '../../domain/price_history.dart';
import 'price_chart.dart';

class PriceChartCard extends ConsumerWidget {
  const PriceChartCard({
    super.key,
    required this.coinId,
    required this.range,
    required this.onRangeChanged,
  });

  final String coinId;
  final ChartRange range;
  final ValueChanged<ChartRange> onRangeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (coinId: coinId, range: range);
    final history = ref.watch(priceHistoryProvider(key));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<ChartRange>(
              segments: [
                for (final option in ChartRange.values)
                  ButtonSegment(value: option, label: Text(option.label)),
              ],
              selected: {range},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  onRangeChanged(selection.single),
            ),
            const SizedBox(height: AppSpacing.lg),
            switch (history) {
              AsyncValue(:final value?) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RangeSummary(history: value),
                  const SizedBox(height: AppSpacing.md),
                  PriceChart(history: value),
                ],
              ),
              AsyncValue(:final error?) => SizedBox(
                height: priceChartHeight,
                child: InlineErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(priceHistoryProvider(key)),
                ),
              ),
              _ => const SkeletonPulse(
                child: SkeletonBox(
                  width: double.infinity,
                  height: priceChartHeight,
                  radius: AppRadius.tile,
                ),
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _RangeSummary extends StatelessWidget {
  const _RangeSummary({required this.history});

  final PriceHistory history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall;
    final valueStyle = theme.textTheme.labelLarge?.tabular;

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PriceChangeIndicator(
              percentage: history.changePercentage,
              periodLabel: 'over ${history.range.label}',
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('in ${history.range.label}', style: labelStyle),
          ],
        ),
        Text.rich(
          TextSpan(
            text: 'Low ',
            style: labelStyle,
            children: [
              TextSpan(
                text: MarketFormatters.price(history.lowestPrice),
                style: valueStyle,
              ),
            ],
          ),
        ),
        Text.rich(
          TextSpan(
            text: 'High ',
            style: labelStyle,
            children: [
              TextSpan(
                text: MarketFormatters.price(history.highestPrice),
                style: valueStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
