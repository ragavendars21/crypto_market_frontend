import 'package:crypto_market/core/errors/app_failure.dart';
import 'package:crypto_market/core/routing/app_router.dart';
import 'package:crypto_market/features/coin_details/domain/price_history.dart';
import 'package:crypto_market/features/coin_details/presentation/coin_details_screen.dart';
import 'package:crypto_market/shared/widgets/state_views.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_coin_details_repository.dart';
import '../../../helpers/pump_app.dart';

Future<void> _openCoin(
  WidgetTester tester,
  String coinId, {
  FakeCoinDetailsRepository? repository,
}) async {
  final container = await pumpApp(tester, coinDetailsRepository: repository);
  container.read(appRouterProvider).go(AppRoutes.coinDetails(coinId));
  await tester.pumpAndSettle();
}

Finder get _detailsScrollable => find
    .descendant(
      of: find.byType(CoinDetailsScreen),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: _detailsScrollable);
  await tester.pumpAndSettle();
}

Future<void> _selectRange(WidgetTester tester, ChartRange range) async {
  // "1Y" etc. also appear in the Performance grid, so look in the selector.
  await tester.tap(
    find.descendant(
      of: find.byType(SegmentedButton<ChartRange>),
      matching: find.text(range.label),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the header, price and an interactive chart', (
    tester,
  ) async {
    await _openCoin(tester, 'bitcoin');

    expect(find.widgetWithText(AppBar, 'Bitcoin'), findsOneWidget);
    expect(find.text('Rank #1'), findsOneWidget);
    expect(find.text(r'$67,012.50'), findsOneWidget);
    expect(find.text('+1.85%'), findsWidgets);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('describes the chart to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await _openCoin(tester, 'bitcoin');

    expect(
      find.bySemanticsLabel(RegExp(r'^Price chart for 7D\. Started at \$')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('shows market data and a supply bar for capped coins', (
    tester,
  ) async {
    await _openCoin(tester, 'bitcoin');

    await _scrollTo(tester, find.text('Fully diluted valuation'));
    expect(find.text(r'$1.41T'), findsOneWidget);

    await _scrollTo(tester, find.text('Max supply'));
    expect(find.text('21.00M BTC'), findsNWidgets(2)); // Total and max.
    expect(find.text('93.9% of max supply in circulation'), findsOneWidget);

    await _scrollTo(tester, find.text('All-time high'));
    expect(find.text(r'$73,738.00'), findsOneWidget);
  });

  testWidgets('says "No fixed cap" and hides the bar for uncapped coins', (
    tester,
  ) async {
    await _openCoin(tester, 'ethereum');

    await _scrollTo(tester, find.text('Max supply'));
    expect(find.text('No fixed cap'), findsOneWidget);
    expect(find.textContaining('of max supply in circulation'), findsNothing);
  });

  testWidgets('shows dashes for values the provider does not have', (
    tester,
  ) async {
    await _openCoin(tester, 'dogecoin');

    await _scrollTo(tester, find.text('Fully diluted valuation'));
    final fdvRow = find.ancestor(
      of: find.text('Fully diluted valuation'),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(of: fdvRow.first, matching: find.text('—')),
      findsOneWidget,
    );

    await _scrollTo(tester, find.text('All-time high'));
    expect(find.textContaining(r'$0.00'), findsNothing);
  });

  testWidgets('switching ranges loads new data and reuses cached data', (
    tester,
  ) async {
    final repository = FakeCoinDetailsRepository();
    await _openCoin(tester, 'bitcoin', repository: repository);

    await _selectRange(tester, ChartRange.year);
    expect(find.text('in 1Y'), findsOneWidget);

    await _selectRange(tester, ChartRange.week);
    expect(find.text('in 7D'), findsOneWidget);

    // 7D was cached, so going back did not request it again.
    expect(repository.historyRequests, [ChartRange.week, ChartRange.year]);
  });

  testWidgets('shows "not enough data" instead of a misleading line', (
    tester,
  ) async {
    await _openCoin(tester, 'sample-new-coin');
    await _selectRange(tester, ChartRange.year);

    expect(
      find.text('Not enough price history for this range yet.'),
      findsOneWidget,
    );
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('a chart error can be retried without leaving the screen', (
    tester,
  ) async {
    final repository = FakeCoinDetailsRepository()
      ..failNextHistoryWith = const TimeoutFailure();
    await _openCoin(tester, 'bitcoin', repository: repository);

    expect(find.text(const TimeoutFailure().message), findsOneWidget);
    expect(find.text(r'$67,012.50'), findsOneWidget); // Rest still works.

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('a details error offers retry', (tester) async {
    final repository = FakeCoinDetailsRepository()
      ..failNextDetailsWith = const NetworkFailure();
    await _openCoin(tester, 'bitcoin', repository: repository);

    expect(find.byType(ErrorView), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text(r'$67,012.50'), findsOneWidget);
  });

  testWidgets('opened from a link, the app bar still offers a way back', (
    tester,
  ) async {
    final repository = FakeCoinDetailsRepository()
      ..failNextDetailsWith = const NetworkFailure();
    // `go` replaces the stack, like opening a deep link: nothing to pop.
    await _openCoin(tester, 'bitcoin', repository: repository);

    await tester.tap(find.byTooltip('Back to markets'));
    await tester.pumpAndSettle();

    expect(find.byType(CoinDetailsScreen), findsNothing);
    expect(find.widgetWithText(AppBar, 'Markets'), findsOneWidget);
  });

  testWidgets('an unknown coin explains itself and links back', (tester) async {
    await _openCoin(tester, 'not-a-coin');

    expect(find.text('Coin not found'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);

    await tester.tap(find.text('Back to markets'));
    await tester.pumpAndSettle();

    expect(find.byType(CoinDetailsScreen), findsNothing);
    expect(find.widgetWithText(AppBar, 'Markets'), findsOneWidget);
  });
}
