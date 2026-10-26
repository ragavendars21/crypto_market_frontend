import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/formatters/market_formatters.dart';
import '../../domain/price_history.dart';

/// Height shared by the chart and its loading/empty states, so switching
/// ranges never makes the page jump.
const double priceChartHeight = 220;

/// Interactive line chart of a coin's price over one range.
///
/// Drag across it to see the price and time at any point. Green when the
/// range ended higher than it started, red when lower. With fewer than two
/// points it shows a message instead of a misleading line.
class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.history});

  final PriceHistory history;

  @override
  Widget build(BuildContext context) {
    if (!history.hasEnoughData) {
      return const _NotEnoughData();
    }

    final theme = Theme.of(context);
    final lineColor = history.isUp
        ? context.appColors.positive
        : context.appColors.negative;
    final points = history.points;
    final spots = [
      for (final point in points)
        FlSpot(point.time.millisecondsSinceEpoch.toDouble(), point.priceUsd),
    ];

    final low = history.lowestPrice!;
    final high = history.highestPrice!;
    // Leave breathing room above and below the line. A perfectly flat range
    // still gets a visible band around the price.
    final padding = high == low ? high * 0.01 : (high - low) * 0.1;
    final minX = spots.first.x;
    final maxX = spots.last.x;

    final labelStyle = theme.textTheme.labelSmall!.tabular;

    return Semantics(
      container: true,
      label: _semanticSummary(),
      excludeSemantics: true,
      child: SizedBox(
        height: priceChartHeight,
        child: LineChart(
          LineChartData(
            minX: minX,
            maxX: maxX,
            minY: low - padding,
            maxY: high + padding,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                color: lineColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      lineColor.withValues(alpha: 0.25),
                      lineColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              leftTitles: const AxisTitles(),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 64,
                  getTitlesWidget: (value, meta) {
                    // The outermost labels sit on the padding; skip them.
                    if (value == meta.min || value == meta.max) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(_axisPrice(value), style: labelStyle),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: (maxX - minX) / 4,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) {
                      return const SizedBox.shrink();
                    }
                    final time = DateTime.fromMillisecondsSinceEpoch(
                      value.toInt(),
                    );
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        _axisTimeFormat(history.range).format(time),
                        style: labelStyle,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                getTooltipItems: (touchedSpots) => [
                  for (final spot in touchedSpots)
                    LineTooltipItem(
                      '${MarketFormatters.price(spot.y)}\n',
                      theme.textTheme.labelLarge!.tabular.copyWith(
                        color: theme.colorScheme.onInverseSurface,
                      ),
                      children: [
                        TextSpan(
                          text: _tooltipTimeFormat(history.range).format(
                            DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()),
                          ),
                          style: theme.textTheme.labelSmall!.copyWith(
                            color: theme.colorScheme.onInverseSurface,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              getTouchedSpotIndicator: (barData, indexes) => [
                for (final _ in indexes)
                  TouchedSpotIndicatorData(
                    FlLine(color: lineColor.withValues(alpha: 0.5)),
                    FlDotData(
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 4,
                        color: lineColor,
                        strokeWidth: 2,
                        strokeColor: theme.colorScheme.surface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One sentence for screen readers, since a chart can't be "read".
  String _semanticSummary() {
    final first = history.points.first.priceUsd;
    final last = history.points.last.priceUsd;
    final change = history.changePercentage;
    final direction = change == null
        ? ''
        : ', ${change >= 0 ? 'up' : 'down'} '
              '${change.abs().toStringAsFixed(2)} percent';
    return 'Price chart for ${history.range.label}. '
        'Started at ${MarketFormatters.price(first)}, '
        'ended at ${MarketFormatters.price(last)}$direction. '
        'Low ${MarketFormatters.price(history.lowestPrice)}, '
        'high ${MarketFormatters.price(history.highestPrice)}.';
  }

  static String _axisPrice(double value) => value.abs() >= 1000
      ? MarketFormatters.compactCurrency(value)
      : MarketFormatters.price(value);

  static DateFormat _axisTimeFormat(ChartRange range) => switch (range) {
    ChartRange.day => DateFormat.Hm('en_US'), // 14:00
    ChartRange.week || ChartRange.month => DateFormat.MMMd('en_US'), // Oct 23
    ChartRange.year => DateFormat.MMM('en_US'), // Oct
  };

  static DateFormat _tooltipTimeFormat(ChartRange range) => switch (range) {
    ChartRange.year => DateFormat.yMMMd('en_US'), // Oct 23, 2026
    _ => DateFormat('MMM d, HH:mm', 'en_US'), // Oct 23, 14:00
  };
}

class _NotEnoughData extends StatelessWidget {
  const _NotEnoughData();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: priceChartHeight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Not enough price history for this range yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
