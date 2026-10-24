/// One coin's share of the total crypto market cap.
class DominanceEntry {
  const DominanceEntry({required this.symbol, required this.percentage});

  final String symbol;
  final double percentage;

  String get displaySymbol => symbol.toUpperCase();
}

/// Market-wide statistics for the Global screen.
class GlobalMarketStats {
  const GlobalMarketStats({
    required this.dominance,
    this.totalMarketCapUsd,
    this.totalVolumeUsd,
    this.marketCapChangePercentage24h,
    this.volumeChangePercentage24h,
    this.activeCryptocurrencies,
    this.markets,
    this.updatedAt,
  });

  final double? totalMarketCapUsd;
  final double? totalVolumeUsd;
  final double? marketCapChangePercentage24h;
  final double? volumeChangePercentage24h;
  final int? activeCryptocurrencies;

  /// Number of exchanges tracked by the provider.
  final int? markets;

  /// Largest first, as returned by the backend (usually the top 10).
  final List<DominanceEntry> dominance;
  final DateTime? updatedAt;

  /// Share of every coin not listed in [dominance], so a chart can show an
  /// "Others" slice that makes the total 100%. `null` if there is no data.
  double? get othersDominance {
    if (dominance.isEmpty) return null;
    final listed = dominance.fold<double>(0, (sum, e) => sum + e.percentage);
    final others = 100 - listed;
    return others > 0 ? others : 0;
  }

  /// Bitcoin's share, highlighted on the market screen.
  double? get bitcoinDominance {
    for (final entry in dominance) {
      if (entry.symbol == 'btc') return entry.percentage;
    }
    return null;
  }
}
