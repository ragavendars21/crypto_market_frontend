import 'package:crypto_market/core/routing/app_router.dart';
import 'package:crypto_market/features/market/data/mock_market_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Every screen, opened through the real router.
const _screens = {
  'Markets': AppRoutes.markets,
  'Watchlist': AppRoutes.watchlist,
  'Global': AppRoutes.global,
  'Coin details': '/coins/bitcoin',
};

/// A typical phone: 412 x 915 logical pixels.
void _usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1236, 2745);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _open(WidgetTester tester, String route) async {
  final container = await pumpApp(
    tester,
    marketRepository: MockMarketRepository(latency: Duration.zero),
    // A saved coin, so the watchlist shows a list rather than its empty state.
    savedPreferences: {
      'watchlist_coin_ids': ['bitcoin', 'sample-new-coin'],
    },
  );
  container.read(appRouterProvider).go(route);
  await tester.pumpAndSettle();
}

void main() {
  for (final MapEntry(key: name, value: route) in _screens.entries) {
    group(name, () {
      testWidgets('meets tap target, label and contrast guidelines', (
        tester,
      ) async {
        _usePhoneScreen(tester);
        final semantics = tester.ensureSemantics();
        await _open(tester, route);

        // Android: tappable areas of at least 48x48 dp.
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        // iOS: at least 44x44 pt.
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        // Every tappable element has a label for screen readers.
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        // Text meets WCAG contrast (4.5:1, or 3:1 for large text).
        await expectLater(tester, meetsGuideline(textContrastGuideline));

        semantics.dispose();
      });

      testWidgets('lays out without overflow at 200% text size', (
        tester,
      ) async {
        _usePhoneScreen(tester);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await _open(tester, route);

        // Overflow errors are reported as exceptions during layout.
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('dark theme also meets the contrast guideline', (tester) async {
    _usePhoneScreen(tester);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final semantics = tester.ensureSemantics();

    await _open(tester, AppRoutes.markets);

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}
