/// Sort options supported by `GET /api/v1/coins?sort=...`.
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

  /// Value sent to the backend.
  final String apiValue;

  /// Text shown in the UI.
  final String label;
}

/// Filter by direction of the 24h price change.
enum MarketMovement {
  all('All'),
  gainers('Gainers'),
  losers('Losers');

  const MarketMovement(this.label);

  final String label;

  String get apiValue => name;
}

/// Filter by market capitalization bracket.
enum MarketCapTier {
  all('All caps'),
  large('Large cap'),
  mid('Mid cap'),
  small('Small cap');

  const MarketCapTier(this.label);

  final String label;

  String get apiValue => name;

  /// Thresholds shared with the backend (see docs/api-contract.md).
  static const double largeCapMinimumUsd = 10e9;
  static const double midCapMinimumUsd = 1e9;
}

/// Everything that decides which coins the market list shows.
///
/// It is immutable: changing a filter creates a new query with [copyWith].
/// That makes "did the query change?" a simple `==` check, which the
/// market list uses to avoid repeating identical requests.
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
