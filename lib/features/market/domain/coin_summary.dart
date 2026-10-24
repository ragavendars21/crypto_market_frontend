/// One row of the market list.
///
/// Every market value is nullable: the provider does not always supply it
/// (for example, a newly listed coin may have no market cap yet), and the
/// app shows "—" instead of inventing a number.
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

  /// Provider ID used in URLs and API calls, e.g. `bitcoin`.
  final String id;

  /// Ticker in lowercase as supplied, e.g. `btc`. Display with [displaySymbol].
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
