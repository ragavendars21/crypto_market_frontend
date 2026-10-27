enum ChangePeriod {
  h1('1h', '1H'),
  h24('24h', '24H'),
  d7('7d', '7D'),
  d14('14d', '14D'),
  d30('30d', '30D'),
  d60('60d', '60D'),
  d200('200d', '200D'),
  y1('1y', '1Y');

  const ChangePeriod(this.apiKey, this.label);

  final String apiKey;
  final String label;
}

class PriceExtreme {
  const PriceExtreme({this.priceUsd, this.changePercentage, this.date});

  final double? priceUsd;

  final double? changePercentage;
  final DateTime? date;
}

class CoinDetails {
  const CoinDetails({
    required this.id,
    required this.symbol,
    required this.name,
    required this.priceChangePercentages,
    this.imageUrl,
    this.marketCapRank,
    this.priceUsd,
    this.marketCapUsd,
    this.fullyDilutedValuationUsd,
    this.totalVolumeUsd,
    this.high24hUsd,
    this.low24hUsd,
    this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    this.allTimeHigh,
    this.allTimeLow,
    this.lastUpdated,
  });

  final String id;
  final String symbol;
  final String name;
  final String? imageUrl;
  final int? marketCapRank;
  final double? priceUsd;
  final double? marketCapUsd;
  final double? fullyDilutedValuationUsd;
  final double? totalVolumeUsd;
  final double? high24hUsd;
  final double? low24hUsd;
  final double? circulatingSupply;
  final double? totalSupply;

  final double? maxSupply;

  final Map<ChangePeriod, double?> priceChangePercentages;
  final PriceExtreme? allTimeHigh;
  final PriceExtreme? allTimeLow;
  final DateTime? lastUpdated;

  String get displaySymbol => symbol.toUpperCase();

  double? get priceChangePercentage24h =>
      priceChangePercentages[ChangePeriod.h24];

  double? get circulatingSupplyRatio {
    final circulating = circulatingSupply;
    final max = maxSupply;
    if (circulating == null || max == null || max <= 0) return null;
    return (circulating / max).clamp(0.0, 1.0);
  }
}
