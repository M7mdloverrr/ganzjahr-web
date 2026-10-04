import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'catalog.dart';
import 'customers.dart';
import 'document_view.dart';
import '../i18n.dart';

class DocumentEditScreen extends StatefulWidget {
  final DocKind kind;
  final Customer? customer;
  final Document? existing;
  final Document? prefilled;

  const DocumentEditScreen({super.key, required this.kind, this.customer, this.existing, this.prefilled});

  @override
  State<DocumentEditScreen> createState() => _DocumentEditScreenState();
}

class _DocumentEditScreenState extends State<DocumentEditScreen> {
  late Document _d;
  late final TextEditingController _intro;
  late final TextEditingController _notes;
  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final store = context.read<Store>();
    _d = widget.existing != null
        ? Document.fromJson(widget.existing!.toJson())
        : widget.prefilled ?? store.draftFor(kind: widget.kind, customer: widget.customer);
    _intro = TextEditingController(text: _d.intro);
    _notes = TextEditingController(text: _d.notes);
  }

  @override
  void dispose() {
    _intro.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _setCustomer(Customer c) => setState(() {
    _d.customerId = c.id;
    _d.customerSnapshot = c.toJson();
    _d.showLabourNote = c.type == CustomerType.private;
  });

  Future<void> _pickCustomer() async {
    final store = context.read<Store>();
    final picked = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _CustomerPicker(customers: store.customers),
    );
    if (!mounted) return;
    if (picked is Customer) {
      _setCustomer(picked);
    } else if (picked == 'new') {
      final c = await Navigator.push<Customer>(context, MaterialPageRoute(builder: (_) => const CustomerEditScreen()));
      if (c != null) _setCustomer(c);
    }
  }

  Future<void> _addFromCatalog() async {
    final item = await Navigator.push<CatalogItem>(context, MaterialPageRoute(builder: (_) => const CatalogScreen(picker: true)));
    if (item == null) return;
    setState(
      () => _d.items.add(
        LineItem(
          title: item.title,
          description: item.description,
          unit: item.unit,
          unitPrice: item.price,
          vatRate: context.read<Store>().company.defaultVatRate,
          isLabour: item.isLabour,
        ),
      ),
    );
  }

  void _addBlank() => setState(() => _d.items.add(LineItem(vatRate: context.read<Store>().company.defaultVatRate)));

  Future<DateTime?> _pickDate(DateTime? initial) =>
      showDatePicker(context: context, initialDate: initial ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));

  void _save({required bool draft}) {
    if (_d.customerId.isEmpty) {
      toast(context, 'Please choose a customer first.'.tr);
      return;
    }
    _d.items.removeWhere((i) => i.title.trim().isEmpty && i.unitPrice == 0);
    if (_d.items.isEmpty) {
      toast(context, 'Add at least one item.'.tr);
      setState(() {});
      return;
    }
    if (_d.items.any((i) => i.title.trim().isEmpty)) {
      toast(context, 'Every item needs a description.'.tr);
      return;
    }
    _d.intro = _intro.text.trim();
    _d.notes = _notes.text.trim();
    if (draft) {
      _d.status = DocStatus.draft;
    } else if (_d.status == DocStatus.draft) {
      _d.status = DocStatus.open;
    }
    final store = context.read<Store>();
    final saved = store.saveDocument(_d);
    if (_isNew) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DocumentViewScreen(docId: saved.id)));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    final isInvoice = _d.isInvoice;
    final t = _d.totals;
    final cust = _d.customerId.isEmpty ? null : _d.customer;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isNew ? (isInvoice ? 'New invoice'.tr : 'New quote'.tr) : 'Edit {n}'.trf({'n': _d.number}),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [if (_isNew || _d.status == DocStatus.draft) TextButton(onPressed: () => _save(draft: true), child: Text('Save draft'.tr))],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE3E9E0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_d.smallBusiness ? 'Total'.tr : 'Total incl. VAT'.tr, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    Text(
                      eur(t.gross),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: brandInk),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _save(draft: false),
                icon: const Icon(Icons.check_rounded),
                label: Text(_isNew ? (isInvoice ? 'Create invoice'.tr : 'Create quote'.tr) : 'Save'.tr),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Card(
            child: ListTile(
              onTap: _pickCustomer,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: const CircleAvatar(
                backgroundColor: Color(0x2263B32A),
                child: Icon(Icons.person_rounded, color: brandGreenDark),
              ),
              title: Text(cust?.displayName ?? 'Choose customer'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                cust == null ? 'Tap to select or add a customer'.tr : [cust.street, cust.cityLine].where((e) => e.isNotEmpty).join(', '),
              ),
              trailing: const Icon(Icons.swap_horiz_rounded),
            ),
          ),
          SectionTitle('Details'.tr),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _InfoRow(
                    label: isInvoice ? 'Invoice no.'.tr : 'Quote no.'.tr,
                    value: _isNew ? '{n} (auto)'.trf({'n': store.peekNumber(_d.kind)}) : _d.number,
                  ),
                  _DateRow(
                    label: isInvoice ? 'Invoice date'.tr : 'Date'.tr,
                    value: _d.date,
                    onTap: () async {
                      final v = await _pickDate(_d.date);
                      if (v != null) {
                        setState(() {
                          final diff = _d.dueDate.difference(_d.date);
                          _d.date = v;
                          _d.dueDate = v.add(diff);
                        });
                      }
                    },
                  ),
                  if (isInvoice) ...[
                    _DateRow(
                      label: 'Service date (from)'.tr,
                      value: _d.serviceFrom,
                      onTap: () async {
                        final v = await _pickDate(_d.serviceFrom);
                        if (v != null) setState(() => _d.serviceFrom = v);
                      },
                    ),
                    _DateRow(
                      label: 'Service until (optional)'.tr,
                      value: _d.serviceTo,
                      onTap: () async {
                        final v = await _pickDate(_d.serviceTo ?? _d.serviceFrom);
                        if (v != null) setState(() => _d.serviceTo = v);
                      },
                      onClear: _d.serviceTo == null ? null : () => setState(() => _d.serviceTo = null),
                    ),
                  ],
                  _DateRow(
                    label: isInvoice ? 'Payment due'.tr : 'Valid until'.tr,
                    value: _d.dueDate,
                    onTap: () async {
                      final v = await _pickDate(_d.dueDate);
                      if (v != null) setState(() => _d.dueDate = v);
                    },
                  ),
                  if (isInvoice)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                      child: Wrap(
                        spacing: 6,
                        children: [
                          for (final days in [7, 14, 30])
                            ActionChip(
                              label: Text('{d} days'.trf({'d': days})),
                              onPressed: () => setState(() => _d.dueDate = _d.date.add(Duration(days: days))),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SectionTitle('Items ({n})'.trf({'n': _d.items.length})),
          ..._d.items.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ItemEditor(
                key: ObjectKey(e.value),
                index: e.key,
                item: e.value,
                smallBusiness: _d.smallBusiness,
                onChanged: () => setState(() {}),
                onRemove: () => setState(() => _d.items.removeAt(e.key)),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _addFromCatalog,
                  icon: const Icon(Icons.handyman_rounded),
                  label: Text('From price list'.tr),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(onPressed: _addBlank, icon: const Icon(Icons.add), label: Text('Custom item'.tr)),
              ),
            ],
          ),
          SectionTitle('Totals'.tr),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (!_d.smallBusiness) ...[
                    _TotalRow('Net'.tr, eur(t.net)),
                    for (final e in t.vatByRate.entries) _TotalRow('VAT {r}'.trf({'r': vatLabel(e.key)}), eur(e.value)),
                    const Divider(),
                  ],
                  _TotalRow('Total'.tr, eur(t.gross), strong: true),
                  if (t.labourGross > 0) _TotalRow('of which labour (§35a)'.tr, eur(t.labourGross)),
                ],
              ),
            ),
          ),
          SectionTitle('Options & text'.tr),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _d.showLabourNote,
                  onChanged: (v) => setState(() => _d.showLabourNote = v),
                  title: Text('Show §35a labour-cost note'.tr),
                  subtitle: Text('Private customers can deduct 20 % of labour costs from their taxes.'.tr),
                ),
                SwitchListTile(
                  value: _d.smallBusiness,
                  onChanged: (v) => setState(() => _d.smallBusiness = v),
                  title: Text('Small business – no VAT (§19 UStG)'.tr),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _intro,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(labelText: 'Intro text (German, optional)'.tr, hintText: 'Leave empty for the standard text'.tr),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notes,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(labelText: 'Closing note on the PDF (German, optional)'.tr),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
  );
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _DateRow({required this.label, required this.value, required this.onTap, this.onClear});

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    onTap: onTap,
    title: Text(label),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value == null ? '—' : dmy(value!), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        if (onClear != null)
          IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded, size: 18), visualDensity: VisualDensity.compact)
        else
          const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.edit_calendar_rounded, size: 18)),
      ],
    ),
  );
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  const _TotalRow(this.label, this.value, {this.strong = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: strong ? 18 : 14,
      fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
      color: strong ? brandInk : Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _ItemEditor extends StatefulWidget {
  final int index;
  final LineItem item;
  final bool smallBusiness;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _ItemEditor({
    super.key,
    required this.index,
    required this.item,
    required this.smallBusiness,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late final TextEditingController _title = TextEditingController(text: widget.item.title);
  late final TextEditingController _desc = TextEditingController(text: widget.item.description);
  late final TextEditingController _qty = TextEditingController(text: numText(widget.item.quantity));
  late final TextEditingController _unit = TextEditingController(text: widget.item.unit);
  late final TextEditingController _price = TextEditingController(text: numText(widget.item.unitPrice));

  @override
  void initState() {
    super.initState();
    _title.addListener(() => widget.item.title = _title.text);
    _desc.addListener(() => widget.item.description = _desc.text);
    _unit.addListener(() => widget.item.unit = _unit.text);
    _qty.addListener(() {
      widget.item.quantity = parseNum(_qty.text);
      widget.onChanged();
    });
    _price.addListener(() {
      widget.item.unitPrice = parseNum(_price.text);
      widget.onChanged();
    });
  }

  @override
  void dispose() {
    for (final c in [_title, _desc, _qty, _unit, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    const num = TextInputType.numberWithOptions(decimal: true);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: brandInk,
                  child: Text('${widget.index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(eur(it.net), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.delete_outline_rounded), tooltip: 'Remove'.tr),
              ],
            ),
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: 'Service (German, e.g. Heckenschnitt)'.tr),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              maxLines: 2,
              minLines: 1,
              decoration: InputDecoration(labelText: 'Details (optional)'.tr),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _qty,
                    keyboardType: num,
                    decoration: InputDecoration(labelText: 'Qty'.tr),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(flex: 4, child: UnitField(controller: _unit)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _price,
                    keyboardType: num,
                    decoration: InputDecoration(labelText: 'Net price €'.tr),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (!widget.smallBusiness) ...[
                  Text('VAT'.tr),
                  const SizedBox(width: 8),
                  DropdownButton<double>(
                    value: [19.0, 7.0, 0.0].contains(it.vatRate) ? it.vatRate : 19.0,
                    underline: const SizedBox(),
                    items: const [19.0, 7.0, 0.0].map((r) => DropdownMenuItem(value: r, child: Text(vatLabel(r)))).toList(),
                    onChanged: (v) {
                      setState(() => it.vatRate = v!);
                      widget.onChanged();
                    },
                  ),
                ],
                const Spacer(),
                Text('Labour'.tr),
                Switch(
                  value: it.isLabour,
                  onChanged: (v) {
                    setState(() => it.isLabour = v);
                    widget.onChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerPicker extends StatefulWidget {
  final List<Customer> customers;
  const _CustomerPicker({required this.customers});

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final list = widget.customers.where((c) => q.isEmpty || '${c.displayName} ${c.number} ${c.city}'.toLowerCase().contains(q)).toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: widget.customers.length > 8,
              decoration: InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search customer'.tr),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: brandGreenDark,
              child: Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
            ),
            title: Text('New customer'.tr, style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => Navigator.pop(context, 'new'),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: list
                  .map(
                    (c) => ListTile(
                      title: Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text([c.number, c.city].where((e) => e.isNotEmpty).join(' · ')),
                      onTap: () => Navigator.pop(context, c),
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
