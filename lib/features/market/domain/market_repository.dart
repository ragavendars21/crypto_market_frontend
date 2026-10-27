import 'coin_page.dart';
import 'coin_summary.dart';
import 'market_query.dart';

abstract interface class MarketRepository {
  static const int defaultPageSize = 20;

  Future<CoinPage> getCoins({
    required MarketQuery query,
    int page = 1,
    int perPage = defaultPageSize,
  });

  Future<List<CoinSummary>> getCoinsByIds(List<String> ids);
}
