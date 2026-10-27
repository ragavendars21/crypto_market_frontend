import 'dart:async';

import 'package:crypto_market/core/routing/app_router.dart';
import 'package:crypto_market/features/market/data/mock_market_repository.dart';
import 'package:crypto_market/features/market/presentation/widgets/coin_list_tile.dart';
import 'package:crypto_market/features/watchlist/presentation/watchlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

const _savedKey = 'watchlist_coin_ids';

MockMarketRepository _market() => MockMarketRepository(latency: Duration.zero);

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Finder _watchlistTiles() => find.descendant(
  of: find.byType(WatchlistScreen),
  matching: find.byType(CoinListTile),
);

void main() {
  testWidgets('empty watchlist explains how to add coins', (tester) async {
    await pumpApp(tester, marketRepository: _market());
    await _openTab(tester, 'Watchlist');

    expect(find.text('Your watchlist is empty'), findsOneWidget);

    await tester.tap(find.text('Explore markets'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Markets'), findsOneWidget);
  });

  testWidgets('starring a coin in the market list adds it to the watchlist', (
    tester,
  ) async {
    await pumpApp(tester, marketRepository: _market());

    await tester.tap(find.byTooltip('Add Bitcoin to watchlist'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove Bitcoin from watchlist'), findsOneWidget);

    await _openTab(tester, 'Watchlist');

    expect(_watchlistTiles(), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(WatchlistScreen),
        matching: find.text('Bitcoin'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the star stays in sync between details and the list', (
    tester,
  ) async {
    final container = await pumpApp(tester, marketRepository: _market());

    unawaited(
      container.read(appRouterProvider).push(AppRoutes.coinDetails('solana')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add Solana to watchlist'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byTooltip('Remove Solana from watchlist'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byTooltip('Remove Solana from watchlist'), findsOneWidget);
  });

  testWidgets('coins saved in an earlier session are shown on launch', (
    tester,
  ) async {
    await pumpApp(
      tester,
      marketRepository: _market(),
      savedPreferences: {
        _savedKey: ['ethereum', 'dogecoin'],
      },
    );
    await _openTab(tester, 'Watchlist');

    expect(_watchlistTiles(), findsNWidgets(2));
  });

  testWidgets('swipe removes a coin and Undo brings it back', (tester) async {
    await pumpApp(
      tester,
      marketRepository: _market(),
      savedPreferences: {
        _savedKey: ['bitcoin', 'ethereum'],
      },
    );
    await _openTab(tester, 'Watchlist');

    await tester.drag(
      find.descendant(
        of: find.byType(WatchlistScreen),
        matching: find.text('Ethereum'),
      ),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    expect(_watchlistTiles(), findsOneWidget);
    expect(find.text('Ethereum removed from watchlist'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(_watchlistTiles(), findsNWidgets(2));
  });

  testWidgets('removing the last coin shows the empty state', (tester) async {
    await pumpApp(
      tester,
      marketRepository: _market(),
      savedPreferences: {
        _savedKey: ['bitcoin'],
      },
    );
    await _openTab(tester, 'Watchlist');

    await tester.tap(
      find.descendant(
        of: find.byType(WatchlistScreen),
        matching: find.byTooltip('Remove Bitcoin from watchlist'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your watchlist is empty'), findsOneWidget);
  });

  testWidgets('the sort menu reorders the watchlist', (tester) async {
    await pumpApp(
      tester,
      marketRepository: _market(),
      savedPreferences: {
        _savedKey: ['bitcoin', 'pepe', 'ethereum'],
      },
    );
    await _openTab(tester, 'Watchlist');

    await tester.tap(find.byIcon(Icons.sort_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lowest price'));
    await tester.pumpAndSettle();

    final order = tester
        .widgetList<CoinListTile>(_watchlistTiles())
        .map((tile) => tile.coin.id);
    expect(order, ['pepe', 'ethereum', 'bitcoin']);
  });
}
