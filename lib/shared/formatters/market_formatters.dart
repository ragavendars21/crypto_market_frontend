import 'dart:math' as math;

import 'package:intl/intl.dart';

/// Formatting for market values. Every function accepts `null` and returns
/// [notAvailable], so screens never have to invent a fallback number.
abstract final class MarketFormatters {
  /// Shown for any value the provider did not supply.
  static const notAvailable = '—';

  /// Read by screen readers instead of the dash.
  static const notAvailableLabel = 'Not available';

  static final _twoDecimals = NumberFormat('#,##0.00', 'en_US');

  /// `$67,012.50` for prices of $1 or more. Smaller prices keep about four
  /// significant digits so they don't all round to `$0.00`:
  /// `$0.5234`, `$0.00001842`.
  static String price(double? value) {
    if (value == null) return notAvailable;
    if (value == 0) return r'$0.00';

    final magnitude = value.abs();
    if (magnitude >= 1) return '\$${_twoDecimals.format(value)}';

    // Number of zeros after the decimal point, plus 4 significant digits.
    final leadingZeros = -(math.log(magnitude) / math.ln10).floor() - 1;
    final decimals = math.min(leadingZeros + 4, 12);
    // Drop trailing zeros (and a dangling dot, e.g. 0.99999 -> "1.0000").
    final text = value
        .toStringAsFixed(decimals)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return '\$${_ensureTwoDecimals(text)}';
  }

  /// `$1.32T`, `$81.20B`, `$412.00M`, `$12.50K`. Values under $1,000 use
  /// [price].
  static String compactCurrency(double? value) {
    if (value == null) return notAvailable;
    final compact = _compact(value);
    return compact == null ? price(value) : '\$$compact';
  }

  /// Circulating/total/max supply, e.g. `19.71M BTC`.
  static String supply(double? value, String symbol) {
    if (value == null) return notAvailable;
    final amount = _compact(value) ?? _twoDecimals.format(value);
    return '$amount ${symbol.toUpperCase()}';
  }

  /// `+5.58%`, `-2.40%`, `0.00%`.
  static String percentage(double? value) {
    if (value == null) return notAvailable;
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  /// Plain counts such as number of exchanges: `17,321`.
  static String count(int? value) {
    if (value == null) return notAvailable;
    return NumberFormat.decimalPattern('en_US').format(value);
  }

  static String? _compact(double value) {
    const units = [(1e12, 'T'), (1e9, 'B'), (1e6, 'M'), (1e3, 'K')];
    for (final (threshold, suffix) in units) {
      if (value.abs() >= threshold) {
        return '${(value / threshold).toStringAsFixed(2)}$suffix';
      }
    }
    return null;
  }

  static String _ensureTwoDecimals(String text) {
    final decimals = text.contains('.') ? text.split('.').last.length : 0;
    if (decimals >= 2) return text;
    return double.parse(text).toStringAsFixed(2);
  }
}
