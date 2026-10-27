import 'dart:math' as math;

import 'package:intl/intl.dart';

abstract final class MarketFormatters {
  static const notAvailable = '—';

  static const notAvailableLabel = 'Not available';

  static final _twoDecimals = NumberFormat('#,##0.00', 'en_US');

  static String price(double? value) {
    if (value == null) return notAvailable;
    if (value == 0) return r'$0.00';

    final magnitude = value.abs();
    if (magnitude >= 1) return '\$${_twoDecimals.format(value)}';

    final leadingZeros = -(math.log(magnitude) / math.ln10).floor() - 1;
    final decimals = math.min(leadingZeros + 4, 12);
    final text = value
        .toStringAsFixed(decimals)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return '\$${_ensureTwoDecimals(text)}';
  }

  static String compactCurrency(double? value) {
    if (value == null) return notAvailable;
    final compact = _compact(value);
    return compact == null ? price(value) : '\$$compact';
  }

  static String supply(double? value, String symbol) {
    if (value == null) return notAvailable;
    final amount = _compact(value) ?? _twoDecimals.format(value);
    return '$amount ${symbol.toUpperCase()}';
  }

  static String percentage(double? value) {
    if (value == null) return notAvailable;
    final rounded = roundedPercentage(value);
    final sign = rounded > 0 ? '+' : '';
    return '$sign${rounded.toStringAsFixed(2)}%';
  }

  static double roundedPercentage(double value) {
    final rounded = (value * 100).round() / 100;
    return rounded == 0 ? 0 : rounded;
  }

  static String count(int? value) {
    if (value == null) return notAvailable;
    return NumberFormat.decimalPattern('en_US').format(value);
  }

  static final _dateTimeFormat = DateFormat('MMM d, y, h:mm a', 'en_US');
  static final _dateFormat = DateFormat('MMM d, y', 'en_US');

  static String dateTime(DateTime? value) {
    if (value == null) return notAvailable;
    return _dateTimeFormat.format(value.toLocal());
  }

  static String date(DateTime? value) {
    if (value == null) return notAvailable;
    return _dateFormat.format(value.toLocal());
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
