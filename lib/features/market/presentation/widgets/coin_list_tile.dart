import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/formatters/market_formatters.dart';
import '../../../../shared/widgets/coin_logo.dart';
import '../../../../shared/widgets/price_change_indicator.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../domain/coin_summary.dart';

const double _rankWidth = 28;
const double _contentIndent =
    _rankWidth + AppSizes.coinLogoList + AppSpacing.md;

class CoinListTile extends StatelessWidget {
  const CoinListTile({
    super.key,
    required this.coin,
    required this.onTap,
    this.trailing,
  });

  final CoinSummary coin;
  final VoidCallback onTap;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tile = Semantics(
      button: true,
      label: _semanticLabel(),
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            trailing == null ? AppSpacing.lg : AppSpacing.xs,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: _rankWidth,
                    child: Text(
                      coin.marketCapRank?.toString() ??
                          MarketFormatters.notAvailable,
                      style: theme.textTheme.labelSmall?.tabular,
                    ),
                  ),
                  CoinLogo(
                    imageUrl: coin.imageUrl,
                    symbol: coin.symbol,
                    size: AppSizes.coinLogoList,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _NameAndSymbol(coin: coin)),
                  const SizedBox(width: AppSpacing.sm),
                  _PriceAndChange(coin: coin),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(left: _contentIndent),
                child: _MetricsRow(coin: coin),
              ),
            ],
          ),
        ),
      ),
    );

    final trailingAction = trailing;
    if (trailingAction == null) return tile;
    return Row(
      children: [
        Expanded(child: tile),
        trailingAction,
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  String _semanticLabel() {
    String spoken(String text) => text == MarketFormatters.notAvailable
        ? MarketFormatters.notAvailableLabel
        : text;

    final change = coin.priceChangePercentage24h;
    final changeText = change == null
        ? '24 hour change not available'
        : '${change >= 0 ? 'up' : 'down'} '
              '${change.abs().toStringAsFixed(2)} percent in 24 hours';
    final rank = coin.marketCapRank == null
        ? ''
        : ', rank ${coin.marketCapRank}';

    return '${coin.name}, ${coin.displaySymbol}$rank. '
        'Price ${spoken(MarketFormatters.price(coin.priceUsd))}, $changeText. '
        'Market cap ${spoken(MarketFormatters.compactCurrency(coin.marketCapUsd))}. '
        'Volume ${spoken(MarketFormatters.compactCurrency(coin.totalVolumeUsd))}. '
        'Circulating supply '
        '${spoken(MarketFormatters.supply(coin.circulatingSupply, coin.symbol))}.';
  }
}

class _NameAndSymbol extends StatelessWidget {
  const _NameAndSymbol({required this.coin});

  final CoinSummary coin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          coin.name,
          style: theme.textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(coin.displaySymbol, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _PriceAndChange extends StatelessWidget {
  const _PriceAndChange({required this.coin});

  final CoinSummary coin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 130),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              MarketFormatters.price(coin.priceUsd),
              style: Theme.of(context).textTheme.titleMedium?.tabular,
            ),
          ),
        ),
        const SizedBox(height: 2),
        PriceChangeIndicator(
          percentage: coin.priceChangePercentage24h,
          filled: true,
        ),
      ],
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.coin});

  final CoinSummary coin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Metric(
          label: 'Mkt cap',
          value: MarketFormatters.compactCurrency(coin.marketCapUsd),
        ),
        _Metric(
          label: 'Vol 24h',
          value: MarketFormatters.compactCurrency(coin.totalVolumeUsd),
        ),
        _Metric(
          label: 'Supply',
          value: MarketFormatters.supply(coin.circulatingSupply, coin.symbol),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          Text(
            value,
            style: theme.textTheme.labelMedium?.tabular,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class CoinListTileSkeleton extends StatelessWidget {
  const CoinListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: _rankWidth),
              SkeletonBox(
                width: AppSizes.coinLogoList,
                height: AppSizes.coinLogoList,
                radius: AppSizes.coinLogoList / 2,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 110, height: 14),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonBox(width: 40, height: 10),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SkeletonBox(width: 80, height: 14),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonBox(width: 56, height: 18),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.only(left: _contentIndent),
            child: Row(
              children: [
                Expanded(child: SkeletonBox(width: 60, height: 22)),
                SizedBox(width: AppSpacing.lg),
                Expanded(child: SkeletonBox(width: 60, height: 22)),
                SizedBox(width: AppSpacing.lg),
                Expanded(child: SkeletonBox(width: 60, height: 22)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
