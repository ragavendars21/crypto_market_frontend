import 'dart:math' as math;

import '../../../core/errors/app_failure.dart';
import '../../../core/mock/mock_market_data.dart';
import '../domain/coin_details.dart';
import '../domain/coin_details_repository.dart';
import '../domain/price_history.dart';
import 'dtos/coin_details_dto.dart';
import 'dtos/price_history_dto.dart';

/// Offline [CoinDetailsRepository] backed by sample data.
///
/// Price history is a generated random walk that ends at the coin's sample
/// price. It is seeded from the coin ID and range, so the same chart is
/// produced every time (important for tests and screenshots).
class MockCoinDetailsRepository implements CoinDetailsRepository {
  MockCoinDetailsRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  /// The sample "new coin" only has an hour of history, which exercises the
  /// chart's "not enough data" state on longer ranges.
  static const _listingAge = {'sample-new-coin': Duration(hours: 1)};

  @override
  Future<CoinDetails> getCoinDetails(String coinId) async {
    await Future<void>.delayed(latency);
    final json = mockCoinDetailsJson(coinId);
    if (json == null) throw const NotFoundFailure();
    return CoinDetailsDto.fromJson(json).toDomain();
  }

  @override
  Future<PriceHistory> getPriceHistory(String coinId, ChartRange range) async {
    await Future<void>.delayed(latency);
    final json = mockCoinDetailsJson(coinId);
    if (json == null) throw const NotFoundFailure();

    final points = _generatePoints(
      coinId: coinId,
      range: range,
      currentPrice: json['priceUsd'] as double?,
    );
    return PriceHistoryDto.fromJson({
      'coinId': coinId,
      'range': range.apiValue,
      'points': points,
    }).toDomain();
  }

  List<Map<String, Object?>> _generatePoints({
    required String coinId,
    required ChartRange range,
    required double? currentPrice,
  }) {
    if (currentPrice == null) return const [];

    // Mirrors the provider's automatic granularity for each range.
    final (count, step, volatility) = switch (range) {
      ChartRange.day => (288, const Duration(minutes: 5), 0.002),
      ChartRange.week => (168, const Duration(hours: 1), 0.006),
      ChartRange.month => (720, const Duration(hours: 1), 0.006),
      ChartRange.year => (365, const Duration(days: 1), 0.03),
    };

    final random = math.Random(_stableSeed('$coinId:${range.apiValue}'));
    final end = DateTime.parse(mockLastUpdated);
    final listedAt = switch (_listingAge[coinId]) {
      final age? => end.subtract(age),
      null => null,
    };

    // Walk backwards from the current price so the chart ends on it.
    final prices = List<double>.filled(count, currentPrice);
    for (var i = count - 2; i >= 0; i--) {
      final move = (random.nextDouble() * 2 - 1) * volatility;
      prices[i] = prices[i + 1] / (1 + move);
    }

    final points = <Map<String, Object?>>[];
    for (var i = 0; i < count; i++) {
      final time = end.subtract(step * (count - 1 - i));
      if (listedAt != null && time.isBefore(listedAt)) continue;
      points.add({
        'timestamp': time.millisecondsSinceEpoch,
        'priceUsd': prices[i],
      });
    }
    return points;
  }

  /// `String.hashCode` is not guaranteed to be stable across runs or
  /// platforms, so build a simple deterministic seed from the characters.
  static int _stableSeed(String value) =>
      value.codeUnits.fold(17, (hash, unit) => (hash * 31 + unit) & 0x7fffffff);
}
