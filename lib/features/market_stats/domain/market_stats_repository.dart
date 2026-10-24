import 'global_market_stats.dart';

/// Contract for loading global market statistics.
abstract interface class MarketStatsRepository {
  Future<GlobalMarketStats> getGlobalStats();
}
