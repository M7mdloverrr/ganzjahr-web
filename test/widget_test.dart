import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ganzjahr_rechnung/models.dart';
import 'package:ganzjahr_rechnung/cloud.dart';
import 'package:ganzjahr_rechnung/i18n.dart';
import 'package:ganzjahr_rechnung/pdf/invoice_pdf.dart';
import 'package:ganzjahr_rechnung/reports.dart';
import 'package:ganzjahr_rechnung/store.dart';
import 'package:intl/date_symbol_data_local.dart';

Document sampleInvoice({bool smallBusiness = false}) => Document(
  id: 'x',
  kind: DocKind.invoice,
  number: 'RE-2026-0001',
  customerId: 'c1',
  customerSnapshot: Customer(
    id: 'c1',
    number: 'K1001',
    name: 'Herr Max Müller',
    street: 'Gartenweg 12',
    zip: '10115',
    city: 'Berlin',
    propertyAddress: 'Lindenstraße 5, 10117 Berlin',
  ).toJson(),
  date: DateTime(2026, 10, 4),
  createdAt: DateTime(2026, 10, 4, 14, 35),
  serviceFrom: DateTime(2026, 9, 28),
  serviceTo: DateTime(2026, 10, 2),
  dueDate: DateTime(2026, 10, 18),
  smallBusiness: smallBusiness,
  items: [
    LineItem(title: 'Heckenschnitt', description: 'Thujahecke ca. 25 m, inkl. Formschnitt', quantity: 3.5, unit: 'Std.', unitPrice: 45),
    LineItem(title: 'Rasenmähen inkl. Entsorgung', quantity: 400, unit: 'm²', unitPrice: 0.12),
    LineItem(title: 'Grünschnitt-Entsorgung', quantity: 2, unit: 'm³', unitPrice: 35, isLabour: false),
  ],
);

