import 'package:crypto_market/features/market/data/mock_market_repository.dart';
import 'package:crypto_market/features/market/domain/market_query.dart';
import 'package:crypto_market/features/market/presentation/widgets/coin_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_market_repository.dart';
import '../../../helpers/pump_app.dart';

MockMarketRepository _realisticRepository() =>
    MockMarketRepository(latency: Duration.zero);

List<String> _visibleCoinIds(WidgetTester tester) => tester
    .widgetList<CoinListTile>(find.byType(CoinListTile))
    .map((tile) => tile.coin.id)
    .toList();

Future<void> _tapChip(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(FilterChip, label);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('waits for typing to pause before searching', (tester) async {
    final repository = FakeMarketRepository();
    await pumpApp(tester, marketRepository: repository);

    for (final text in ['e', 'et', 'eth']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(repository.requests, hasLength(1), reason: 'only the first load');

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(repository.requests, hasLength(2));
    expect(repository.requests.last.query.search, 'eth');
  });

  testWidgets('search narrows the list and can be cleared', (tester) async {
    await pumpApp(tester, marketRepository: _realisticRepository());

    await _search(tester, 'SOL');

    expect(_visibleCoinIds(tester), ['solana']);
    expect(find.text('1 result'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(_visibleCoinIds(tester).first, 'bitcoin');
    expect(find.text('1 result'), findsNothing);
  });

  testWidgets('sort sheet changes the order and the chip label', (
    tester,
  ) async {
    await pumpApp(tester, marketRepository: _realisticRepository());

    await tester.tap(find.text(MarketSort.marketCapDesc.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(MarketSort.priceAsc.label));
    await tester.pumpAndSettle();

    expect(find.text(MarketSort.priceAsc.label), findsOneWidget);
    expect(_visibleCoinIds(tester).take(2), ['pepe', 'shiba-inu']);
  });

  testWidgets('dismissing the sort sheet keeps the current order', (
    tester,
  ) async {
    final repository = FakeMarketRepository();
    await pumpApp(tester, marketRepository: repository);

    await tester.tap(find.text(MarketSort.marketCapDesc.label));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(repository.requests, hasLength(1));
  });

  testWidgets('filter chips toggle on and off', (tester) async {
    await pumpApp(tester, marketRepository: _realisticRepository());

    await _tapChip(tester, 'Losers');

    final losers = tester
        .widgetList<CoinListTile>(find.byType(CoinListTile))
        .map((tile) => tile.coin.priceChangePercentage24h);
    expect(losers, everyElement(lessThan(0)));

    await _tapChip(tester, 'Losers');

    expect(_visibleCoinIds(tester).first, 'bitcoin');
  });

  testWidgets('combines search with a market-cap filter', (tester) async {
    await pumpApp(tester, marketRepository: _realisticRepository());

    await _tapChip(tester, 'Mid cap');
    await _search(tester, 'coin');

    expect(_visibleCoinIds(tester), ['bitcoin-cash', 'litecoin']);
    expect(find.text('2 results'), findsOneWidget);
  });

  testWidgets('empty results explain the scope and offer a reset', (
    tester,
  ) async {
    await pumpApp(tester, marketRepository: _realisticRepository());
    await _tapChip(tester, 'Small cap');

    await _search(tester, 'zzzz');

    expect(find.text('No results for "zzzz"'), findsOneWidget);
    expect(find.textContaining('top 250 coins'), findsOneWidget);

    await tester.tap(find.text('Clear search and filters'));
    await tester.pumpAndSettle();

    expect(_visibleCoinIds(tester).first, 'bitcoin');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    final smallCap = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Small cap'),
    );
    expect(smallCap.selected, isFalse);
  });
}
