import '../../../core/mock/mock_market_data.dart';
import '../domain/coin_page.dart';
import '../domain/coin_summary.dart';
import '../domain/market_query.dart';
import '../domain/market_repository.dart';
import '../domain/market_sorting.dart';
import 'dtos/coin_summary_dto.dart';

/// Offline [MarketRepository] backed by sample data.
///
/// It applies search, filters, sorting and pagination the same way the
/// backend does (docs/api-contract.md), so the UI behaves identically in
/// mock and live mode. A small artificial delay makes loading states visible.
class MockMarketRepository implements MarketRepository {
  MockMarketRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  // Parsed with the same DTO as live responses, so mock mode also
  // exercises the JSON mapping code.
  late final List<CoinSummary> _allCoins = mockCoinSummariesJson
      .map((json) => CoinSummaryDto.fromJson(json).toDomain())
      .toList(growable: false);

  @override
  Future<CoinPage> getCoins({
    required MarketQuery query,
    int page = 1,
    int perPage = MarketRepository.defaultPageSize,
  }) async {
    if (page < 1 || perPage < 1) {
      throw ArgumentError('page and perPage must be at least 1');
    }
    await Future<void>.delayed(latency);

    final matching = sortCoins(
      _allCoins
          .where((coin) => _matchesSearch(coin, query.trimmedSearch))
          .where((coin) => _matchesMovement(coin, query.movement))
          .where((coin) => _matchesTier(coin, query.tier)),
      query.sort,
    );

    final start = (page - 1) * perPage;
    final pageCoins = matching.skip(start).take(perPage).toList();

    return CoinPage(
      coins: pageCoins,
      page: page,
      totalItems: matching.length,
      hasNextPage: start + perPage < matching.length,
    );
  }

  @override
  Future<List<CoinSummary>> getCoinsByIds(List<String> ids) async {
    await Future<void>.delayed(latency);
    final wanted = ids.toSet();
    return _allCoins.where((coin) => wanted.contains(coin.id)).toList();
  }

  static bool _matchesSearch(CoinSummary coin, String search) {
    if (search.isEmpty) return true;
    final term = search.toLowerCase();
    return coin.name.toLowerCase().contains(term) ||
        coin.symbol.toLowerCase().contains(term);
  }

  static bool _matchesMovement(CoinSummary coin, MarketMovement movement) {
    final change = coin.priceChangePercentage24h;
    return switch (movement) {
      MarketMovement.all => true,
      MarketMovement.gainers => change != null && change > 0,
      MarketMovement.losers => change != null && change < 0,
    };
  }

  static bool _matchesTier(CoinSummary coin, MarketCapTier tier) {
    final cap = coin.marketCapUsd;
    if (tier == MarketCapTier.all) return true;
    if (cap == null) return false;
    return switch (tier) {
      MarketCapTier.all => true,
      MarketCapTier.large => cap >= MarketCapTier.largeCapMinimumUsd,
      MarketCapTier.mid =>
        cap >= MarketCapTier.midCapMinimumUsd &&
            cap < MarketCapTier.largeCapMinimumUsd,
      MarketCapTier.small => cap < MarketCapTier.midCapMinimumUsd,
    };
  }
}
