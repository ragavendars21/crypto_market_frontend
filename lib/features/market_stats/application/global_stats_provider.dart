import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/repository_providers.dart';
import '../domain/global_market_stats.dart';

/// Global market statistics, shared by the market overview strip and the
/// Global screen. Both read the same provider, so one request serves both.
final globalStatsProvider = FutureProvider<GlobalMarketStats>((ref) {
  return ref.watch(marketStatsRepositoryProvider).getGlobalStats();
});
