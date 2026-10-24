import 'package:crypto_market/app.dart';
import 'package:crypto_market/core/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CryptoMarketApp()));
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(CryptoMarketApp)),
    );
  }

  testWidgets('starts on the Markets tab', (tester) async {
    await pumpApp(tester);

    expect(find.widgetWithText(AppBar, 'Markets'), findsOneWidget);
  });

  testWidgets('bottom navigation switches between tabs', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Watchlist'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Watchlist'), findsOneWidget);

    await tester.tap(find.text('Global'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Global market'), findsOneWidget);
  });

  testWidgets('coin details route opens from a deep link', (tester) async {
    final container = await pumpApp(tester);

    container.read(appRouterProvider).go(AppRoutes.coinDetails('bitcoin'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'bitcoin'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
