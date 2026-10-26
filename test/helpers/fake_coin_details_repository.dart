import 'package:crypto_market/features/coin_details/data/mock_coin_details_repository.dart';
import 'package:crypto_market/features/coin_details/domain/coin_details.dart';
import 'package:crypto_market/features/coin_details/domain/coin_details_repository.dart';
import 'package:crypto_market/features/coin_details/domain/price_history.dart';

/// Serves the realistic mock data, but records history requests and can be
/// told to fail, so tests can check caching and error handling.
class FakeCoinDetailsRepository implements CoinDetailsRepository {
  final _mock = MockCoinDetailsRepository(latency: Duration.zero);

  Object? failNextDetailsWith;
  Object? failNextHistoryWith;
  final List<ChartRange> historyRequests = [];

  @override
  Future<CoinDetails> getCoinDetails(String coinId) async {
    final failure = failNextDetailsWith;
    if (failure != null) {
      failNextDetailsWith = null;
      throw failure;
    }
    return _mock.getCoinDetails(coinId);
  }

  @override
  Future<PriceHistory> getPriceHistory(String coinId, ChartRange range) async {
    historyRequests.add(range);
    final failure = failNextHistoryWith;
    if (failure != null) {
      failNextHistoryWith = null;
      throw failure;
    }
    return _mock.getPriceHistory(coinId, range);
  }
}
