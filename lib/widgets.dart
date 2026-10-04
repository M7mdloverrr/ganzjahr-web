import 'package:flutter/material.dart';

import 'format.dart';
import 'models.dart';
import 'theme.dart';
import 'i18n.dart';

class StatusChip extends StatelessWidget {
  final Document doc;
  const StatusChip(this.doc, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(doc);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(20)),
      child: Text(
        statusLabel(doc),
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class DocTile extends StatelessWidget {
  final Document doc;
  final VoidCallback onTap;
  final bool showCustomer;
  const DocTile(this.doc, {super.key, required this.onTap, this.showCustomer = true});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: (doc.isInvoice ? brandGreen : brandFrost).withValues(alpha: 0.15),
        child: Icon(
          doc.isInvoice ? Icons.receipt_long_rounded : Icons.request_quote_rounded,
          color: doc.isInvoice ? brandGreenDark : brandFrost,
          size: 20,
        ),
      ),
      title: Text(
        showCustomer ? doc.customer.displayName : doc.number,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(showCustomer ? '${doc.number} · ${dmy(doc.date)}' : dmy(doc.date)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(eur(doc.totals.gross), style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          StatusChip(doc),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: brandInk),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: brandGreen),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}

Future<bool> confirm(BuildContext context, String title, String message, {String? ok}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel'.tr)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ok ?? 'Delete'.tr)),
      ],
    ),
  );
  return r ?? false;
}

void toast(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
