import 'global_market_stats.dart';

abstract interface class MarketStatsRepository {
  Future<GlobalMarketStats> getGlobalStats();
}
