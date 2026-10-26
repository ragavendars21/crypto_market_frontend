import 'coin_summary.dart';
import 'market_query.dart';

/// Returns a new list of [coins] in [sort] order.
///
/// Coins missing the sorted value always go last, in either direction, so
/// "unknown" never shows up as "lowest". Used for client-side sorting (the
/// watchlist) and by the mock repository, which mirrors the backend.
List<CoinSummary> sortCoins(Iterable<CoinSummary> coins, MarketSort sort) {
  return [...coins]..sort((a, b) => _compare(a, b, sort));
}

int _compare(CoinSummary a, CoinSummary b, MarketSort sort) {
  final (valueA, valueB, descending) = switch (sort) {
    MarketSort.marketCapDesc => (a.marketCapUsd, b.marketCapUsd, true),
    MarketSort.marketCapAsc => (a.marketCapUsd, b.marketCapUsd, false),
    MarketSort.priceDesc => (a.priceUsd, b.priceUsd, true),
    MarketSort.priceAsc => (a.priceUsd, b.priceUsd, false),
    MarketSort.change24hDesc => (
      a.priceChangePercentage24h,
      b.priceChangePercentage24h,
      true,
    ),
    MarketSort.change24hAsc => (
      a.priceChangePercentage24h,
      b.priceChangePercentage24h,
      false,
    ),
    MarketSort.volumeDesc => (a.totalVolumeUsd, b.totalVolumeUsd, true),
    MarketSort.volumeAsc => (a.totalVolumeUsd, b.totalVolumeUsd, false),
  };

  if (valueA == null && valueB == null) return 0;
  if (valueA == null) return 1;
  if (valueB == null) return -1;
  return descending ? valueB.compareTo(valueA) : valueA.compareTo(valueB);
}
