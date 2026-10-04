import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../format.dart';
import '../models.dart';
import '../pdf/invoice_pdf.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'document_edit.dart';
import 'document_view.dart';
import 'pdf_actions.dart';
import '../i18n.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

enum _Sort { name, number, revenue, open }

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';
  _Sort _sort = _Sort.name;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final q = _query.toLowerCase();
    final list = s.customers.where((c) {
      if (q.isEmpty) return true;
      return [c.displayName, c.name, c.number, c.city, c.street, c.email, c.phone, c.propertyAddress].any((f) => f.toLowerCase().contains(q));
    }).toList();
    double openFor(Customer c) => s.docsFor(c.id).where((d) => d.isInvoice && d.status == DocStatus.open).fold(0.0, (a, d) => a + d.totals.gross);
    switch (_sort) {
      case _Sort.name:
        list.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      case _Sort.number:
        list.sort((a, b) => a.number.compareTo(b.number));
      case _Sort.revenue:
        list.sort((a, b) => s.revenueFor(b.id).compareTo(s.revenueFor(a.id)));
      case _Sort.open:
        list.sort((a, b) => openFor(b).compareTo(openFor(a)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Customers'.tr),
        actions: [
          PopupMenuButton<_Sort>(
            icon: const Icon(Icons.sort_rounded),
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              PopupMenuItem(value: _Sort.name, child: Text('Sort by name'.tr)),
              PopupMenuItem(value: _Sort.number, child: Text('Sort by customer no.'.tr)),
              PopupMenuItem(value: _Sort.revenue, child: Text('Sort by revenue'.tr)),
              PopupMenuItem(value: _Sort.open, child: Text('Sort by outstanding'.tr)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-customers',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerEditScreen())),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text('Customer'.tr),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search name, city, phone, no. …'.tr),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: s.customers.isEmpty
                ? EmptyState(
                    icon: Icons.people_alt_rounded,
                    title: 'No customers yet'.tr,
                    message: 'Add your first customer to start writing invoices.'.tr,
                    action: FilledButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerEditScreen())),
                      icon: const Icon(Icons.add),
                      label: Text('Add customer'.tr),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final c = list[i];
                      final open = openFor(c);
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: c.id))),
                          leading: CircleAvatar(
                            backgroundColor: (c.type == CustomerType.business ? brandInk2 : brandGreen).withValues(alpha: 0.15),
                            child: Text(
                              c.displayName.isEmpty ? '?' : c.displayName.characters.first.toUpperCase(),
                              style: TextStyle(fontWeight: FontWeight.w800, color: c.type == CustomerType.business ? brandInk2 : brandGreenDark),
                            ),
                          ),
                          title: Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text([c.number, if (c.city.isNotEmpty) c.city].join(' · ')),
                          trailing: open > 0
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      eur(open),
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB57A00)),
                                    ),
                                    const Text('open', style: TextStyle(fontSize: 11, color: Colors.black45)),
                                  ],
                                )
                              : const Icon(Icons.chevron_right_rounded),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CustomerEditScreen extends StatefulWidget {
  final Customer? customer;
  const CustomerEditScreen({super.key, this.customer});

  @override
  State<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends State<CustomerEditScreen> {
  final _form = GlobalKey<FormState>();
  late final Customer _c;
  late CustomerType _type;
  late final Map<String, TextEditingController> _t;

  @override
  void initState() {
    super.initState();
    final store = context.read<Store>();
    _c = widget.customer ?? Customer(id: newId(), number: store.nextCustomerNumber());
    _type = _c.type;
    _t = {
      'company': TextEditingController(text: _c.company),
      'name': TextEditingController(text: _c.name),
      'street': TextEditingController(text: _c.street),
      'zip': TextEditingController(text: _c.zip),
      'city': TextEditingController(text: _c.city),
      'email': TextEditingController(text: _c.email),
      'phone': TextEditingController(text: _c.phone),
      'property': TextEditingController(text: _c.propertyAddress),
      'vat': TextEditingController(text: _c.vatId),
      'notes': TextEditingController(text: _c.notes),
    };
  }

  @override
  void dispose() {
    for (final c in _t.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    _c
      ..type = _type
      ..company = _type == CustomerType.business ? _t['company']!.text.trim() : ''
      ..name = _t['name']!.text.trim()
      ..street = _t['street']!.text.trim()
      ..zip = _t['zip']!.text.trim()
      ..city = _t['city']!.text.trim()
      ..email = _t['email']!.text.trim()
      ..phone = _t['phone']!.text.trim()
      ..propertyAddress = _t['property']!.text.trim()
      ..vatId = _t['vat']!.text.trim()
      ..notes = _t['notes']!.text.trim();
    context.read<Store>().upsertCustomer(_c);
    Navigator.pop(context, _c);
  }

  Widget _field(String key, String label, {TextInputType? type, String? Function(String?)? validator, int lines = 1, IconData? icon}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _t[key],
      keyboardType: type,
      maxLines: lines,
      minLines: 1,
      textCapitalization: type == null ? TextCapitalization.words : TextCapitalization.none,
      decoration: InputDecoration(labelText: label, prefixIcon: icon == null ? null : Icon(icon)),
      validator: validator,
    ),
  );

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Required'.tr : null;

  @override
  Widget build(BuildContext context) {
    final isNew = widget.customer == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'New customer'.tr : 'Edit customer'.tr)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<CustomerType>(
              segments: [
                ButtonSegment(value: CustomerType.private, label: Text('Private'.tr), icon: Icon(Icons.home_rounded)),
                ButtonSegment(value: CustomerType.business, label: Text('Business'.tr), icon: Icon(Icons.business_rounded)),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() => _type = v.first),
            ),
            const SizedBox(height: 16),
            Text(
              'Customer no. {n}'.trf({'n': _c.number}),
              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_type == CustomerType.business) _field('company', 'Company name'.tr, validator: _required, icon: Icons.business_rounded),
            _field(
              'name',
              _type == CustomerType.business ? 'Contact person'.tr : 'Full name (e.g. Herr Max Müller)'.tr,
              validator: _type == CustomerType.private ? _required : null,
              icon: Icons.person_rounded,
            ),
            _field('street', 'Street & house number'.tr, validator: _required, icon: Icons.signpost_rounded),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: _field('zip', 'ZIP'.tr, type: TextInputType.number, validator: _required),
                ),
                const SizedBox(width: 10),
                Expanded(child: _field('city', 'City'.tr, validator: _required)),
              ],
            ),
            _field('phone', 'Phone'.tr, type: TextInputType.phone, icon: Icons.phone_rounded),
            _field('email', 'Email'.tr, type: TextInputType.emailAddress, icon: Icons.alternate_email_rounded),
            _field('property', 'Service address (if different)'.tr, icon: Icons.location_on_rounded),
            if (_type == CustomerType.business) _field('vat', 'Customer VAT ID (optional)'.tr, type: TextInputType.text),
            _field('notes', 'Internal notes (gate code, dog, keys…)'.tr, lines: 4, icon: Icons.sticky_note_2_rounded),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check_rounded), label: Text('Save customer'.tr)),
          ],
        ),
      ),
    );
  }
}

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  Future<void> _launch(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) toast(context, 'No app found to open this.'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final c = s.customerById(customerId);
    if (c == null) return Scaffold(body: Center(child: Text('Customer deleted'.tr)));
    final docs = s.docsFor(c.id);
    final open = docs.where((d) => d.isInvoice && d.status == DocStatus.open).fold(0.0, (a, d) => a + d.totals.gross);
    final lastYear = DateTime.now().year - 1;
    final thisYear = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerEditScreen(customer: Customer.fromJson(c.toJson())))),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                final ok = await confirm(
                  context,
                  'Delete customer?'.tr,
                  'Invoices of this customer stay saved (with the address at the time of writing). This cannot be undone.'.tr,
                );
                if (ok && context.mounted) {
                  context.read<Store>().deleteCustomer(c.id);
                  Navigator.pop(context);
                }
              } else if (v.startsWith('cert')) {
                final year = int.parse(v.substring(4));
                final inv = s.labourInvoices(c.id, year);
                if (inv.isEmpty) {
                  toast(context, 'No paid invoices with labour costs in {year}.'.trf({'year': year}));
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewScreen(
                      title: '§35a certificate {year}'.trf({'year': year}),
                      fileName: safeFileName('Bescheinigung_35a_${year}_${c.displayName}.pdf'),
                      email: c.email,
                      emailSubject: 'Bescheinigung haushaltsnahe Dienstleistungen $year',
                      builder: () => buildLabourCertificatePdf(c, year, inv, s.company),
                    ),
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'cert$lastYear', child: Text('Tax certificate §35a ({year})'.trf({'year': lastYear}))),
              PopupMenuItem(value: 'cert$thisYear', child: Text('Tax certificate §35a ({year})'.trf({'year': thisYear}))),
              PopupMenuItem(value: 'delete', child: Text('Delete customer'.tr)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-customer-detail',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentEditScreen(kind: DocKind.invoice, customer: c),
          ),
        ),
        icon: const Icon(Icons.receipt_long_rounded),
        label: Text('New invoice'.tr),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(label: Text(c.type == CustomerType.business ? 'Business'.tr : 'Private'.tr), visualDensity: VisualDensity.compact),
                      const SizedBox(width: 8),
                      Text(
                        c.number,
                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...c.addressLines.map((l) => Text(l, style: const TextStyle(fontSize: 15))),
                  if (c.propertyAddress.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: brandGreenDark),
                        const SizedBox(width: 4),
                        Expanded(child: Text('Service address: {a}'.trf({'a': c.propertyAddress}))),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (c.phone.isNotEmpty)
                        ActionChip(
                          avatar: const Icon(Icons.phone_rounded, size: 18),
                          label: Text('Call'.tr),
                          onPressed: () => _launch(context, Uri(scheme: 'tel', path: c.phone)),
                        ),
                      if (c.phone.isNotEmpty)
                        ActionChip(
                          avatar: const Icon(Icons.chat_rounded, size: 18),
                          label: const Text('WhatsApp'),
                          onPressed: () => _launch(context, Uri.parse('https://wa.me/${_waNumber(c.phone)}')),
                        ),
                      if (c.email.isNotEmpty)
                        ActionChip(
                          avatar: const Icon(Icons.email_rounded, size: 18),
                          label: Text('Email'.tr),
                          onPressed: () => _launch(context, Uri(scheme: 'mailto', path: c.email)),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.map_rounded, size: 18),
                        label: Text('Navigate'.tr),
                        onPressed: () => _launch(
                          context,
                          Uri.https('www.google.com', '/maps/search/', {
                            'api': '1',
                            'query': c.propertyAddress.isNotEmpty ? c.propertyAddress : '${c.street}, ${c.cityLine}',
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Stat(label: 'Total invoiced'.tr, value: eur(s.revenueFor(c.id))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(label: 'Outstanding'.tr, value: eur(open), color: open > 0 ? const Color(0xFFB57A00) : null),
              ),
            ],
          ),
          if (c.notes.isNotEmpty) ...[
            SectionTitle('Notes'.tr),
            Card(
              child: Padding(padding: const EdgeInsets.all(14), child: Text(c.notes)),
            ),
          ],
          SectionTitle(
            'Invoices & quotes'.tr,
            trailing: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentEditScreen(kind: DocKind.quote, customer: c),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Quote'.tr),
            ),
          ),
          if (docs.isEmpty)
            Card(
              child: Padding(padding: EdgeInsets.all(16), child: Text('Nothing yet.'.tr)),
            )
          else
            Card(
              child: Column(
                children: docs
                    .map(
                      (d) => DocTile(
                        d,
                        showCustomer: false,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentViewScreen(docId: d.id))),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

String _waNumber(String phone) {
  var p = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (p.startsWith('+')) return p.substring(1);
  if (p.startsWith('00')) return p.substring(2);
  if (p.startsWith('0')) return '49${p.substring(1)}';
  return p;
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color ?? brandInk),
          ),
        ],
      ),
    ),
  );
}
