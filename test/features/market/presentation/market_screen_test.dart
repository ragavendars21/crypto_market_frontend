import 'package:crypto_market/core/errors/app_failure.dart';
import 'package:crypto_market/features/market/presentation/widgets/coin_list_tile.dart';
import 'package:crypto_market/shared/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_market_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('shows skeletons while loading, then the coins', (tester) async {
    final repository = FakeMarketRepository(
      delay: const Duration(milliseconds: 300),
    );
    await pumpApp(tester, marketRepository: repository, settle: false);
    await tester.pump();

    expect(find.byType(CoinListTileSkeleton), findsWidgets);
    expect(find.byType(CoinListTile), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(CoinListTileSkeleton), findsNothing);
    // The list is lazy, so only tiles near the viewport are built.
    expect(find.byType(CoinListTile), findsWidgets);
    expect(find.text('Coin 1'), findsOneWidget);
  });

  testWidgets('shows the market overview strip', (tester) async {
    await pumpApp(tester);

    expect(find.text('Market cap'), findsOneWidget);
    expect(find.text(r'$2.41T'), findsOneWidget);
    expect(find.text('BTC dominance'), findsOneWidget);
    expect(find.text('54.8%'), findsOneWidget);
  });

  testWidgets('shows an error with retry that recovers', (tester) async {
    final repository = FakeMarketRepository()
      ..failNextRequestWith = const NetworkFailure();
    await pumpApp(tester, marketRepository: repository);

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('No connection'), findsOneWidget);
    expect(find.text(const NetworkFailure().message), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Coin 1'), findsOneWidget);
  });

  testWidgets('hides unexpected exception details from the user', (
    tester,
  ) async {
    final repository = FakeMarketRepository()
      ..failNextRequestWith = StateError('database exploded at line 42');
    await pumpApp(tester, marketRepository: repository);

    expect(find.textContaining('line 42'), findsNothing);
    expect(
      find.textContaining('Something unexpected happened'),
      findsOneWidget,
    );
  });

  testWidgets('shows an empty state when there are no coins', (tester) async {
    await pumpApp(tester, marketRepository: FakeMarketRepository(coins: []));

    expect(find.text('No coins match these filters'), findsOneWidget);
    // Nothing to clear, so no reset button is offered.
    expect(find.text('Clear search and filters'), findsNothing);
  });

  testWidgets('loads the next page when scrolling near the end', (
    tester,
  ) async {
    final repository = FakeMarketRepository(coins: testCoins(30));
    await pumpApp(tester, marketRepository: repository);

    await tester.scrollUntilVisible(
      find.textContaining('Showing 30 coins'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(repository.requests.map((r) => r.page), [1, 2]);
    expect(find.textContaining('Data provided by CoinGecko'), findsOneWidget);
  });

  testWidgets('offers a retry row when the next page fails', (tester) async {
    final repository = FakeMarketRepository(coins: testCoins(30));
    await pumpApp(tester, marketRepository: repository);
    repository.failNextRequestWith = const TimeoutFailure();

    await tester.scrollUntilVisible(
      find.textContaining("Couldn't load more coins"),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    // Loaded coins stay, and scrolling did not keep retrying by itself.
    expect(find.text('Coin 20'), findsOneWidget);
    expect(repository.requests.map((r) => r.page), [1, 2]);

    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Coin 30'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Coin 30'), findsOneWidget);
  });

  testWidgets('shows a banner when prices come from the backend cache', (
    tester,
  ) async {
    await pumpApp(
      tester,
      marketRepository: FakeMarketRepository(isStale: true),
    );

    expect(find.byType(StaleDataBanner), findsOneWidget);
  });

  testWidgets('pull to refresh reloads the list', (tester) async {
    final repository = FakeMarketRepository();
    await pumpApp(tester, marketRepository: repository);
    repository.coins = [testCoin(1, name: 'Refreshed Coin')];

    await tester.fling(find.text('Coin 1'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Refreshed Coin'), findsOneWidget);
    expect(repository.requests, hasLength(2));
  });

  testWidgets('tapping a coin opens its details', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Coin 2'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'coin-2'), findsOneWidget);
  });
}
