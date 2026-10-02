import 'package:intl/intl.dart';

// These are rebuilt per-currency call, so we keep a factory pattern.
final _dateFmt = DateFormat('MMM dd, yyyy');
final _timeFmt = DateFormat('hh:mm a');
final _monthFmt = DateFormat('MMM yyyy');
final _shortDateFmt = DateFormat('dd MMM');

/// Format amount with given currency symbol.
String formatAmount(double amount, {String symbol = '\$'}) {
  final fmt = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
  return fmt.format(amount);
}

String formatCompact(double amount) => NumberFormat.compact().format(amount);

String formatDate(DateTime date) => _dateFmt.format(date);

String formatTime(DateTime date) => _timeFmt.format(date);

String formatDateTime(DateTime date) =>
    '${_shortDateFmt.format(date)} • ${_timeFmt.format(date)}';

String formatMonth(DateTime date) => _monthFmt.format(date);

String formatShortDate(DateTime date) => _shortDateFmt.format(date);

/// e.g. "2 days ago", "Today", "Yesterday"
String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final diff = DateTime(now.year, now.month, now.day)
      .difference(DateTime(date.year, date.month, date.day))
      .inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return '$diff days ago';
  return _dateFmt.format(date);
}