Company sampleCompany() => Company(
  owner: 'Jamel Beispiel',
  street: 'Musterstraße 1',
  zip: '10115',
  city: 'Berlin',
  phone: '+49 30 1234567',
  email: 'info@ganzjahr-pflege.de',
  taxNumber: '12/345/67890',
  vatId: 'DE123456789',
  taxOffice: 'Berlin-Mitte',
  bankName: 'Berliner Sparkasse',
  iban: 'DE89370400440532013000',
  bic: 'COBADEFFXXX',
  accountHolder: 'Jamel Beispiel',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('de_DE'));

  test('totals with VAT and labour share', () {
    final t = sampleInvoice().totals;
    expect(t.net, 275.5);
    expect(t.vat, 52.35);
    expect(t.gross, 327.85);
    expect(t.labourGross, 244.55);
  });

  test('small business has no VAT', () {
    final t = sampleInvoice(smallBusiness: true).totals;
    expect(t.vat, 0);
    expect(t.gross, 275.5);
  });

  test('girocode payload', () {
    final g = girocode(name: 'GanzJahr', iban: 'DE89 3704 0044 0532 0130 00', amount: 327.85, reference: 'RE-2026-0001');
    expect(g.split('\n'), ['BCD', '002', '1', 'SCT', '', 'GanzJahr', 'DE89370400440532013000', 'EUR327.85', '', '', 'RE-2026-0001']);
  });

  test('builds invoice, reminder and certificate PDFs', () async {
    final c = sampleCompany();
    final inv = sampleInvoice();
    final out = Platform.environment['PDF_OUT'];
    final pdf = await buildDocumentPdf(inv, c);
    expect(pdf.length, greaterThan(10000));
    final rem = await buildReminderPdf(inv, c, level: 1);
    final cert = await buildLabourCertificatePdf(inv.customer, 2026, [
      inv
        ..status = DocStatus.paid
        ..paidAt = DateTime(2026, 10, 10),
    ], c);
    if (out != null) {
      File('$out/rechnung.pdf').writeAsBytesSync(pdf);
      File('$out/mahnung.pdf').writeAsBytesSync(rem);
      File('$out/bescheinigung.pdf').writeAsBytesSync(cert);
    }
  });

  test('monthly and yearly earnings', () {
    final s = Store();
    final a = sampleInvoice()
      ..status = DocStatus.paid
      ..paidAt = DateTime(2026, 11, 2);
    final b = sampleInvoice()
      ..id = 'y'
      ..status = DocStatus.open
      ..date = DateTime(2025, 3, 1);
    final c = sampleInvoice()
      ..id = 'z'
      ..status = DocStatus.cancelled;
    s.documents = [a, b, c];
    final m = monthlyEarnings(s, 2026);
    expect(m[9].count, 1);
    expect(m[9].gross, 327.85);
    expect(m[10].received, 327.85);
    expect(sumRows(m).gross, 327.85);
    final y = yearlyEarnings(s);
    expect(y.map((r) => r.year), containsAllInOrder([2025, 2026]));
    expect(y.firstWhere((r) => r.year == 2025).gross, 327.85);
  });

  test('translations', () {
    appLang = AppLang.de;
    expect('Customers'.tr, 'Kunden');
    expect('Year {year}'.trf({'year': 2026}), 'Jahr 2026');
    appLang = AppLang.ar;
    expect('Customers'.tr, 'العملاء');
    appLang = AppLang.en;
    expect('Customers'.tr, 'Customers');
  });

  test('earnings PDF', () async {
    final s = Store()..documents = [sampleInvoice()..status = DocStatus.open];
    final rows = monthlyEarnings(s, 2026).map((r) => ('M${r.month}', r)).toList();
    final pdf = await buildEarningsPdf(
      company: sampleCompany(),
      title: 'Umsatzübersicht 2026 (monatlich)',
      periodHeader: 'Monat',
      rows: rows,
      total: sumRows(rows.map((e) => e.$2).toList()),
    );
    final out = Platform.environment['PDF_OUT'];
    if (out != null) File('$out/umsatz.pdf').writeAsBytesSync(pdf);
    expect(pdf.length, greaterThan(5000));
  });

  test('canonical JSON ignores key order', () {
    expect(
      canonical({
        'b': 1,
        'a': {
          'd': 2.5,
          'c': [
            1,
            {'y': 1, 'x': 2},
          ],
        },
      }),
      canonical({
        'a': {
          'c': [
            1,
            {'x': 2, 'y': 1},
          ],
          'd': 2.5,
        },
        'b': 1,
      }),
    );
    final inv = sampleInvoice();
    expect(canonical(inv.toJson()), canonical(jsonDecode(jsonEncode(inv.toJson()))));
  });

  test('reads google-services.json', () {
    const raw = '''{"project_info":{"project_number":"123","project_id":"ganzjahr","storage_bucket":"ganzjahr.appspot.com"},
      "client":[{"client_info":{"mobilesdk_app_id":"1:123:android:abc","android_client_info":{"package_name":"de.ganzjahr.ganzjahr_rechnung"}},
      "api_key":[{"current_key":"KEY"}]}]}''';
    final o = CloudSync.optionsFromGoogleServices(raw);
    expect(o.projectId, 'ganzjahr');
    expect(o.appId, '1:123:android:abc');
    expect(o.apiKey, 'KEY');
    expect(o.messagingSenderId, '123');
  });

  test('reads pasted firebaseConfig', () {
    const raw = '''const firebaseConfig = {
  apiKey: "AIzaX",
  authDomain: "ganzjahr.firebaseapp.com",
  projectId: "ganzjahr",
  storageBucket: "ganzjahr.firebasestorage.app",
  messagingSenderId: "123",
  appId: "1:123:web:abc"
};''';
    final o = CloudSync.optionsFromConfig(raw);
    expect(o.apiKey, 'AIzaX');
    expect(o.projectId, 'ganzjahr');
    expect(o.appId, '1:123:web:abc');
    expect(o.authDomain, 'ganzjahr.firebaseapp.com');
    expect(() => CloudSync.optionsFromConfig('hello'), throwsFormatException);
  });
}
