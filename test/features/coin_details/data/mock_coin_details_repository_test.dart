import 'package:crypto_market/core/errors/app_failure.dart';
import 'package:crypto_market/features/coin_details/data/mock_coin_details_repository.dart';
import 'package:crypto_market/features/coin_details/domain/price_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repository = MockCoinDetailsRepository(latency: Duration.zero);

  group('getCoinDetails', () {
    test('returns details for a known coin', () async {
      final details = await repository.getCoinDetails('bitcoin');

      expect(details.name, 'Bitcoin');
      expect(details.maxSupply, 21000000);
      expect(details.allTimeHigh?.priceUsd, isNotNull);
    });

    test('leaves values unknown for coins without extra sample data', () async {
      final details = await repository.getCoinDetails('dogecoin');

      expect(details.priceUsd, isNotNull);
      expect(details.maxSupply, isNull);
      expect(details.allTimeHigh, isNull);
    });

    test('throws NotFoundFailure for an unknown coin', () {
      expect(
        repository.getCoinDetails('not-a-coin'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('getPriceHistory', () {
    test('matches the provider granularity for each range', () async {
      final expectedCounts = {
        ChartRange.day: 288,
        ChartRange.week: 168,
        ChartRange.month: 720,
        ChartRange.year: 365,
      };

      for (final MapEntry(key: range, value: count) in expectedCounts.entries) {
        final history = await repository.getPriceHistory('bitcoin', range);
        expect(history.points, hasLength(count), reason: range.label);
        expect(history.range, range);
      }
    });

    test('is deterministic and ends at the current price', () async {
      final first = await repository.getPriceHistory('solana', ChartRange.week);
      final second = await repository.getPriceHistory(
        'solana',
        ChartRange.week,
      );
      final details = await repository.getCoinDetails('solana');

      expect(
        first.points.map((p) => p.priceUsd),
        second.points.map((p) => p.priceUsd),
      );
      expect(first.points.last.priceUsd, details.priceUsd);
    });

    test('a newly listed coin lacks data for longer ranges', () async {
      final day = await repository.getPriceHistory(
        'sample-new-coin',
        ChartRange.day,
      );
      final year = await repository.getPriceHistory(
        'sample-new-coin',
        ChartRange.year,
      );

      expect(day.hasEnoughData, isTrue);
      expect(day.points.length, lessThan(288));
      expect(year.hasEnoughData, isFalse);
    });

    test('throws NotFoundFailure for an unknown coin', () {
      expect(
        repository.getPriceHistory('not-a-coin', ChartRange.day),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });
}
