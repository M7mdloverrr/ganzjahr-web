import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';

int _idCounter = 0;
String newId() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_idCounter++).toRadixString(36)}';

List<CatalogItem> defaultCatalog() => [
  CatalogItem(id: newId(), title: 'Rasenmähen inkl. Entsorgung', unit: 'm²', price: 0.12, category: ServiceCategory.garten),
  CatalogItem(id: newId(), title: 'Heckenschnitt', unit: 'Std.', price: 45, category: ServiceCategory.garten),
  CatalogItem(id: newId(), title: 'Gartenpflege allgemein', unit: 'Std.', price: 42, category: ServiceCategory.garten),
  CatalogItem(id: newId(), title: 'Laubbeseitigung', unit: 'Std.', price: 40, category: ServiceCategory.garten),
  CatalogItem(id: newId(), title: 'Grünschnitt-Entsorgung', unit: 'm³', price: 35, category: ServiceCategory.material, isLabour: false),
  CatalogItem(id: newId(), title: 'Treppenhausreinigung', unit: 'pauschal', price: 85, category: ServiceCategory.objekt),
  CatalogItem(id: newId(), title: 'Hausmeisterservice', unit: 'Std.', price: 38, category: ServiceCategory.objekt),
  CatalogItem(id: newId(), title: 'Winterdienst Räumen & Streuen', unit: 'Einsatz', price: 30, category: ServiceCategory.winter),
  CatalogItem(id: newId(), title: 'Winterdienst Saisonpauschale', unit: 'Monat', price: 120, category: ServiceCategory.winter),
  CatalogItem(id: newId(), title: 'Streusalz / Splitt', unit: 'kg', price: 1.2, category: ServiceCategory.material, isLabour: false),
  CatalogItem(id: newId(), title: 'Anfahrtspauschale', unit: 'pauschal', price: 15, category: ServiceCategory.material),
];

class Store extends ChangeNotifier {
  Company company = Company();
  List<Customer> customers = [];
  List<CatalogItem> catalog = [];
  List<Document> documents = [];
  String language = 'en';
  bool loaded = false;
  File? _file;

  /// Called after every local change (used by cloud sync).
  void Function()? onLocalChange;

