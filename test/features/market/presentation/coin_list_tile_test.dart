import 'package:crypto_market/core/theme/app_colors.dart';
import 'package:crypto_market/core/theme/app_theme.dart';
import 'package:crypto_market/features/market/domain/coin_summary.dart';
import 'package:crypto_market/features/market/presentation/widgets/coin_list_tile.dart';
import 'package:crypto_market/shared/widgets/price_change_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  const bitcoin = CoinSummary(
    id: 'bitcoin',
    symbol: 'btc',
    name: 'Bitcoin',
    marketCapRank: 1,
    priceUsd: 67012.5,
    priceChangePercentage24h: 1.85,
    marketCapUsd: 1.321e12,
    totalVolumeUsd: 3.12e10,
    circulatingSupply: 19712345,
  );

  testWidgets('shows price, change and market metrics', (tester) async {
    await tester.pumpWidget(_wrap(CoinListTile(coin: bitcoin, onTap: () {})));

    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('BTC'), findsOneWidget);
    expect(find.text(r'$67,012.50'), findsOneWidget);
    expect(find.text('+1.85%'), findsOneWidget);
    expect(find.text(r'$1.32T'), findsOneWidget);
    expect(find.text(r'$31.20B'), findsOneWidget);
    expect(find.text('19.71M BTC'), findsOneWidget);
  });

  testWidgets('shows dashes, not zeros, for missing values', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CoinListTile(
          coin: const CoinSummary(id: 'new', symbol: 'new', name: 'New Coin'),
          onTap: () {},
        ),
      ),
    );

    // Rank, price, change, market cap, volume and supply.
    expect(find.text('—'), findsNWidgets(6));
    expect(find.textContaining(r'$0'), findsNothing);
  });

  testWidgets('announces one summary sentence to screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(CoinListTile(coin: bitcoin, onTap: () {})));

    expect(
      find.bySemanticsLabel(
        RegExp(r'^Bitcoin, BTC, rank 1\. Price \$67,012\.50, up 1\.85 percent'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('truncates very long names instead of overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        CoinListTile(
          coin: const CoinSummary(
            id: 'long',
            symbol: 'long',
            name: 'An Extremely Long Coin Name That Will Not Fit On Screen',
            priceUsd: 123456789.12,
          ),
          onTap: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('calls onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(CoinListTile(coin: bitcoin, onTap: () => tapped = true)),
    );

    await tester.tap(find.byType(CoinListTile));

    expect(tapped, isTrue);
  });

  group('PriceChangeIndicator', () {
    Future<Color?> colorFor(WidgetTester tester, double? value) async {
      await tester.pumpWidget(_wrap(PriceChangeIndicator(percentage: value)));
      return tester.widget<Text>(find.byType(Text)).style?.color;
    }

    testWidgets('uses positive, negative and neutral colors', (tester) async {
      expect(await colorFor(tester, 2), AppColors.light.positive);
      expect(await colorFor(tester, -2), AppColors.light.negative);
      expect(await colorFor(tester, 0), isNot(AppColors.light.positive));
    });

    testWidgets('shows an arrow only when the price moved', (tester) async {
      await tester.pumpWidget(_wrap(const PriceChangeIndicator(percentage: 3)));
      expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);

      await tester.pumpWidget(
        _wrap(const PriceChangeIndicator(percentage: null)),
      );
      expect(find.byType(Icon), findsNothing);
      expect(find.text('—'), findsOneWidget);
    });
  });
}
