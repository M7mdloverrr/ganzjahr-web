import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'customers.dart';
import 'document_edit.dart';
import 'document_view.dart';
import 'settings.dart';
import '../i18n.dart';
import 'reports.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final now = DateTime.now();
    final overdue = s.overdue;
    final recent = [...s.documents]..sort((a, b) => b.date.compareTo(a.date));
    final openQuotes = s.documents.where((d) => d.kind == DocKind.quote && d.status == DocStatus.open).length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _Header(company: s.company.name),
            if (!s.company.isComplete) ...[
              const SizedBox(height: 14),
              _SetupBanner(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyScreen()))),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Kpi(
                    label: 'Outstanding'.tr,
                    value: eur(s.openAmount),
                    icon: Icons.hourglass_bottom_rounded,
                    color: const Color(0xFFE09B1A),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Kpi(
                    label: 'Overdue'.tr,
                    value: '${overdue.length}',
                    sub: overdue.isEmpty ? 'all good'.tr : eur(overdue.fold(0.0, (a, d) => a + d.totals.gross)),
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFD64545),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Kpi(
                    label: 'Invoiced {month}'.trf({'month': monthShort(now)}),
                    value: eur(s.invoicedInMonth(now.year, now.month)),
                    icon: Icons.trending_up_rounded,
                    color: brandGreenDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Kpi(
                    label: 'Year {year}'.trf({'year': now.year}),
                    value: eur(s.invoicedInYear(now.year)),
                    sub: '{c} customers · {q} open quotes'.trf({'c': s.customers.length, 'q': openQuotes}),
                    icon: Icons.calendar_month_rounded,
                    color: brandFrost,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _QuickActions(onNavigate: onNavigate),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x22263542),
                  child: Icon(Icons.account_balance_rounded, color: brandInk2),
                ),
                title: Text('Company & tax info'.tr, style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  [
                        if (s.company.taxNumber.isNotEmpty) 'St.-Nr. ${s.company.taxNumber}',
                        if (s.company.vatId.isNotEmpty) 'USt-IdNr. ${s.company.vatId}',
                      ].join(' · ').isEmpty
                      ? 'Add tax number, VAT ID, bank details'.tr
                      : [
                          if (s.company.taxNumber.isNotEmpty) 'St.-Nr. ${s.company.taxNumber}',
                          if (s.company.vatId.isNotEmpty) 'USt-IdNr. ${s.company.vatId}',
                        ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyScreen(section: CompanySection.tax))),
              ),
            ),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x2263B32A),
                  child: Icon(Icons.bar_chart_rounded, color: brandGreenDark),
                ),
                title: Text('Earnings reports'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Monthly & yearly earnings tables'.tr),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
              ),
            ),
            SectionTitle('Last 6 months'.tr),
            _RevenueChart(store: s),
            if (overdue.isNotEmpty) ...[
              SectionTitle('Overdue – send a reminder'.tr),
              Card(
                child: Column(
                  children: overdue
                      .take(5)
                      .map(
                        (d) => ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x22D64545),
                            child: Icon(Icons.notification_important_rounded, color: Color(0xFFD64545)),
                          ),
                          title: Text(d.customer.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            '{n} · {d} days overdue'.trf({'n': d.number, 'd': d.daysOverdue}) +
                                (d.reminderLevel > 0 ? ' · {r} reminder(s) sent'.trf({'r': d.reminderLevel}) : ''),
                          ),
                          trailing: Text(eur(d.totals.gross), style: const TextStyle(fontWeight: FontWeight.w800)),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentViewScreen(docId: d.id))),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            SectionTitle(
              'Recent'.tr,
              trailing: TextButton(onPressed: () => onNavigate(2), child: Text('See all'.tr)),
            ),
            if (recent.isEmpty)
              Card(
                child: Padding(padding: EdgeInsets.all(20), child: Text('No invoices yet. Tap "New invoice" to create your first one.'.tr)),
              )
            else
              Card(
                child: Column(
                  children: recent
                      .take(5)
                      .map(
                        (d) => DocTile(
                          d,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentViewScreen(docId: d.id))),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String company;
  const _Header({required this.company});

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final greet = h < 12 ? 'Good morning'.tr : (h < 18 ? 'Good afternoon'.tr : 'Good evening'.tr);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [brandInk, brandInk2], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: ClipOval(child: Image.asset('assets/images/emblem.png', fit: BoxFit.contain)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greet,
                  style: const TextStyle(color: Color(0xFFA8DC6C), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  company,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(dmy(DateTime.now()), style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _SetupBanner({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFF4DB),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFFB57A00)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Finish your company details (address, tax number, IBAN). German invoices legally need them.'.tr,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final IconData icon;
  final Color color;
  const _Kpi({required this.label, required this.value, this.sub, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: brandInk),
            ),
          ),
          if (sub != null)
            Text(
              sub!,
              style: const TextStyle(color: Colors.black45, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    ),
  );
}

class _QuickActions extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _QuickActions({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, String label, Color color, VoidCallback onTap) => Expanded(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Row(
      children: [
        btn(
          Icons.receipt_long_rounded,
          'New invoice'.tr,
          brandGreenDark,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentEditScreen(kind: DocKind.invoice))),
        ),
        const SizedBox(width: 10),
        btn(
          Icons.request_quote_rounded,
          'New quote'.tr,
          brandFrost,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentEditScreen(kind: DocKind.quote))),
        ),
        const SizedBox(width: 10),
        btn(
          Icons.person_add_alt_1_rounded,
          'New customer'.tr,
          brandInk2,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerEditScreen())),
        ),
      ],
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final Store store;
  const _RevenueChart({required this.store});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
    final invoiced = months.map((m) => store.invoicedInMonth(m.year, m.month)).toList();
    final paid = months.map((m) => store.paidInMonth(m.year, m.month)).toList();
    final maxV = [...invoiced, ...paid, 1.0].reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
        child: Column(
          children: [
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (i) {
                  Widget bar(double v, Color c) => Container(
                    width: 12,
                    height: 4 + 110 * (v / maxV),
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
                  );
                  return Expanded(
                    child: Tooltip(
                      message: 'Invoiced {a}\nPaid {b}'.trf({'a': eur(invoiced[i]), 'b': eur(paid[i])}),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [bar(invoiced[i], brandInk2), const SizedBox(width: 4), bar(paid[i], brandGreen)],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: months
                  .map(
                    (m) => Expanded(
                      child: Text(
                        monthShort(m),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(color: brandInk2, label: 'Invoiced'.tr),
                SizedBox(width: 16),
                _Legend(color: brandGreen, label: 'Paid'.tr),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
