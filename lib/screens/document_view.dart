import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models.dart';
import '../pdf/invoice_pdf.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'document_edit.dart';
import 'pdf_actions.dart';
import '../i18n.dart';

class DocumentViewScreen extends StatelessWidget {
  final String docId;
  const DocumentViewScreen({super.key, required this.docId});

  String _fileName(Document d) => safeFileName('${d.isInvoice ? 'Rechnung' : 'Angebot'}_${d.number}_${d.customer.displayName}.pdf');

  Future<void> _menu(BuildContext context, Store s, Document d, String action) async {
    switch (action) {
      case 'edit':
        if (d.isInvoice && d.status != DocStatus.draft) {
          final ok = await confirm(
            context,
            'Edit issued invoice?'.tr,
            'In Germany an invoice that was already sent should not be changed. Better: cancel it and create a new one. Edit anyway?'.tr,
            ok: 'Edit'.tr,
          );
          if (!ok || !context.mounted) return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentEditScreen(kind: d.kind, existing: d),
          ),
        );
      case 'paid':
        s.setStatus(d, DocStatus.paid);
        toast(context, 'Marked as paid'.tr);
      case 'open':
        s.setStatus(d, DocStatus.open);
      case 'accepted':
        s.setStatus(d, DocStatus.accepted);
      case 'declined':
        s.setStatus(d, DocStatus.declined);
      case 'convert':
        if (d.status == DocStatus.open) s.setStatus(d, DocStatus.accepted);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentEditScreen(kind: DocKind.invoice, prefilled: s.invoiceFromQuote(d)),
          ),
        );
      case 'duplicate':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentEditScreen(kind: d.kind, prefilled: s.duplicate(d)),
          ),
        );
      case 'reminder':
        final level = d.reminderLevel.clamp(0, 2);
        final title = reminderTitle(level);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewScreen(
              title: title,
              fileName: safeFileName('${title}_${d.number}.pdf'),
              email: d.customer.email,
              emailSubject: '$title zur Rechnung ${d.number}',
              emailBody:
                  'Sehr geehrte Damen und Herren,\n\nanbei erhalten Sie unsere $title zur Rechnung ${d.number}.\n\nMit freundlichen Grüßen\n${s.company.name}',
              builder: () => buildReminderPdf(d, s.company, level: level),
              onOutput: () {
                if (d.reminderLevel == level) s.recordReminder(d);
              },
            ),
          ),
        );
      case 'cancel':
        final ok = await confirm(
          context,
          'Cancel invoice?'.tr,
          'The invoice stays in your records marked as cancelled (Storno). It no longer counts as income.'.tr,
          ok: 'Cancel invoice'.tr,
        );
        if (ok) s.setStatus(d, DocStatus.cancelled);
      case 'delete':
        final ok = await confirm(context, 'Delete?'.tr, 'This removes {n} completely.'.trf({'n': d.number}));
        if (ok && context.mounted) {
          s.deleteDocument(d.id);
          Navigator.pop(context);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    final d = s.documentById(docId);
    if (d == null) return Scaffold(body: Center(child: Text('Deleted'.tr)));
    final isInvoice = d.isInvoice;

    return Scaffold(
      appBar: AppBar(
        title: Text(d.number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _menu(context, s, d, v),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('Edit'.tr)),
              ),
              PopupMenuItem(
                value: 'duplicate',
                child: ListTile(leading: Icon(Icons.copy_rounded), title: Text('Duplicate (e.g. next month)'.tr)),
              ),
              if (isInvoice && d.status == DocStatus.open)
                PopupMenuItem(
                  value: 'reminder',
                  child: ListTile(leading: Icon(Icons.notification_important_rounded), title: Text('Payment reminder'.tr)),
                ),
              if (isInvoice && d.status == DocStatus.paid)
                PopupMenuItem(
                  value: 'open',
                  child: ListTile(leading: Icon(Icons.undo_rounded), title: Text('Mark as unpaid'.tr)),
                ),
              if (!isInvoice) ...[
                PopupMenuItem(
                  value: 'convert',
                  child: ListTile(leading: Icon(Icons.receipt_long_rounded), title: Text('Turn into invoice'.tr)),
                ),
                if (d.status != DocStatus.accepted)
                  PopupMenuItem(
                    value: 'accepted',
                    child: ListTile(leading: Icon(Icons.thumb_up_alt_rounded), title: Text('Mark accepted'.tr)),
                  ),
                if (d.status != DocStatus.declined)
                  PopupMenuItem(
                    value: 'declined',
                    child: ListTile(leading: Icon(Icons.thumb_down_alt_rounded), title: Text('Mark declined'.tr)),
                  ),
              ],
              if (isInvoice && d.status != DocStatus.cancelled && d.status != DocStatus.draft)
                PopupMenuItem(
                  value: 'cancel',
                  child: ListTile(leading: Icon(Icons.block_rounded), title: Text('Cancel (Storno)'.tr)),
                ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(leading: Icon(Icons.delete_rounded), title: Text('Delete'.tr)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3E9E0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.customer.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StatusChip(d),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              d.status == DocStatus.paid && d.paidAt != null
                                  ? 'paid {date}'.trf({'date': dmy(d.paidAt!)})
                                  : (isInvoice ? 'due {date}' : 'valid until {date}').trf({'date': dmy(d.dueDate)}) +
                                        (d.reminderLevel > 0 ? ' · {n}× reminded'.trf({'n': d.reminderLevel}) : ''),
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created {dt}'.trf({'dt': dmyHm(d.createdAt).replaceAll(' Uhr', '')}),
                        style: const TextStyle(color: Colors.black45, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      eur(d.totals.gross),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: brandInk),
                    ),
                    if (isInvoice && (d.status == DocStatus.open || d.status == DocStatus.draft))
                      TextButton.icon(
                        onPressed: () => _menu(context, s, d, d.status == DocStatus.draft ? 'open' : 'paid'),
                        icon: Icon(d.status == DocStatus.draft ? Icons.send_rounded : Icons.check_circle_rounded, size: 18),
                        label: Text(d.status == DocStatus.draft ? 'Finalize'.tr : 'Mark paid'.tr),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: brandGreenDark),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPane(
              key: ValueKey('${d.toJson()}${s.company.toJson()}'),
              fileName: _fileName(d),
              email: d.customer.email,
              emailSubject: '${isInvoice ? 'Rechnung' : 'Angebot'} ${d.number} – ${s.company.name}',
              emailBody:
                  'Sehr geehrte Damen und Herren,\n\nanbei erhalten Sie ${isInvoice ? 'unsere Rechnung' : 'unser Angebot'} ${d.number}.\n\n'
                  'Mit freundlichen Grüßen\n${s.company.owner.isNotEmpty ? s.company.owner : s.company.name}',
              builder: () => buildDocumentPdf(d, s.company),
            ),
          ),
        ],
      ),
    );
  }
}
