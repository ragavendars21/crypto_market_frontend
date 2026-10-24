import 'package:crypto_market/features/coin_details/data/dtos/price_history_dto.dart';
import 'package:crypto_market/features/coin_details/domain/price_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PriceHistoryDto', () {
    test('drops points without a price and sorts oldest first', () {
      final history = PriceHistoryDto.fromJson({
        'coinId': 'bitcoin',
        'range': '7d',
        'granularity': 'hourly',
        'points': [
          {'timestamp': 3000, 'priceUsd': 103},
          {'timestamp': 1000, 'priceUsd': 100},
          {'timestamp': 2000, 'priceUsd': null},
        ],
      }).toDomain();

      expect(history.range, ChartRange.week);
      expect(history.points.map((p) => p.priceUsd), [100, 103]);
      expect(history.points.first.time.isUtc, isTrue);
    });

    test('rejects an unknown range instead of guessing', () {
      final dto = PriceHistoryDto.fromJson({
        'coinId': 'bitcoin',
        'range': 'max',
        'points': <Object>[],
      });

      expect(dto.toDomain, throwsFormatException);
    });
  });

  group('PriceHistory', () {
    PriceHistory historyOf(List<double> prices) => PriceHistory(
      range: ChartRange.day,
      points: [
        for (var i = 0; i < prices.length; i++)
          PricePoint(
            time: DateTime.utc(2026).add(Duration(minutes: 5 * i)),
            priceUsd: prices[i],
          ),
      ],
    );

    test('computes change, direction and price extremes', () {
      final history = historyOf([100, 120, 90, 110]);

      expect(history.hasEnoughData, isTrue);
      expect(history.changePercentage, closeTo(10, 0.0001));
      expect(history.isUp, isTrue);
      expect(history.lowestPrice, 90);
      expect(history.highestPrice, 120);
    });

    test('reports insufficient data instead of a misleading change', () {
      expect(historyOf([]).hasEnoughData, isFalse);
      expect(historyOf([]).lowestPrice, isNull);
      expect(historyOf([42]).hasEnoughData, isFalse);
      expect(historyOf([42]).changePercentage, isNull);
    });

    test('marks a falling range as down', () {
      expect(historyOf([100, 80]).isUp, isFalse);
    });
  });
}
