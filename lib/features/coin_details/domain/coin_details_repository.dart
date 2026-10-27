import 'coin_details.dart';
import 'price_history.dart';

abstract interface class CoinDetailsRepository {
  Future<CoinDetails> getCoinDetails(String coinId);

  Future<PriceHistory> getPriceHistory(String coinId, ChartRange range);
}
