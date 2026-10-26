import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/global_market_stats.dart';

/// How many coins get their own segment; the rest fold into "Others".
const int _maxSegments = 5;

/// Fixed color slot per coin, so a coin keeps its color even if the
/// ranking changes between refreshes (color follows the coin, not its rank).
/// Coins without a slot use the next free one.
const _colorSlotBySymbol = {'btc': 0, 'eth': 1, 'usdt': 2, 'bnb': 3, 'sol': 4};

/// Market dominance as one horizontal 100% bar plus a legend.
///
/// A stacked bar is used instead of a pie/donut because lengths along one
/// line are easier to compare accurately than angles. Every segment is
/// named with its percentage in the legend, so colour is never the only
/// way to tell coins apart.
class DominanceBar extends StatelessWidget {
  const DominanceBar({super.key, required this.stats});

  final GlobalMarketStats stats;

  @override
  Widget build(BuildContext context) {
    final segments = _buildSegments(context.appColors);
    final surface = Theme.of(context).colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          // The legend below reads out every value.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  for (final (index, segment) in segments.indexed)
                    Expanded(
                      // Flex needs integers; hundredths of a percent keep
                      // small shares visible and proportions exact.
                      flex: (segment.percentage * 100).round().clamp(1, 10000),
                      child: Container(
                        decoration: BoxDecoration(
                          color: segment.color,
                          // 2px gap between segments, in the card color.
                          border: index == 0
                              ? null
                              : Border(
                                  left: BorderSide(color: surface, width: 2),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final segment in segments) _LegendRow(segment: segment),
      ],
    );
  }

  List<_Segment> _buildSegments(AppColors colors) {
    final shown = stats.dominance.take(_maxSegments).toList();
    final usedSlots = <int>{
      for (final entry in shown) ?_colorSlotBySymbol[entry.symbol],
    };

    // Coins with a fixed slot keep it; any other coin takes the first slot
    // nobody is using. At most five coins are shown, so a slot is always free.
    int slotFor(String symbol) {
      final fixed = _colorSlotBySymbol[symbol];
      if (fixed != null) return fixed;
      var slot = 0;
      while (usedSlots.contains(slot)) {
        slot++;
      }
      usedSlots.add(slot);
      return slot;
    }

    final segments = [
      for (final entry in shown)
        _Segment(
          label: entry.displaySymbol,
          percentage: entry.percentage,
          color: colors.chartSeries[slotFor(entry.symbol)],
        ),
    ];

    final others = 100 - shown.fold<double>(0, (sum, e) => sum + e.percentage);
    if (others > 0.05) {
      segments.add(
        _Segment(label: 'Others', percentage: others, color: colors.chartOther),
      );
    }
    return segments;
  }
}

class _Segment {
  const _Segment({
    required this.label,
    required this.percentage,
    required this.color,
  });

  final String label;
  final double percentage;
  final Color color;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.segment});

  final _Segment segment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = '${segment.percentage.toStringAsFixed(1)}%';

    return Semantics(
      label: '${segment.label}, $value of total market cap',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: segment.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Text uses normal text colors, never the series color.
            Expanded(
              child: Text(segment.label, style: theme.textTheme.bodyMedium),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.tabular.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
