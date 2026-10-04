import 'models.dart';
import 'store.dart';

class EarningsRow {
  final int year;
  final int? month;
  int count = 0;
  double net = 0;
  double vat = 0;
  double gross = 0;
  double received = 0;

  EarningsRow(this.year, [this.month]);

  void addInvoice(Totals t) {
    count++;
    net += t.net;
    vat += t.vat;
    gross += t.gross;
  }

  void addTo(EarningsRow sum) {
    sum
      ..count += count
      ..net += net
      ..vat += vat
      ..gross += gross
      ..received += received;
  }
}

/// Invoiced amounts are grouped by invoice date, received amounts by payment date.
List<EarningsRow> monthlyEarnings(Store s, int year) {
  final rows = List.generate(12, (i) => EarningsRow(year, i + 1));
  for (final d in s.invoices) {
    final t = d.totals;
    if (d.date.year == year) rows[d.date.month - 1].addInvoice(t);
    final p = d.paidAt;
    if (d.status == DocStatus.paid && p != null && p.year == year) rows[p.month - 1].received += t.gross;
  }
  return rows;
}

List<int> reportYears(Store s) {
  final now = DateTime.now().year;
  final years = <int>{now};
  for (final d in s.invoices) {
    years.add(d.date.year);
    if (d.paidAt != null) years.add(d.paidAt!.year);
  }
  final first = years.reduce((a, b) => a < b ? a : b);
  final last = years.reduce((a, b) => a > b ? a : b);
  return [for (var y = last; y >= first; y--) y];
}

List<EarningsRow> yearlyEarnings(Store s) {
  final years = reportYears(s).reversed.toList();
  return years.map((y) {
    final r = EarningsRow(y);
    for (final m in monthlyEarnings(s, y)) {
      m.addTo(r);
    }
    return r;
  }).toList();
}

EarningsRow sumRows(List<EarningsRow> rows) {
  final sum = EarningsRow(rows.isEmpty ? DateTime.now().year : rows.first.year);
  for (final r in rows) {
    r.addTo(sum);
  }
  return sum;
}
