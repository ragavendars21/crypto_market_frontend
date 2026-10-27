class DominanceEntry {
  const DominanceEntry({required this.symbol, required this.percentage});

  final String symbol;
  final double percentage;

  String get displaySymbol => symbol.toUpperCase();
}

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

  final int? markets;

  final List<DominanceEntry> dominance;
  final DateTime? updatedAt;

  double? get othersDominance {
    if (dominance.isEmpty) return null;
    final listed = dominance.fold<double>(0, (sum, e) => sum + e.percentage);
    final others = 100 - listed;
    return others > 0 ? others : 0;
  }

  double? get bitcoinDominance {
    for (final entry in dominance) {
      if (entry.symbol == 'btc') return entry.percentage;
    }
    return null;
  }
}
