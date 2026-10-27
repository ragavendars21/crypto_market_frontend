import 'package:crypto_market/features/market/domain/coin_page.dart';
import 'package:crypto_market/features/market/domain/coin_summary.dart';
import 'package:crypto_market/features/market/domain/market_query.dart';
import 'package:crypto_market/features/market/domain/market_repository.dart';

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

class FakeMarketRepository implements MarketRepository {
  FakeMarketRepository({
    List<CoinSummary>? coins,
    this.delay = Duration.zero,
    this.isStale = false,
  }) : coins = coins ?? testCoins(5);

  List<CoinSummary> coins;
  Duration delay;
  bool isStale;

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

  final List<List<String>> idsRequests = [];

  @override
  Future<List<CoinSummary>> getCoinsByIds(List<String> ids) async {
    idsRequests.add(ids);
    await Future<void>.delayed(delay);

    final failure = failNextRequestWith;
    if (failure != null) {
      failNextRequestWith = null;
      throw failure;
    }
    return coins.where((coin) => ids.contains(coin.id)).toList();
  }
}
