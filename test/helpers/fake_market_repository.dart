import 'package:crypto_market/features/market/domain/coin_page.dart';
import 'package:crypto_market/features/market/domain/coin_summary.dart';
import 'package:crypto_market/features/market/domain/market_query.dart';
import 'package:crypto_market/features/market/domain/market_repository.dart';

/// Builds a coin with predictable values: coin 1 is the largest.
CoinSummary testCoin(
  int number, {
  double? priceUsd,
  double? priceChangePercentage24h = 1.5,
  double? marketCapUsd,
  String? name,
}) {
  return CoinSummary(
    id: 'coin-$number',
    symbol: 'c$number',
    name: name ?? 'Coin $number',
    marketCapRank: number,
    priceUsd: priceUsd ?? 1000.0 / number,
    priceChangePercentage24h: priceChangePercentage24h,
    marketCapUsd: marketCapUsd ?? 1e9 / number,
    totalVolumeUsd: 1e8 / number,
    circulatingSupply: 1e6,
  );
}

List<CoinSummary> testCoins(int count) => [
  for (var i = 1; i <= count; i++) testCoin(i),
];

/// Hand-written fake: serves [coins] page by page, records every request
/// and can be told to fail, so tests control each scenario precisely.
class FakeMarketRepository implements MarketRepository {
  FakeMarketRepository({
    List<CoinSummary>? coins,
    this.delay = Duration.zero,
    this.isStale = false,
  }) : coins = coins ?? testCoins(5);

  List<CoinSummary> coins;
  Duration delay;
  bool isStale;

  /// When set, the next request throws this and the field is cleared.
  Object? failNextRequestWith;

  final List<({MarketQuery query, int page})> requests = [];

  @override
  Future<CoinPage> getCoins({
    required MarketQuery query,
    int page = 1,
    int perPage = MarketRepository.defaultPageSize,
  }) async {
    requests.add((query: query, page: page));
    await Future<void>.delayed(delay);

    final failure = failNextRequestWith;
    if (failure != null) {
      failNextRequestWith = null;
      throw failure;
    }

    final start = (page - 1) * perPage;
    return CoinPage(
      coins: coins.skip(start).take(perPage).toList(),
      page: page,
      totalItems: coins.length,
      hasNextPage: start + perPage < coins.length,
      isStale: isStale,
    );
  }

  @override
  Future<List<CoinSummary>> getCoinsByIds(List<String> ids) async {
    await Future<void>.delayed(delay);
    return coins.where((coin) => ids.contains(coin.id)).toList();
  }
}
