import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n.dart';
import 'reports.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportBackup(BuildContext context) async {
    final s = context.read<Store>();
    final now = DateTime.now();
    final name = 'GanzJahr_Backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';
    try {
      final uri = await FilePicker.saveFile(
        fileName: name,
        bytes: utf8.encode(s.exportJson()),
        mimeType: 'application/json',
        dialogTitle: 'Save backup'.tr,
      );
      if (uri != null && context.mounted) toast(context, 'Backup saved: {n}'.trf({'n': name}));
    } catch (e) {
      if (context.mounted) toast(context, 'Backup failed: {e}'.trf({'e': e}));
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final files = await FilePicker.pickFiles(dialogTitle: 'Choose backup file'.tr, type: FileType.any);
    if (files.isEmpty || !context.mounted) return;
    final ok = await confirm(context, 'Restore backup?'.tr, 'All current data in the app will be replaced by the backup.'.tr, ok: 'Restore'.tr);
    if (!ok || !context.mounted) return;
    try {
      final raw = utf8.decode(await files.first.readAsBytes());
      if (!context.mounted) return;
      context.read<Store>().importJson(raw);
      toast(context, 'Backup restored'.tr);
    } catch (e) {
      if (context.mounted) toast(context, 'This is not a valid backup file ({e})'.trf({'e': e}));
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final s = context.read<Store>();
    final year = DateTime.now().year;
    String q(String v) => '"${v.replaceAll('"', '""')}"';
    String n(double v) => v.toStringAsFixed(2).replaceAll('.', ',');
    final rows = <String>['Rechnungsnummer;Datum;Kunde;Kunden-Nr.;Netto;USt;Brutto;Status;Bezahlt am'];
    final list = s.documents.where((d) => d.isInvoice && d.status != DocStatus.draft).toList()..sort((a, b) => a.number.compareTo(b.number));
    for (final d in list) {
      final t = d.totals;
      rows.add(
        [
          q(d.number),
          dmy(d.date),
          q(d.customer.displayName),
          q(d.customer.number),
          n(t.net),
          n(t.vat),
          n(t.gross),
          d.status == DocStatus.cancelled ? 'Storniert' : (d.status == DocStatus.paid ? 'Bezahlt' : 'Offen'),
          d.paidAt == null ? '' : dmy(d.paidAt!),
        ].join(';'),
      );
    }
    try {
      final uri = await FilePicker.saveFile(
        fileName: 'Rechnungsausgangsbuch_$year.csv',
        bytes: utf8.encode('\uFEFF${rows.join('\r\n')}'),
        mimeType: 'text/csv',
        dialogTitle: 'Save invoice list'.tr,
      );
      if (uri != null && context.mounted) toast(context, 'Invoice list saved'.tr);
    } catch (e) {
      if (context.mounted) toast(context, 'Export failed: {e}'.trf({'e': e}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = s.company;
    Widget tile(IconData icon, String title, String sub, VoidCallback onTap, {Color color = brandGreenDark, Widget? trailing}) => ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(sub),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
    return Scaffold(
      appBar: AppBar(title: Text('Control panel'.tr)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          SectionTitle('Language'.tr),
          Card(
            child: Column(
              children: [
                for (final l in AppLang.values)
                  ListTile(
                    leading: Icon(s.language == l.name ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: brandGreenDark),
                    title: Text(l.nativeName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    onTap: () => context.read<Store>().setLanguage(l.name),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text('Invoices are always printed in German.'.tr, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ),
              ],
            ),
          ),
          SectionTitle('My company'.tr),
          Card(
            child: Column(
              children: [
                tile(
                  Icons.business_rounded,
                  'Company details'.tr,
                  c.addressLine.isEmpty ? 'Name, owner, address, contact'.tr : c.addressLine,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyScreen(section: CompanySection.company))),
                ),
                tile(
                  Icons.account_balance_rounded,
                  'Tax information'.tr,
                  [
                    if (c.taxNumber.isNotEmpty) 'St.-Nr. ${c.taxNumber}',
                    if (c.vatId.isNotEmpty) 'USt-IdNr. ${c.vatId}',
                    if (c.smallBusiness) '§19 small business'.tr,
                  ].join(' · ').ifEmpty('Tax number, VAT ID, tax office, VAT rate'.tr),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyScreen(section: CompanySection.tax))),
                  color: brandInk2,
                  trailing: (c.taxNumber.isEmpty && c.vatId.isEmpty) ? const Icon(Icons.error_outline_rounded, color: Color(0xFFD64545)) : null,
                ),
                tile(
                  Icons.credit_card_rounded,
                  'Bank details'.tr,
                  c.iban.isEmpty ? 'IBAN for payments & GiroCode'.tr : 'IBAN ${c.iban}',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyScreen(section: CompanySection.bank))),
                  color: brandFrost,
                  trailing: c.iban.isEmpty ? const Icon(Icons.error_outline_rounded, color: Color(0xFFD64545)) : null,
                ),
                tile(
                  Icons.tag_rounded,
                  'Invoice numbers & terms'.tr,
                  'Next: {n} · {d} days to pay'.trf({'n': s.peekNumber(DocKind.invoice), 'd': c.paymentDays}),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyScreen(section: CompanySection.invoice))),
                  color: const Color(0xFF9A7B4F),
                ),
              ],
            ),
          ),
          SectionTitle('Data'.tr),
          Card(
            child: Column(
              children: [
                tile(Icons.backup_rounded, 'Save backup'.tr, 'Store all data as a file (Google Drive, USB, email…)'.tr, () => _exportBackup(context)),
                tile(
                  Icons.settings_backup_restore_rounded,
                  'Restore backup'.tr,
                  'Load data from a backup file (e.g. new phone)'.tr,
                  () => _restoreBackup(context),
                  color: brandInk2,
                ),
                tile(
                  Icons.bar_chart_rounded,
                  'Earnings reports'.tr,
                  'Monthly & yearly earnings tables'.tr,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                ),
                tile(
                  Icons.table_chart_rounded,
                  'Export for tax advisor'.tr,
                  'Invoice list as CSV (Excel)'.tr,
                  () => _exportCsv(context),
                  color: brandFrost,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                Image.asset('assets/images/logo_invoice.png', height: 70),
                const SizedBox(height: 8),
                Text(
                  '{c} customers · {d} documents'.trf({'c': s.customers.length, 'd': s.documents.length}),
                  style: const TextStyle(color: Colors.black45),
                ),
                Text('Data is stored only on this phone. Make regular backups.'.tr, style: TextStyle(color: Colors.black45, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

enum CompanySection { company, tax, bank, invoice }

class CompanyScreen extends StatefulWidget {
  final CompanySection? section;
  const CompanyScreen({super.key, this.section});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final _form = GlobalKey<FormState>();
  late Company _c;
  late final Map<String, TextEditingController> _t;
  final _keys = {for (final s in CompanySection.values) s: GlobalKey()};

  @override
  void initState() {
    super.initState();
    _c = Company.fromJson(context.read<Store>().company.toJson());
    _t = {
      'name': TextEditingController(text: _c.name),
      'owner': TextEditingController(text: _c.owner),
      'street': TextEditingController(text: _c.street),
      'zip': TextEditingController(text: _c.zip),
      'city': TextEditingController(text: _c.city),
      'phone': TextEditingController(text: _c.phone),
      'email': TextEditingController(text: _c.email),
      'website': TextEditingController(text: _c.website),
      'taxNumber': TextEditingController(text: _c.taxNumber),
      'vatId': TextEditingController(text: _c.vatId),
      'taxOffice': TextEditingController(text: _c.taxOffice),
      'bankName': TextEditingController(text: _c.bankName),
      'iban': TextEditingController(text: _c.iban),
      'bic': TextEditingController(text: _c.bic),
      'holder': TextEditingController(text: _c.accountHolder),
      'invoicePrefix': TextEditingController(text: _c.invoicePrefix),
      'quotePrefix': TextEditingController(text: _c.quotePrefix),
      'nextInvoice': TextEditingController(text: '${_c.nextInvoiceNo}'),
      'nextQuote': TextEditingController(text: '${_c.nextQuoteNo}'),
      'payDays': TextEditingController(text: '${_c.paymentDays}'),
      'fee': TextEditingController(text: numText(_c.reminderFee)),
    };
    final section = widget.section;
    if (section != null && section != CompanySection.company) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[section]!.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
      });
    }
  }

  @override
  void dispose() {
    for (final c in _t.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _v(String k) => _t[k]!.text.trim();

  void _save() {
    if (!_form.currentState!.validate()) return;
    _c
      ..name = _v('name')
      ..owner = _v('owner')
      ..street = _v('street')
      ..zip = _v('zip')
      ..city = _v('city')
      ..phone = _v('phone')
      ..email = _v('email')
      ..website = _v('website')
      ..taxNumber = _v('taxNumber')
      ..vatId = _v('vatId').toUpperCase().replaceAll(' ', '')
      ..taxOffice = _v('taxOffice')
      ..bankName = _v('bankName')
      ..iban = _v('iban').toUpperCase().replaceAll(' ', '')
      ..bic = _v('bic').toUpperCase().replaceAll(' ', '')
      ..accountHolder = _v('holder')
      ..invoicePrefix = _v('invoicePrefix')
      ..quotePrefix = _v('quotePrefix')
      ..nextInvoiceNo = int.tryParse(_v('nextInvoice')) ?? _c.nextInvoiceNo
      ..nextQuoteNo = int.tryParse(_v('nextQuote')) ?? _c.nextQuoteNo
      ..paymentDays = int.tryParse(_v('payDays')) ?? 14
      ..reminderFee = parseNum(_v('fee'));
    context.read<Store>().updateCompany(_c);
    toast(context, 'Saved'.tr);
    Navigator.pop(context);
  }

  Widget _f(String k, String label, {TextInputType? type, String? hint, String? Function(String?)? validator, IconData? icon}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _t[k],
      keyboardType: type,
      validator: validator,
      decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: icon == null ? null : Icon(icon)),
    ),
  );

  Widget _section(CompanySection s, IconData icon, String title, String? hint, List<Widget> children) => Padding(
    key: _keys[s],
    padding: const EdgeInsets.only(bottom: 14),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: brandGreenDark),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(hint, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    ),
  );

  static String? _ibanCheck(String? v) {
    final s = (v ?? '').replaceAll(' ', '').toUpperCase();
    if (s.isEmpty) return null;
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]{10,30}$').hasMatch(s)) return 'Invalid IBAN'.tr;
    final rearranged = s.substring(4) + s.substring(0, 4);
    final digits = rearranged.split('').map((ch) {
      final c = ch.codeUnitAt(0);
      return c >= 65 ? '${c - 55}' : ch;
    }).join();
    var rem = 0;
    for (final ch in digits.split('')) {
      rem = (rem * 10 + int.parse(ch)) % 97;
    }
    return rem == 1 ? null : 'IBAN check digits are wrong – please check'.tr;
  }

  static String? _vatIdCheck(String? v) {
    final s = (v ?? '').replaceAll(' ', '').toUpperCase();
    if (s.isEmpty) return null;
    return RegExp(r'^DE[0-9]{9}$').hasMatch(s) ? null : 'German VAT ID looks like DE123456789'.tr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Company & tax info'.tr)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check_rounded), label: Text('Save'.tr)),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            _section(CompanySection.company, Icons.business_rounded, 'Company'.tr, 'Printed at the top and bottom of every invoice.'.tr, [
              _f('name', 'Company name'.tr, icon: Icons.storefront_rounded),
              _f('owner', 'Owner (Inhaber) – full legal name'.tr, icon: Icons.person_rounded),
              _f('street', 'Street & house number'.tr, icon: Icons.signpost_rounded),
              Row(
                children: [
                  SizedBox(width: 120, child: _f('zip', 'ZIP'.tr, type: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _f('city', 'City'.tr)),
                ],
              ),
              _f('phone', 'Phone'.tr, type: TextInputType.phone, icon: Icons.phone_rounded),
              _f('email', 'Email'.tr, type: TextInputType.emailAddress, icon: Icons.alternate_email_rounded),
              _f('website', 'Website'.tr, type: TextInputType.url, icon: Icons.language_rounded),
            ]),
            _section(
              CompanySection.tax,
              Icons.account_balance_rounded,
              'Tax information'.tr,
              'German law (§14 UStG) requires your tax number (Steuernummer) OR your VAT ID (USt-IdNr.) on every invoice. You find them on letters from your Finanzamt.'
                  .tr,
              [
                _f('taxNumber', 'Tax number (Steuernummer)'.tr, hint: 'e.g. 12/345/67890', icon: Icons.numbers_rounded),
                _f('vatId', 'VAT ID (USt-IdNr.)'.tr, hint: 'e.g. DE123456789'.tr, validator: _vatIdCheck, icon: Icons.badge_rounded),
                _f('taxOffice', 'Tax office (Finanzamt)'.tr, hint: 'e.g. Berlin-Mitte'.tr, icon: Icons.account_balance_outlined),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _c.smallBusiness,
                  onChanged: (v) => setState(() => _c.smallBusiness = v),
                  title: Text('Small business (Kleinunternehmer §19 UStG)'.tr),
                  subtitle: Text('Turn on only if you do NOT charge VAT. Invoices then show "Gemäß § 19 UStG wird keine Umsatzsteuer berechnet."'.tr),
                ),
                if (!_c.smallBusiness) ...[
                  const SizedBox(height: 6),
                  Text('Default VAT rate'.tr, style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 19, label: Text('19 %')),
                      ButtonSegment(value: 7, label: Text('7 %')),
                      ButtonSegment(value: 0, label: Text('0 %')),
                    ],
                    selected: {_c.defaultVatRate},
                    onSelectionChanged: (v) => setState(() => _c.defaultVatRate = v.first),
                  ),
                ],
              ],
            ),
            _section(
              CompanySection.bank,
              Icons.credit_card_rounded,
              'Bank details'.tr,
              'Printed on invoices together with a GiroCode QR – customers scan it in their banking app and pay instantly.'.tr,
              [
                _f('holder', 'Account holder'.tr, icon: Icons.person_outline_rounded),
                _f('bankName', 'Bank name'.tr, icon: Icons.account_balance_rounded),
                _f('iban', 'IBAN', hint: 'DE..', validator: _ibanCheck, icon: Icons.credit_card_rounded),
                _f('bic', 'BIC (optional)'.tr, icon: Icons.code_rounded),
              ],
            ),
            _section(
              CompanySection.invoice,
              Icons.tag_rounded,
              'Invoice numbers & terms'.tr,
              'Invoice numbers must be unique and continuous. Format: PREFIX-YEAR-NUMBER, e.g. RE-2026-0001.'.tr,
              [
                Row(
                  children: [
                    Expanded(child: _f('invoicePrefix', 'Invoice prefix'.tr)),
                    const SizedBox(width: 10),
                    Expanded(child: _f('nextInvoice', 'Next invoice no.'.tr, type: TextInputType.number)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _f('quotePrefix', 'Quote prefix'.tr)),
                    const SizedBox(width: 10),
                    Expanded(child: _f('nextQuote', 'Next quote no.'.tr, type: TextInputType.number)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _f('payDays', 'Days to pay'.tr, type: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _f('fee', 'Reminder fee €'.tr, type: const TextInputType.numberWithOptions(decimal: true))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
