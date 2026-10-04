import 'package:intl/intl.dart';

final _eur = NumberFormat.currency(locale: 'de_DE', symbol: '€', decimalDigits: 2);
final _num = NumberFormat('#,##0.##', 'de_DE');
final _date = DateFormat('dd.MM.yyyy', 'de_DE');
final _dateTime = DateFormat('dd.MM.yyyy, HH:mm', 'de_DE');
final _month = DateFormat('MMM', 'en_US');

String eur(double v) => _eur.format(v);
String qty(double v) => _num.format(v);
String dmy(DateTime d) => _date.format(d);
String dmyHm(DateTime d) => '${_dateTime.format(d)} Uhr';
String monthShort(DateTime d) => _month.format(d);

String vatLabel(double rate) => '${_num.format(rate)} %';

double parseNum(String s) {
  final t = s.trim().replaceAll(' ', '').replaceAll('€', '');
  if (t.isEmpty) return 0;
  final normalized = t.contains(',') ? t.replaceAll('.', '').replaceAll(',', '.') : t;
  return double.tryParse(normalized) ?? 0;
}

final _edit = NumberFormat('0.##', 'de_DE');

String numText(double v) => v == 0 ? '' : _edit.format(v);
