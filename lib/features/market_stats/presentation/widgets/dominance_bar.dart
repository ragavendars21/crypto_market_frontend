import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/global_market_stats.dart';

const int _maxSegments = 5;

const _colorSlotBySymbol = {'btc': 0, 'eth': 1, 'usdt': 2, 'bnb': 3, 'sol': 4};

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  for (final (index, segment) in segments.indexed)
                    Expanded(
                      flex: (segment.percentage * 100).round().clamp(1, 10000),
                      child: Container(
                        decoration: BoxDecoration(
                          color: segment.color,
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
