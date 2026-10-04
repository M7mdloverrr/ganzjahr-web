import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n.dart';

class CatalogScreen extends StatelessWidget {
  final bool picker;
  const CatalogScreen({super.key, this.picker = false});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Store>();
    return Scaffold(
      appBar: AppBar(title: Text(picker ? 'Pick a service'.tr : 'Services & prices'.tr)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-catalog',
        onPressed: () => showCatalogEditor(context),
        icon: const Icon(Icons.add),
        label: Text('Service'.tr),
      ),
      body: s.catalog.isEmpty
          ? EmptyState(
              icon: Icons.handyman_rounded,
              title: 'No services'.tr,
              message: 'Add your standard services and prices to fill invoices in seconds.'.tr,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                if (!picker)
                  Padding(
                    padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text(
                      'Your price list. Prices are net (without VAT). Tap to edit, long-press to delete.'.tr,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                for (final cat in ServiceCategory.values)
                  if (s.catalog.any((e) => e.category == cat)) ...[
                    SectionTitle(cat.label.tr),
                    Card(
                      child: Column(
                        children: s.catalog
                            .where((e) => e.category == cat)
                            .map(
                              (e) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: categoryColor(cat).withValues(alpha: 0.15),
                                  child: Icon(categoryIcon(cat), color: categoryColor(cat), size: 20),
                                ),
                                title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text('${eur(e.price)} / ${e.unit}${e.isLabour ? ' · labour'.tr : ''}'),
                                trailing: picker
                                    ? const Icon(Icons.add_circle_rounded, color: brandGreenDark)
                                    : const Icon(Icons.edit_rounded, size: 18),
                                onTap: () => picker ? Navigator.pop(context, e) : showCatalogEditor(context, item: e),
                                onLongPress: picker
                                    ? null
                                    : () async {
                                        if (await confirm(context, 'Delete service?'.tr, e.title) && context.mounted) {
                                          context.read<Store>().deleteCatalog(e.id);
                                        }
                                      },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
              ],
            ),
    );
  }
}

Future<void> showCatalogEditor(BuildContext context, {CatalogItem? item}) async {
  final it = item == null ? CatalogItem(id: newId(), title: '') : CatalogItem.fromJson(item.toJson());
  final title = TextEditingController(text: it.title);
  final desc = TextEditingController(text: it.description);
  final unit = TextEditingController(text: it.unit);
  final price = TextEditingController(text: numText(it.price));
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(item == null ? 'New service'.tr : 'Edit service'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Write the name in German – it is printed on the invoice.'.tr, style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                decoration: InputDecoration(labelText: 'Name (e.g. Heckenschnitt)'.tr),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: desc,
                decoration: InputDecoration(labelText: 'Description (optional)'.tr),
                maxLines: 2,
                minLines: 1,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: 'Net price €'.tr),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: UnitField(controller: unit)),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<ServiceCategory>(
                initialValue: it.category,
                decoration: InputDecoration(labelText: 'Category'.tr),
                items: ServiceCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label.tr))).toList(),
                onChanged: (v) => setSt(() {
                  it.category = v!;
                  if (v == ServiceCategory.material) it.isLabour = false;
                }),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: it.isLabour,
                onChanged: (v) => setSt(() => it.isLabour = v),
                title: Text('Labour / travel cost'.tr),
                subtitle: Text('Counts for the §35a tax note your private customers can claim.'.tr),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  if (title.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: Text('Save'.tr),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (saved == true && context.mounted) {
    it
      ..title = title.text.trim()
      ..description = desc.text.trim()
      ..unit = unit.text.trim().isEmpty ? 'Stk.' : unit.text.trim()
      ..price = parseNum(price.text);
    context.read<Store>().upsertCatalog(it);
  }
}

const commonUnits = ['Std.', 'Stk.', 'pauschal', 'm²', 'm', 'm³', 'kg', 'Einsatz', 'Monat', 'km'];

class UnitField extends StatelessWidget {
  final TextEditingController controller;
  const UnitField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: 'Unit'.tr,
      suffixIcon: PopupMenuButton<String>(
        icon: const Icon(Icons.arrow_drop_down_rounded),
        onSelected: (v) => controller.text = v,
        itemBuilder: (_) => commonUnits.map((u) => PopupMenuItem(value: u, child: Text(u))).toList(),
      ),
    ),
  );
}
