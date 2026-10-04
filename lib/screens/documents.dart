import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../widgets.dart';
import 'document_edit.dart';
import 'document_view.dart';
import '../i18n.dart';

enum _Filter { all, open, overdue, paid, draft }

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  DocKind _kind = DocKind.invoice;
  _Filter _filter = _Filter.all;
  String _query = '';

  bool _match(Document d) {
    switch (_filter) {
      case _Filter.all:
        break;
      case _Filter.open:
        if (d.status != DocStatus.open) return false;
      case _Filter.overdue:
        if (!d.isOverdue) return false;
      case _Filter.paid:
        if (d.status != DocStatus.paid && d.status != DocStatus.accepted) return false;
      case _Filter.draft:
        if (d.status != DocStatus.draft) return false;
    }
    final q = _query.toLowerCase();
    if (q.isEmpty) return true;
    return d.number.toLowerCase().contains(q) ||
        d.customer.displayName.toLowerCase().contains(q) ||
        d.items.any((i) => i.title.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final list = s.documents.where((d) => d.kind == _kind && _match(d)).toList()
      ..sort((a, b) {
        final c = b.date.compareTo(a.date);
        return c != 0 ? c : b.number.compareTo(a.number);
      });
    final filters = {
      _Filter.all: 'All'.tr,
      _Filter.open: 'Open'.tr,
      if (_kind == DocKind.invoice) _Filter.overdue: 'Overdue'.tr,
      _Filter.paid: _kind == DocKind.invoice ? 'Paid'.tr : 'Accepted'.tr,
      _Filter.draft: 'Drafts'.tr,
    };
    return Scaffold(
      appBar: AppBar(title: Text('Invoices & quotes'.tr)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-docs',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentEditScreen(kind: _kind))),
        icon: const Icon(Icons.add),
        label: Text(_kind == DocKind.invoice ? 'Invoice'.tr : 'Quote'.tr),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SegmentedButton<DocKind>(
              segments: [
                ButtonSegment(value: DocKind.invoice, label: Text('Invoices'.tr), icon: Icon(Icons.receipt_long_rounded)),
                ButtonSegment(value: DocKind.quote, label: Text('Quotes'.tr), icon: Icon(Icons.request_quote_rounded)),
              ],
              selected: {_kind},
              onSelectionChanged: (v) => setState(() {
                _kind = v.first;
                _filter = _Filter.all;
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search number, customer, service…'.tr),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: filters.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(label: Text(e.value), selected: _filter == e.key, onSelected: (_) => setState(() => _filter = e.key)),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? EmptyState(
                    icon: _kind == DocKind.invoice ? Icons.receipt_long_rounded : Icons.request_quote_rounded,
                    title: 'Nothing here'.tr,
                    message: _kind == DocKind.invoice
                        ? 'Create an invoice and it will show up here.'.tr
                        : 'Quotes can be turned into invoices with one tap.'.tr,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    children: [
                      Card(
                        child: Column(
                          children: list
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
        ],
      ),
    );
  }
}
