import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../format.dart';
import '../i18n.dart';
import '../pdf/invoice_pdf.dart';
import '../reports.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'pdf_actions.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _monthly = true;
  int _year = DateTime.now().year;

  String _monthName(int m, String locale) => DateFormat.MMMM(locale).format(DateTime(2000, m));

  List<(String, EarningsRow)> _rows(Store s, String locale) => _monthly
      ? monthlyEarnings(s, _year).map((r) => (_monthName(r.month!, locale), r)).toList()
      : yearlyEarnings(s).map((r) => ('${r.year}', r)).toList();

  String get _pdfTitle => _monthly ? 'Umsatzübersicht $_year (monatlich)' : 'Umsatzübersicht (jährlich)';

  Future<void> _savePdf(Store s) async {
    final rows = _rows(s, 'de_DE');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewScreen(
          title: 'Earnings reports'.tr,
          fileName: _monthly ? 'Umsatzuebersicht_$_year.pdf' : 'Umsatzuebersicht_Jahre.pdf',
          builder: () => buildEarningsPdf(
            company: s.company,
            title: _pdfTitle,
            periodHeader: _monthly ? 'Monat' : 'Jahr',
            rows: rows,
            total: sumRows(rows.map((e) => e.$2).toList()),
          ),
        ),
      ),
    );
  }

  Future<void> _saveCsv(Store s) async {
    final rows = _rows(s, 'de_DE');
    String n(double v) => v.toStringAsFixed(2).replaceAll('.', ',');
    final total = sumRows(rows.map((e) => e.$2).toList());
    final lines = [
      '${_monthly ? 'Monat' : 'Jahr'};Anzahl;Netto;USt;Brutto;Zahlungseingang',
      for (final (label, r) in rows) '$label;${r.count};${n(r.net)};${n(r.vat)};${n(r.gross)};${n(r.received)}',
      'Summe;${total.count};${n(total.net)};${n(total.vat)};${n(total.gross)};${n(total.received)}',
    ];
    try {
      final uri = await FilePicker.saveFile(
        fileName: _monthly ? 'Umsatzuebersicht_$_year.csv' : 'Umsatzuebersicht_Jahre.csv',
        bytes: utf8.encode('\uFEFF${lines.join('\r\n')}'),
        mimeType: 'text/csv',
        dialogTitle: 'Save table'.tr,
      );
      if (uri != null && mounted) toast(context, 'Report saved'.tr);
    } catch (e) {
      if (mounted) toast(context, 'Export failed: {e}'.trf({'e': e}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final years = reportYears(s);
    if (!years.contains(_year)) _year = years.first;
    final rows = _rows(s, locale);
    final total = sumRows(rows.map((e) => e.$2).toList());
    final best = rows.where((r) => r.$2.gross > 0).fold<(String, EarningsRow)?>(null, (b, r) => b == null || r.$2.gross > b.$2.gross ? r : b);
    final maxGross = rows.fold<double>(1, (m, r) => r.$2.gross > m ? r.$2.gross : m);

    Widget kpi(String label, String value, Color color, IconData icon) => Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              FittedBox(
                child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );

    const head = TextStyle(fontWeight: FontWeight.w700, fontSize: 12);
    const bold = TextStyle(fontWeight: FontWeight.w800, fontSize: 13);
    DataRow row(String label, EarningsRow r, {bool sum = false}) => DataRow(
      color: sum ? WidgetStateProperty.all(brandGreen.withValues(alpha: 0.15)) : null,
      cells: [
        DataCell(Text(label, style: sum ? bold : null)),
        DataCell(Text('${r.count}', style: sum ? bold : null)),
        DataCell(Text(eur(r.net), style: sum ? bold : null)),
        DataCell(Text(eur(r.vat), style: sum ? bold : null)),
        DataCell(Text(eur(r.gross), style: sum ? bold : const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(eur(r.received), style: sum ? bold : null)),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Earnings reports'.tr),
        actions: [
          IconButton(tooltip: 'PDF table'.tr, icon: const Icon(Icons.picture_as_pdf_rounded), onPressed: () => _savePdf(s)),
          IconButton(tooltip: 'Excel (CSV)', icon: const Icon(Icons.table_chart_rounded), onPressed: () => _saveCsv(s)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text('Monthly'.tr), icon: const Icon(Icons.calendar_view_month_rounded)),
              ButtonSegment(value: false, label: Text('Yearly'.tr), icon: const Icon(Icons.calendar_today_rounded)),
            ],
            selected: {_monthly},
            onSelectionChanged: (v) => setState(() => _monthly = v.first),
          ),
          if (_monthly) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: years.contains(_year - 1) ? () => setState(() => _year--) : null,
                  icon: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Center(
                    child: Text('$_year', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ),
                IconButton(
                  onPressed: years.contains(_year + 1) ? () => setState(() => _year++) : null,
                  icon: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              kpi('Invoiced (gross)'.tr, eur(total.gross), brandGreenDark, Icons.receipt_long_rounded),
              const SizedBox(width: 8),
              kpi('Received'.tr, eur(total.received), brandFrost, Icons.savings_rounded),
            ],
          ),
          Row(
            children: [
              kpi('VAT collected'.tr, eur(total.vat), brandInk2, Icons.account_balance_rounded),
              const SizedBox(width: 8),
              kpi('Best month'.tr, best == null ? '–' : best.$1, const Color(0xFFE09B1A), Icons.emoji_events_rounded),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
              child: Column(
                children: [
                  for (final (label, r) in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 74,
                            child: Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: r.gross / maxGross,
                                minHeight: 12,
                                backgroundColor: const Color(0x11000000),
                                color: brandGreen,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 92,
                            child: Text(
                              eur(r.gross),
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0x0D000000)),
                columnSpacing: 18,
                horizontalMargin: 12,
                columns: [
                  DataColumn(label: Text(_monthly ? 'Month'.tr : 'Year'.tr, style: head)),
                  DataColumn(label: Text('Count'.tr, style: head), numeric: true),
                  DataColumn(label: Text('Net'.tr, style: head), numeric: true),
                  DataColumn(label: Text('VAT'.tr, style: head), numeric: true),
                  DataColumn(label: Text('Gross'.tr, style: head), numeric: true),
                  DataColumn(label: Text('Received'.tr, style: head), numeric: true),
                ],
                rows: [for (final (label, r) in rows) row(label, r), row('Sum'.tr, total, sum: true)],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Invoiced amounts by invoice date, received amounts by payment date. Cancelled invoices and drafts are not included.'.tr,
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
