import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../formatters/market_formatters.dart';

class PriceChangeIndicator extends StatelessWidget {
  const PriceChangeIndicator({
    super.key,
    required this.percentage,
    this.periodLabel,
    this.filled = false,
    this.textStyle,
  });

  final double? percentage;

  final String? periodLabel;

  final bool filled;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final raw = percentage;
    final value = raw == null ? null : MarketFormatters.roundedPercentage(raw);
    final color = switch (value) {
      null || 0 => theme.colorScheme.onSurfaceVariant,
      > 0 => context.appColors.positive,
      _ => context.appColors.negative,
    };
    final icon = switch (value) {
      null || 0 => null,
      > 0 => Icons.arrow_drop_up,
      _ => Icons.arrow_drop_down,
    };
    final style = (textStyle ?? theme.textTheme.labelLarge!).tabular.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, size: AppIconSize.md, color: color),
        Text(MarketFormatters.percentage(value), style: style),
      ],
    );

    return Semantics(
      label: _semanticLabel(value),
      excludeSemantics: true,
      child: filled
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  2,
                  AppSpacing.sm,
                  2,
                ),
                child: content,
              ),
            )
          : content,
    );
  }

  String _semanticLabel(double? value) {
    final period = periodLabel == null ? '' : ' $periodLabel';
    if (value == null) return 'Change$period not available';
    final amount = value.abs().toStringAsFixed(2);
    if (value == 0) return 'Unchanged$period';
    return '${value > 0 ? 'Up' : 'Down'} $amount percent$period';
  }
}
