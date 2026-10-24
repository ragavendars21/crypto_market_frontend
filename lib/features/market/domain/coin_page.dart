import 'coin_summary.dart';

/// One page of market results plus what's needed for infinite scrolling.
class CoinPage {
  const CoinPage({
    required this.coins,
    required this.page,
    required this.totalItems,
    required this.hasNextPage,
    this.isStale = false,
  });

  final List<CoinSummary> coins;
  final int page;

  /// Number of coins matching the query across all pages.
  final int totalItems;
  final bool hasNextPage;

  /// True when the backend could not reach the provider and served its last
  /// cached copy. The UI shows a "prices may be out of date" banner.
  final bool isStale;
}
