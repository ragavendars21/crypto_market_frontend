import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/repository_providers.dart';
import '../../../core/utils/provider_cache.dart';
import '../domain/coin_details.dart';
import '../domain/price_history.dart';

const _cacheDuration = Duration(minutes: 2);

final coinDetailsProvider = FutureProvider.autoDispose
    .family<CoinDetails, String>((ref, coinId) {
      ref.cacheFor(_cacheDuration);
      return ref.watch(coinDetailsRepositoryProvider).getCoinDetails(coinId);
    });

final priceHistoryProvider = FutureProvider.autoDispose
    .family<PriceHistory, ({String coinId, ChartRange range})>((ref, key) {
      ref.cacheFor(_cacheDuration);
      return ref
          .watch(coinDetailsRepositoryProvider)
          .getPriceHistory(key.coinId, key.range);
    });