  Future<void> load() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/ganzjahr_data.json');
    if (await _file!.exists()) {
      importJson(await _file!.readAsString(), persist: false);
    } else {
      catalog = defaultCatalog();
    }
    loaded = true;
    notifyListeners();
  }

  String exportJson() => const JsonEncoder.withIndent(' ').convert({
    'app': 'ganzjahr_rechnung',
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'language': language,
    'company': company.toJson(),
    'customers': customers.map((e) => e.toJson()).toList(),
    'catalog': catalog.map((e) => e.toJson()).toList(),
    'documents': documents.map((e) => e.toJson()).toList(),
  });

  void importJson(String raw, {bool persist = true}) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    if (j['company'] == null && j['customers'] == null) {
      throw const FormatException('Not a GanzJahr backup file');
    }
    language = j['language'] as String? ?? language;
    company = Company.fromJson(Map<String, dynamic>.from(j['company'] ?? {}));
    customers = ((j['customers'] as List?) ?? []).map((e) => Customer.fromJson(Map<String, dynamic>.from(e))).toList();
    catalog = ((j['catalog'] as List?) ?? []).map((e) => CatalogItem.fromJson(Map<String, dynamic>.from(e))).toList();
    documents = ((j['documents'] as List?) ?? []).map((e) => Document.fromJson(Map<String, dynamic>.from(e))).toList();
    if (persist) _commit();
  }

  Future<void> _save() async {
    final f = _file;
    if (f == null) return;
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(exportJson(), flush: true);
    await tmp.rename(f.path);
  }

  void setLanguage(String code) {
    language = code;
    _commit();
  }

  void _commit() {
    notifyListeners();
    _save();
    onLocalChange?.call();
  }

  /// Applies data that came from the cloud without triggering another upload.
  void applyRemote(void Function() change) {
    change();
    notifyListeners();
    _save();
  }

  void updateCompany(Company c) {
    company = c;
    _commit();
  }

  Customer? customerById(String id) {
    for (final c in customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  String nextCustomerNumber() => 'K${company.nextCustomerNo}';

  void upsertCustomer(Customer c) {
    final i = customers.indexWhere((e) => e.id == c.id);
    if (i >= 0) {
      customers[i] = c;
    } else {
      customers.add(c);
      company.nextCustomerNo++;
    }
    _commit();
  }

  void deleteCustomer(String id) {
    customers.removeWhere((c) => c.id == id);
    _commit();
  }

  void upsertCatalog(CatalogItem item) {
    final i = catalog.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      catalog[i] = item;
    } else {
      catalog.add(item);
    }
    _commit();
  }

  void deleteCatalog(String id) {
    catalog.removeWhere((c) => c.id == id);
    _commit();
  }

  String peekNumber(DocKind kind) {
    final year = DateTime.now().year;
    final prefix = kind == DocKind.invoice ? company.invoicePrefix : company.quotePrefix;
    final n = kind == DocKind.invoice ? company.nextInvoiceNo : company.nextQuoteNo;
    return '$prefix-$year-${n.toString().padLeft(4, '0')}';
  }

  String _takeNumber(DocKind kind) {
    final number = peekNumber(kind);
    if (kind == DocKind.invoice) {
      company.nextInvoiceNo++;
    } else {
      company.nextQuoteNo++;
    }
    return number;
  }

  Document? documentById(String id) {
    for (final d in documents) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Saves a document. New documents receive the next sequential number.
  Document saveDocument(Document d) {
    final i = documents.indexWhere((e) => e.id == d.id);
    if (i >= 0) {
      documents[i] = d;
    } else {
      d.number = _takeNumber(d.kind);
      d.createdAt = DateTime.now();
      documents.add(d);
    }
    _commit();
    return d;
  }

  void deleteDocument(String id) {
    documents.removeWhere((d) => d.id == id);
    _commit();
  }

  void setStatus(Document d, DocStatus status) {
    d.status = status;
    d.paidAt = status == DocStatus.paid ? DateTime.now() : null;
    _commit();
  }

  void recordReminder(Document d) {
    d.reminderLevel++;
    d.lastReminderAt = DateTime.now();
    _commit();
  }

  Document draftFor({required DocKind kind, Customer? customer}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Document(
      id: newId(),
      kind: kind,
      number: peekNumber(kind),
      customerId: customer?.id ?? '',
      customerSnapshot: customer?.toJson() ?? {},
      date: today,
      dueDate: today.add(Duration(days: kind == DocKind.invoice ? company.paymentDays : 30)),
      serviceFrom: kind == DocKind.invoice ? today : null,
      smallBusiness: company.smallBusiness,
      showLabourNote: customer?.type != CustomerType.business,
    );
  }

  Document invoiceFromQuote(Document q) {
    final d = draftFor(kind: DocKind.invoice, customer: customerById(q.customerId) ?? q.customer);
    d.items = q.items.map((e) => e.copy()).toList();
    d.notes = q.notes;
    d.sourceQuoteNumber = q.number;
    return d;
  }

  Document duplicate(Document src) {
    final d = draftFor(kind: src.kind, customer: customerById(src.customerId) ?? src.customer);
    d.items = src.items.map((e) => e.copy()).toList();
    d.intro = src.intro;
    d.notes = src.notes;
    d.showLabourNote = src.showLabourNote;
    return d;
  }

  List<Document> docsFor(String customerId) => documents.where((d) => d.customerId == customerId).toList()..sort((a, b) => b.date.compareTo(a.date));

  Iterable<Document> get invoices => documents.where((d) => d.isInvoice && d.status != DocStatus.draft && d.status != DocStatus.cancelled);

  double get openAmount => invoices.where((d) => d.status == DocStatus.open).fold(0, (a, d) => a + d.totals.gross);

  List<Document> get overdue => invoices.where((d) => d.isOverdue).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  double paidInMonth(int year, int month) => invoices
      .where((d) => d.status == DocStatus.paid && d.paidAt != null && d.paidAt!.year == year && d.paidAt!.month == month)
      .fold(0, (a, d) => a + d.totals.gross);

  double invoicedInMonth(int year, int month) =>
      invoices.where((d) => d.date.year == year && d.date.month == month).fold(0, (a, d) => a + d.totals.gross);

  double invoicedInYear(int year) => invoices.where((d) => d.date.year == year).fold(0, (a, d) => a + d.totals.gross);

  double revenueFor(String customerId) => invoices.where((d) => d.customerId == customerId).fold(0, (a, d) => a + d.totals.gross);

  /// Invoices of the previous year that included labour, for the §35a certificate.
  List<Document> labourInvoices(String customerId, int year) =>
      invoices.where((d) => d.customerId == customerId && d.date.year == year && d.status == DocStatus.paid && d.totals.labourGross > 0).toList();
}
