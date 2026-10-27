import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

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

  final Widget? footer;

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
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: footer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
