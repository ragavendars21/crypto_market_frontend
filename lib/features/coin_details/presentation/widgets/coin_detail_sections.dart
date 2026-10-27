import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/formatters/market_formatters.dart';
import '../../../../shared/widgets/coin_logo.dart';
import '../../../../shared/widgets/price_change_indicator.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/coin_details.dart';

class CoinPriceHeader extends StatelessWidget {
  const CoinPriceHeader({super.key, required this.details});

  final CoinDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rank = details.marketCapRank;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CoinLogo(
              imageUrl: details.imageUrl,
              symbol: details.symbol,
              size: AppSizes.coinLogoHeader,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    details.name,
                    style: theme.textTheme.headlineSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      _Badge(text: details.displaySymbol),
                      if (rank != null)
                        _Badge(
                          text: 'Rank #$rank',
                          semanticsLabel: 'Market cap rank $rank',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            MarketFormatters.price(details.priceUsd),
            style: theme.textTheme.displaySmall?.tabular,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            PriceChangeIndicator(
              percentage: details.priceChangePercentage24h,
              periodLabel: 'in 24 hours',
              filled: true,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('24h', style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.semanticsLabel});

  final String text;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        child: Text(
          text,
          semanticsLabel: semanticsLabel,
          style: theme.textTheme.labelMedium,
        ),
      ),
    );
  }
}

class DetailSectionCard extends StatelessWidget {
  const DetailSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [SectionHeader(title), ...children],
        ),
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMissing = value == MarketFormatters.notAvailable;

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  semanticsLabel: isMissing
                      ? MarketFormatters.notAvailableLabel
                      : null,
                  style: theme.textTheme.bodyLarge?.tabular.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PerformanceGrid extends StatelessWidget {
  const PerformanceGrid({super.key, required this.changes});

  final Map<ChangePeriod, double?> changes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 8 : 4;
        final cellWidth =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.md,
          children: [
            for (final period in ChangePeriod.values)
              SizedBox(
                width: cellWidth,
                child: MergeSemantics(
                  child: Column(
                    children: [
                      Text(period.label, style: theme.textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.xs),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: PriceChangeIndicator(
                          percentage: changes[period],
                          periodLabel: 'over ${period.label}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class SupplySection extends StatelessWidget {
  const SupplySection({super.key, required this.details});

  final CoinDetails details;

  @override
  Widget build(BuildContext context) {
    final ratio = details.circulatingSupplyRatio;
    final theme = Theme.of(context);

    return DetailSectionCard(
      title: 'Supply',
      children: [
        StatRow(
          label: 'Circulating supply',
          value: MarketFormatters.supply(
            details.circulatingSupply,
            details.symbol,
          ),
        ),
        StatRow(
          label: 'Total supply',
          value: MarketFormatters.supply(details.totalSupply, details.symbol),
        ),
        StatRow(
          label: 'Max supply',
          value: details.maxSupply == null
              ? 'No fixed cap'
              : MarketFormatters.supply(details.maxSupply, details.symbol),
        ),
        if (ratio != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label:
                '${(ratio * 100).toStringAsFixed(1)} percent of max supply '
                'in circulation',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  child: LinearProgressIndicator(value: ratio, minHeight: 8),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${(ratio * 100).toStringAsFixed(1)}% of max supply '
                  'in circulation',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class PriceExtremesSection extends StatelessWidget {
  const PriceExtremesSection({super.key, required this.details});

  final CoinDetails details;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      title: 'All-time high and low',
      children: [
        _ExtremeRow(label: 'All-time high', extreme: details.allTimeHigh),
        const Divider(height: AppSpacing.xl),
        _ExtremeRow(label: 'All-time low', extreme: details.allTimeLow),
      ],
    );
  }
}

class _ExtremeRow extends StatelessWidget {
  const _ExtremeRow({required this.label, required this.extreme});

  final String label;
  final PriceExtreme? extreme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = extreme;

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  MarketFormatters.date(value?.date),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MarketFormatters.price(value?.priceUsd),
                semanticsLabel: value?.priceUsd == null
                    ? MarketFormatters.notAvailableLabel
                    : null,
                style: theme.textTheme.bodyLarge?.tabular.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (value?.changePercentage != null)
                PriceChangeIndicator(
                  percentage: value!.changePercentage,
                  periodLabel: 'from $label',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
