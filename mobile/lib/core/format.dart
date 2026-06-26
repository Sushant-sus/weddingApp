import 'package:intl/intl.dart';

/// Indian-grouped currency (₹12,500 / ₹84,200) — symbol rendered with the value.
final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

String formatInr(num? value) => _inr.format(value ?? 0);

/// Parse the string money fields the API returns (e.g. "12500.00").
num parseMoney(Object? v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

final _intl = NumberFormat.decimalPattern('en_IN');
String formatNumber(num? value) => _intl.format(value ?? 0);

String formatDateLong(DateTime d) => DateFormat('EEE, d MMM yyyy').format(d);
