double _d(dynamic v, [double fallback = 0]) => v is num ? v.toDouble() : (double.tryParse('$v') ?? fallback);

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v as String);

double round2(double v) => (v * 100).roundToDouble() / 100;

class Company {
  String name;
  String owner;
  String street;
  String zip;
  String city;
  String phone;
  String email;
  String website;
  String taxNumber;
  String vatId;
  String taxOffice;
  String bankName;
  String iban;
  String bic;
  String accountHolder;
  bool smallBusiness;
  double defaultVatRate;
  int paymentDays;
  String invoicePrefix;
  String quotePrefix;
  int nextInvoiceNo;
  int nextQuoteNo;
  int nextCustomerNo;
  double reminderFee;
  String? logoPath;

  Company({
    this.name = 'GanzJahr Garten & Objektpflege',
    this.owner = '',
    this.street = '',
    this.zip = '',
    this.city = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.taxNumber = '',
    this.vatId = '',
    this.taxOffice = '',
    this.bankName = '',
    this.iban = '',
    this.bic = '',
    this.accountHolder = '',
    this.smallBusiness = false,
    this.defaultVatRate = 19,
    this.paymentDays = 14,
    this.invoicePrefix = 'RE',
    this.quotePrefix = 'AN',
    this.nextInvoiceNo = 1,
    this.nextQuoteNo = 1,
    this.nextCustomerNo = 1001,
    this.reminderFee = 5,
    this.logoPath,
  });

  String get addressLine => [street, '$zip $city'.trim()].where((s) => s.isNotEmpty).join(', ');

  bool get isComplete => owner.isNotEmpty && street.isNotEmpty && city.isNotEmpty && (taxNumber.isNotEmpty || vatId.isNotEmpty) && iban.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'name': name,
    'owner': owner,
    'street': street,
    'zip': zip,
    'city': city,
    'phone': phone,
    'email': email,
    'website': website,
    'taxNumber': taxNumber,
    'vatId': vatId,
    'taxOffice': taxOffice,
    'bankName': bankName,
    'iban': iban,
    'bic': bic,
    'accountHolder': accountHolder,
    'smallBusiness': smallBusiness,
    'defaultVatRate': defaultVatRate,
    'paymentDays': paymentDays,
    'invoicePrefix': invoicePrefix,
    'quotePrefix': quotePrefix,
    'nextInvoiceNo': nextInvoiceNo,
    'nextQuoteNo': nextQuoteNo,
    'nextCustomerNo': nextCustomerNo,
    'reminderFee': reminderFee,
    'logoPath': logoPath,
  };

  factory Company.fromJson(Map<String, dynamic> j) => Company(
    name: j['name'] ?? 'GanzJahr Garten & Objektpflege',
    owner: j['owner'] ?? '',
    street: j['street'] ?? '',
    zip: j['zip'] ?? '',
    city: j['city'] ?? '',
    phone: j['phone'] ?? '',
    email: j['email'] ?? '',
    website: j['website'] ?? '',
    taxNumber: j['taxNumber'] ?? '',
    vatId: j['vatId'] ?? '',
    taxOffice: j['taxOffice'] ?? '',
    bankName: j['bankName'] ?? '',
    iban: j['iban'] ?? '',
    bic: j['bic'] ?? '',
    accountHolder: j['accountHolder'] ?? '',
    smallBusiness: j['smallBusiness'] ?? false,
    defaultVatRate: _d(j['defaultVatRate'], 19),
    paymentDays: j['paymentDays'] ?? 14,
    invoicePrefix: j['invoicePrefix'] ?? 'RE',
    quotePrefix: j['quotePrefix'] ?? 'AN',
    nextInvoiceNo: j['nextInvoiceNo'] ?? 1,
    nextQuoteNo: j['nextQuoteNo'] ?? 1,
    nextCustomerNo: j['nextCustomerNo'] ?? 1001,
    reminderFee: _d(j['reminderFee'], 5),
    logoPath: j['logoPath'],
  );
}

enum CustomerType { private, business }

class Customer {
  String id;
  String number;
  CustomerType type;
  String company;
  String name;
  String street;
  String zip;
  String city;
  String email;
  String phone;
  String propertyAddress;
  String vatId;
  String notes;
  DateTime createdAt;

