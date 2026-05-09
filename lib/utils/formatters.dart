import 'package:intl/intl.dart';

String formatCurrency(double value, {String currency = 'BRL'}) {
  final locale = currency == 'BRL' ? 'pt_BR' : currency == 'USD' ? 'en_US' : 'de_DE';
  return NumberFormat.currency(locale: locale, symbol: currency == 'BRL' ? 'R\$' : currency == 'USD' ? '\$' : '€').format(value);
}

String formatMonth(DateTime date) => DateFormat('MMMM yyyy', 'pt_BR').format(date);

String formatMonthShort(DateTime date) => DateFormat('MMM/yy', 'pt_BR').format(date);

String formatMonthAbbrev(DateTime date) =>
    DateFormat('MMM', 'pt_BR').format(date).replaceAll('.', '');

String formatDate(DateTime date) => DateFormat('dd/MM/yyyy', 'pt_BR').format(date);

String formatDateShort(DateTime date) => DateFormat('dd/MM', 'pt_BR').format(date);

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

bool isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

int monthDiff(DateTime start, DateTime end) => (end.year - start.year) * 12 + (end.month - start.month);

DateTime firstDayOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

DateTime lastDayOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0);

String groupLabel(String groupId) {
  switch (groupId) {
    case 'avista': return 'À Vista';
    case 'parcelamento': return 'Parcelamento';
    case 'assinatura': return 'Assinatura';
    case 'debito': return 'Débito';
    default: return groupId;
  }
}
