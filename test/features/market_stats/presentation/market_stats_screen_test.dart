import 'package:crypto_market/core/errors/app_failure.dart';
import 'package:crypto_market/core/theme/app_colors.dart';
import 'package:crypto_market/core/theme/app_theme.dart';
import 'package:crypto_market/features/market_stats/data/mock_market_stats_repository.dart';
import 'package:crypto_market/features/market_stats/domain/global_market_stats.dart';
import 'package:crypto_market/features/market_stats/domain/market_stats_repository.dart';
import 'package:crypto_market/features/market_stats/presentation/widgets/dominance_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

/// Fails the first request, then serves the sample data.
class _FlakyStatsRepository implements MarketStatsRepository {
  final _mock = MockMarketStatsRepository(latency: Duration.zero);
  bool _failed = false;

  @override
  Future<GlobalMarketStats> getGlobalStats() async {
    if (!_failed) {
      _failed = true;
      throw const NetworkFailure();
    }
    return _mock.getGlobalStats();
  }
}

Future<void> _openGlobal(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Global'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the headline numbers and counts', (tester) async {
    await pumpApp(tester);
    await _openGlobal(tester);

    expect(find.text('Total crypto market cap'), findsOneWidget);
    expect(find.text(r'$2.41T'), findsOneWidget);
    expect(find.text('17,321'), findsOneWidget);
    expect(find.text('1,287'), findsOneWidget);
  });

  testWidgets('dominance legend names every segment, including Others', (
    tester,
  ) async {
    await pumpApp(tester);
    await _openGlobal(tester);
    await tester.scrollUntilVisible(
      find.text('Others'),
      200,
      scrollable: find.byType(Scrollable).last,
    );

    for (final label in ['BTC', 'ETH', 'USDT', 'BNB', 'SOL', 'Others']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('54.8%'), findsWidgets);
    // 100 - (54.8 + 16.4 + 4.9 + 3.6 + 3.4) = 16.9
    expect(find.text('16.9%'), findsOneWidget);
  });

  testWidgets('an error offers retry', (tester) async {
    await pumpApp(tester, marketStatsRepository: _FlakyStatsRepository());
    await _openGlobal(tester);

    expect(find.text('No connection'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Total crypto market cap'), findsOneWidget);
  });

  testWidgets('a coin keeps its color when the ranking changes', (
    tester,
  ) async {
    Future<Color?> legendColorOf(List<DominanceEntry> dominance) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DominanceBar(stats: GlobalMarketStats(dominance: dominance)),
          ),
        ),
      );
      final swatch = find.descendant(
        of: find.ancestor(of: find.text('ETH'), matching: find.byType(Row)),
        matching: find.byType(Container),
      );
      final decoration =
          tester.widget<Container>(swatch.first).decoration! as BoxDecoration;
      return decoration.color;
    }

    final normal = await legendColorOf(const [
      DominanceEntry(symbol: 'btc', percentage: 50),
      DominanceEntry(symbol: 'eth', percentage: 20),
    ]);
    final reordered = await legendColorOf(const [
      DominanceEntry(symbol: 'eth', percentage: 50),
      DominanceEntry(symbol: 'btc', percentage: 20),
    ]);

    expect(normal, AppColors.light.chartSeries[1]);
    expect(reordered, normal);
  });
}