  Customer({
    required this.id,
    required this.number,
    this.type = CustomerType.private,
    this.company = '',
    this.name = '',
    this.street = '',
    this.zip = '',
    this.city = '',
    this.email = '',
    this.phone = '',
    this.propertyAddress = '',
    this.vatId = '',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName => company.isNotEmpty ? company : name;

  String get cityLine => '$zip $city'.trim();

  List<String> get addressLines => [
    if (company.isNotEmpty) company,
    if (name.isNotEmpty) company.isNotEmpty ? 'z. Hd. $name' : name,
    if (street.isNotEmpty) street,
    if (cityLine.isNotEmpty) cityLine,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'type': type.name,
    'company': company,
    'name': name,
    'street': street,
    'zip': zip,
    'city': city,
    'email': email,
    'phone': phone,
    'propertyAddress': propertyAddress,
    'vatId': vatId,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
    id: j['id'],
    number: j['number'] ?? '',
    type: j['type'] == 'business' ? CustomerType.business : CustomerType.private,
    company: j['company'] ?? '',
    name: j['name'] ?? '',
    street: j['street'] ?? '',
    zip: j['zip'] ?? '',
    city: j['city'] ?? '',
    email: j['email'] ?? '',
    phone: j['phone'] ?? '',
    propertyAddress: j['propertyAddress'] ?? '',
    vatId: j['vatId'] ?? '',
    notes: j['notes'] ?? '',
    createdAt: _date(j['createdAt']),
  );
}

enum ServiceCategory { garten, objekt, winter, material }

extension ServiceCategoryLabel on ServiceCategory {
  String get label => switch (this) {
    ServiceCategory.garten => 'Garden',
    ServiceCategory.objekt => 'Property',
    ServiceCategory.winter => 'Winter',
    ServiceCategory.material => 'Material',
  };
}

class CatalogItem {
  String id;
  String title;
  String description;
  String unit;
  double price;
  ServiceCategory category;
  bool isLabour;

  CatalogItem({
    required this.id,
    required this.title,
    this.description = '',
    this.unit = 'Std.',
    this.price = 0,
    this.category = ServiceCategory.garten,
    this.isLabour = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'unit': unit,
    'price': price,
    'category': category.name,
    'isLabour': isLabour,
  };

  factory CatalogItem.fromJson(Map<String, dynamic> j) => CatalogItem(
    id: j['id'],
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    unit: j['unit'] ?? 'Std.',
    price: _d(j['price']),
    category: ServiceCategory.values.firstWhere((c) => c.name == j['category'], orElse: () => ServiceCategory.garten),
    isLabour: j['isLabour'] ?? true,
  );
}

class LineItem {
  String title;
  String description;
  double quantity;
  String unit;
  double unitPrice;
  double vatRate;
  bool isLabour;

  LineItem({
    this.title = '',
    this.description = '',
    this.quantity = 1,
    this.unit = 'Std.',
    this.unitPrice = 0,
    this.vatRate = 19,
    this.isLabour = true,
  });

  double get net => round2(quantity * unitPrice);

  LineItem copy() => LineItem.fromJson(toJson());

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'quantity': quantity,
    'unit': unit,
    'unitPrice': unitPrice,
    'vatRate': vatRate,
    'isLabour': isLabour,
  };

  factory LineItem.fromJson(Map<String, dynamic> j) => LineItem(
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    quantity: _d(j['quantity'], 1),
    unit: j['unit'] ?? 'Std.',
    unitPrice: _d(j['unitPrice']),
    vatRate: _d(j['vatRate'], 19),
    isLabour: j['isLabour'] ?? true,
  );
}

enum DocKind { invoice, quote }

enum DocStatus { draft, open, paid, cancelled, accepted, declined }

extension DocStatusLabel on DocStatus {
  String get label => switch (this) {
    DocStatus.draft => 'Draft',
    DocStatus.open => 'Open',
    DocStatus.paid => 'Paid',
    DocStatus.cancelled => 'Cancelled',
    DocStatus.accepted => 'Accepted',
    DocStatus.declined => 'Declined',
  };
}

class Totals {
  final double net;
  final Map<double, double> vatByRate;
  final double gross;
  final double labourGross;

  const Totals(this.net, this.vatByRate, this.gross, this.labourGross);

  double get vat => vatByRate.values.fold(0, (a, b) => a + b);
}

class Document {
  String id;
  DocKind kind;
  String number;
  String customerId;
  Map<String, dynamic> customerSnapshot;
  DateTime date;
  DateTime createdAt;
  DateTime? serviceFrom;
  DateTime? serviceTo;
  DateTime dueDate;
  List<LineItem> items;
  String intro;
  String notes;
  DocStatus status;
  DateTime? paidAt;
  int reminderLevel;
  DateTime? lastReminderAt;
  bool showLabourNote;
  bool smallBusiness;
  String? sourceQuoteNumber;

  Document({
    required this.id,
    required this.kind,
    required this.number,
    required this.customerId,
    required this.customerSnapshot,
    required this.date,
    required this.dueDate,
    DateTime? createdAt,
    this.serviceFrom,
    this.serviceTo,
    List<LineItem>? items,
    this.intro = '',
    this.notes = '',
    this.status = DocStatus.open,
    this.paidAt,
    this.reminderLevel = 0,
    this.lastReminderAt,
    this.showLabourNote = true,
    this.smallBusiness = false,
    this.sourceQuoteNumber,
  }) : items = items ?? [],
       createdAt = createdAt ?? DateTime.now();

  Customer get customer => Customer.fromJson(customerSnapshot);

  bool get isInvoice => kind == DocKind.invoice;

  bool get isOverdue => isInvoice && status == DocStatus.open && DateTime.now().isAfter(DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59));

  int get daysOverdue => isOverdue ? DateTime.now().difference(dueDate).inDays : 0;

  Totals get totals {
    double net = 0;
    double labourNet = 0;
    double labourVat = 0;
    final vat = <double, double>{};
    for (final it in items) {
      net += it.net;
      if (!smallBusiness) {
        vat[it.vatRate] = (vat[it.vatRate] ?? 0) + it.net;
      }
      if (it.isLabour) {
        labourNet += it.net;
        if (!smallBusiness) labourVat += it.net * it.vatRate / 100;
      }
    }
    final vatAmounts = {for (final e in vat.entries) e.key: round2(e.value * e.key / 100)};
    final vatSum = vatAmounts.values.fold<double>(0, (a, b) => a + b);
    return Totals(round2(net), vatAmounts, round2(net + vatSum), round2(labourNet + labourVat));
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'number': number,
    'customerId': customerId,
    'customerSnapshot': customerSnapshot,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'serviceFrom': serviceFrom?.toIso8601String(),
    'serviceTo': serviceTo?.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'items': items.map((e) => e.toJson()).toList(),
    'intro': intro,
    'notes': notes,
    'status': status.name,
    'paidAt': paidAt?.toIso8601String(),
    'reminderLevel': reminderLevel,
    'lastReminderAt': lastReminderAt?.toIso8601String(),
    'showLabourNote': showLabourNote,
    'smallBusiness': smallBusiness,
    'sourceQuoteNumber': sourceQuoteNumber,
  };

  factory Document.fromJson(Map<String, dynamic> j) => Document(
    id: j['id'],
    kind: j['kind'] == 'quote' ? DocKind.quote : DocKind.invoice,
    number: j['number'] ?? '',
    customerId: j['customerId'] ?? '',
    customerSnapshot: Map<String, dynamic>.from(j['customerSnapshot'] ?? {}),
    date: _date(j['date']) ?? DateTime.now(),
    createdAt: _date(j['createdAt']),
    serviceFrom: _date(j['serviceFrom']),
    serviceTo: _date(j['serviceTo']),
    dueDate: _date(j['dueDate']) ?? DateTime.now(),
    items: ((j['items'] as List?) ?? []).map((e) => LineItem.fromJson(Map<String, dynamic>.from(e))).toList(),
    intro: j['intro'] ?? '',
    notes: j['notes'] ?? '',
    status: DocStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => DocStatus.open),
    paidAt: _date(j['paidAt']),
    reminderLevel: j['reminderLevel'] ?? 0,
    lastReminderAt: _date(j['lastReminderAt']),
    showLabourNote: j['showLabourNote'] ?? true,
    smallBusiness: j['smallBusiness'] ?? false,
    sourceQuoteNumber: j['sourceQuoteNumber'],
  );
}
