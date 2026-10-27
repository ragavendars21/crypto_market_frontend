class CoinSummary {
  const CoinSummary({
    required this.id,
    required this.symbol,
    required this.name,
    this.imageUrl,
    this.marketCapRank,
    this.priceUsd,
    this.priceChange24hUsd,
    this.priceChangePercentage24h,
    this.marketCapUsd,
    this.totalVolumeUsd,
    this.circulatingSupply,
    this.lastUpdated,
  });

  final String id;

  final String symbol;
  final String name;
  final String? imageUrl;
  final int? marketCapRank;
  final double? priceUsd;
  final double? priceChange24hUsd;
  final double? priceChangePercentage24h;
  final double? marketCapUsd;
  final double? totalVolumeUsd;
  final double? circulatingSupply;
  final DateTime? lastUpdated;

  String get displaySymbol => symbol.toUpperCase();
}
