import 'coin_details.dart';
import 'price_history.dart';

/// Contract for the coin details screen. Implementations throw
/// [AppFailure] subtypes, e.g. `NotFoundFailure` for an unknown coin ID.
abstract interface class CoinDetailsRepository {
  Future<CoinDetails> getCoinDetails(String coinId);

  Future<PriceHistory> getPriceHistory(String coinId, ChartRange range);
}
