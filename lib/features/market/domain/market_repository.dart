import 'coin_page.dart';
import 'coin_summary.dart';
import 'market_query.dart';

/// Contract for loading market listings.
///
/// The UI depends on this interface, not on HTTP. The app swaps in either
/// the API implementation or the mock one; tests can use a fake.
/// Implementations throw [AppFailure] subtypes, never raw exceptions.
abstract interface class MarketRepository {
  static const int defaultPageSize = 20;

  /// Search, filter, sort and paginate the market (server-side).
  Future<CoinPage> getCoins({
    required MarketQuery query,
    int page = 1,
    int perPage = defaultPageSize,
  });

  /// Load specific coins, e.g. the watchlist. Unknown IDs are omitted.
  Future<List<CoinSummary>> getCoinsByIds(List<String> ids);
}
