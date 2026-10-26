import 'package:crypto_market/shared/formatters/market_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('price', () {
    test('uses two decimals and grouping for prices of \$1 or more', () {
      expect(MarketFormatters.price(67012.5), r'$67,012.50');
      expect(MarketFormatters.price(1), r'$1.00');
      expect(MarketFormatters.price(1.0002), r'$1.00');
    });

    test('keeps about four significant digits for small prices', () {
      expect(MarketFormatters.price(0.5234), r'$0.5234');
      expect(MarketFormatters.price(0.1385), r'$0.1385');
      expect(MarketFormatters.price(0.9998), r'$0.9998');
      expect(MarketFormatters.price(0.00001842), r'$0.00001842');
      expect(MarketFormatters.price(0.0000089), r'$0.0000089');
      expect(MarketFormatters.price(0.5), r'$0.50');
      expect(MarketFormatters.price(0.999999), r'$1.00');
    });

    test('handles zero and missing values', () {
      expect(MarketFormatters.price(0), r'$0.00');
      expect(MarketFormatters.price(null), '—');
    });
  });

  group('compactCurrency', () {
    test('abbreviates large values', () {
      expect(MarketFormatters.compactCurrency(1.321e12), r'$1.32T');
      expect(MarketFormatters.compactCurrency(8.12e10), r'$81.20B');
      expect(MarketFormatters.compactCurrency(4.12e8), r'$412.00M');
      expect(MarketFormatters.compactCurrency(125000), r'$125.00K');
    });

    test('falls back to a normal price under \$1,000', () {
      expect(MarketFormatters.compactCurrency(999.5), r'$999.50');
      expect(MarketFormatters.compactCurrency(null), '—');
    });
  });

  test('supply adds the uppercase symbol', () {
    expect(MarketFormatters.supply(19712345, 'btc'), '19.71M BTC');
    expect(MarketFormatters.supply(420.5, 'eth'), '420.50 ETH');
    expect(MarketFormatters.supply(null, 'btc'), '—');
  });

  test('percentage shows an explicit sign', () {
    expect(MarketFormatters.percentage(5.584), '+5.58%');
    expect(MarketFormatters.percentage(-2.4), '-2.40%');
    expect(MarketFormatters.percentage(0), '0.00%');
    expect(MarketFormatters.percentage(null), '—');
    // Tiny moves that round to zero are neutral: no "+0.00%" or "-0.00%".
    expect(MarketFormatters.percentage(0.004), '0.00%');
    expect(MarketFormatters.percentage(-0.004), '0.00%');
  });

  test('dates use a readable format and handle null', () {
    // A local (non-UTC) time, so the result doesn't depend on the time zone.
    final time = DateTime(2026, 10, 23, 14, 5);

    expect(MarketFormatters.dateTime(time), 'Oct 23, 2026, 2:05 PM');
    expect(MarketFormatters.date(time), 'Oct 23, 2026');
    expect(MarketFormatters.dateTime(null), '—');
    expect(MarketFormatters.date(null), '—');
  });

  test('count groups thousands', () {
    expect(MarketFormatters.count(17321), '17,321');
    expect(MarketFormatters.count(null), '—');
  });
}
