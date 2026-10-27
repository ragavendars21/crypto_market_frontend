enum MarketSort {
  marketCapDesc('market_cap_desc', 'Highest market cap'),
  marketCapAsc('market_cap_asc', 'Lowest market cap'),
  priceDesc('price_desc', 'Highest price'),
  priceAsc('price_asc', 'Lowest price'),
  change24hDesc('change_24h_desc', 'Top gainers (24h)'),
  change24hAsc('change_24h_asc', 'Top losers (24h)'),
  volumeDesc('volume_desc', 'Highest volume'),
  volumeAsc('volume_asc', 'Lowest volume');

  const MarketSort(this.apiValue, this.label);

  final String apiValue;

  final String label;
}

enum MarketMovement {
  all('All'),
  gainers('Gainers'),
  losers('Losers');

  const MarketMovement(this.label);

  final String label;

  String get apiValue => name;
}

enum MarketCapTier {
  all('All caps', 'Any market cap'),
  large('Large cap', 'Market cap of \$10B or more'),
  mid('Mid cap', 'Market cap from \$1B to \$10B'),
  small('Small cap', 'Market cap under \$1B');

  const MarketCapTier(this.label, this.description);

  final String label;

  final String description;

  String get apiValue => name;

  static const double largeCapMinimumUsd = 10e9;
  static const double midCapMinimumUsd = 1e9;
}

class MarketQuery {
  const MarketQuery({
    this.search = '',
    this.sort = MarketSort.marketCapDesc,
    this.movement = MarketMovement.all,
    this.tier = MarketCapTier.all,
  });

  final String search;
  final MarketSort sort;
  final MarketMovement movement;
  final MarketCapTier tier;

  String get trimmedSearch => search.trim();

  bool get hasActiveFilters =>
      movement != MarketMovement.all || tier != MarketCapTier.all;

  bool get isNarrowed => trimmedSearch.isNotEmpty || hasActiveFilters;

  MarketQuery copyWith({
    String? search,
    MarketSort? sort,
    MarketMovement? movement,
    MarketCapTier? tier,
  }) {
    return MarketQuery(
      search: search ?? this.search,
      sort: sort ?? this.sort,
      movement: movement ?? this.movement,
      tier: tier ?? this.tier,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MarketQuery &&
        other.trimmedSearch == trimmedSearch &&
        other.sort == sort &&
        other.movement == movement &&
        other.tier == tier;
  }

  @override
  int get hashCode => Object.hash(trimmedSearch, sort, movement, tier);
}
