import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// A labelled statistic, e.g. "Market cap / $2.41T / ▲ 1.42%".
/// Used in the market overview strip and on the Global screen.
class MarketStatCard extends StatelessWidget {
  const MarketStatCard({
    super.key,
    required this.label,
    required this.value,
    this.footer,
    this.semanticValue,
  });

  final String label;
  final String value;

  /// Optional line under the value, typically a [PriceChangeIndicator].
  final Widget? footer;

  /// Spoken instead of [value] when the visible text is abbreviated.
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            // Scale long values down instead of overflowing small cards.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                semanticsLabel: semanticValue,
                style: theme.textTheme.titleMedium?.tabular,
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.xs),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
