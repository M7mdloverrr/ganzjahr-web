import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../format.dart';
import '../models.dart';
import '../reports.dart';

const _ink = PdfColors.black;
const _muted = PdfColor.fromInt(0xFF555555);
const _line = PdfColor.fromInt(0xFF999999);

class _Assets {
  final pw.Font regular;
  final pw.Font bold;
  final pw.ImageProvider logo;
  _Assets(this.regular, this.bold, this.logo);
}

Future<_Assets> _loadAssets(Company c) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/LiberationSans-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/LiberationSans-Bold.ttf'));
  Uint8List logoBytes;
  final custom = c.logoPath;
  if (!kIsWeb && custom != null && File(custom).existsSync()) {
    logoBytes = await File(custom).readAsBytes();
  } else {
    logoBytes = (await rootBundle.load('assets/images/logo_invoice.png')).buffer.asUint8List();
  }
  return _Assets(regular, bold, pw.MemoryImage(logoBytes));
}

/// EPC069-12 "GiroCode" payload that banking apps can scan to pre-fill a SEPA transfer.
String girocode({required String name, required String iban, String bic = '', required double amount, required String reference}) {
  final cleanIban = iban.replaceAll(' ', '').toUpperCase();
  final holder = name.length > 70 ? name.substring(0, 70) : name;
  return [
    'BCD',
    '002',
    '1',
    'SCT',
    bic.replaceAll(' ', '').toUpperCase(),
    holder,
    cleanIban,
    'EUR${amount.toStringAsFixed(2)}',
    '',
    '',
    reference,
  ].join('\n');
}

class _Letter {
  final Company company;
  final _Assets a;
  _Letter(this.company, this.a);

  pw.TextStyle get small => pw.TextStyle(fontSize: 7.5, color: _muted);
  pw.TextStyle get body => const pw.TextStyle(fontSize: 9.5, color: _ink, lineSpacing: 1.5);
  pw.TextStyle get bodyBold => pw.TextStyle(fontSize: 9.5, color: _ink, fontWeight: pw.FontWeight.bold);

  pw.PageTheme theme() => pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(25 * PdfPageFormat.mm, 12 * PdfPageFormat.mm, 18 * PdfPageFormat.mm, 12 * PdfPageFormat.mm),
    theme: pw.ThemeData.withFont(base: a.regular, bold: a.bold),
    buildBackground: (ctx) => pw.FullPage(
      ignoreMargins: true,
      child: pw.Stack(
        children: [
          pw.Positioned(
            left: 4 * PdfPageFormat.mm,
            top: 105 * PdfPageFormat.mm,
            child: pw.Container(width: 8, height: 0.6, color: _muted),
          ),
          pw.Positioned(
            left: 4 * PdfPageFormat.mm,
            top: 148.5 * PdfPageFormat.mm,
            child: pw.Container(width: 12, height: 0.6, color: _muted),
          ),
        ],
      ),
    ),
  );

  pw.Widget header(pw.Context ctx) {
    if (ctx.pageNumber > 1) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        padding: const pw.EdgeInsets.only(bottom: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.6)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(company.name, style: bodyBold),
            pw.Image(a.logo, height: 26),
          ],
        ),
      );
    }
    return pw.SizedBox();
  }

  pw.Widget footer(pw.Context ctx) {
    final c = company;
    pw.Widget col(List<String> lines, {int flex = 4}) => pw.Expanded(
      flex: flex,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: lines.where((l) => l.trim().isNotEmpty).map((l) => pw.Text(l, style: small)).toList(),
      ),
    );
    return pw.Column(
      children: [
        pw.Container(height: 0.6, color: _line, margin: const pw.EdgeInsets.only(bottom: 5)),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            col([c.name, if (c.owner.isNotEmpty) 'Inh. ${c.owner}', c.street, '${c.zip} ${c.city}']),
            col([if (c.phone.isNotEmpty) 'Tel. ${c.phone}', if (c.email.isNotEmpty) c.email, c.website]),
            col([
              if (c.bankName.isNotEmpty) c.bankName,
              if (c.iban.isNotEmpty) 'IBAN ${formatIban(c.iban)}',
              if (c.bic.isNotEmpty) 'BIC ${c.bic}',
            ], flex: 5),
            col([
              if (c.taxNumber.isNotEmpty) 'St.-Nr. ${c.taxNumber}',
              if (c.vatId.isNotEmpty) 'USt-IdNr. ${c.vatId}',
              if (c.taxOffice.isNotEmpty) 'Finanzamt ${c.taxOffice}',
              'Seite ${ctx.pageNumber} von ${ctx.pagesCount}',
            ]),
          ],
        ),
      ],
    );
  }

  /// Letterhead with logo, return-address line, recipient window and info block (DIN 5008 form B).
  pw.Widget letterhead({required List<String> recipient, required List<(String, String)> info}) {
    final c = company;
    final sender = [c.name, c.street, '${c.zip} ${c.city}'.trim()].where((s) => s.isNotEmpty).join(' · ');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          height: 33 * PdfPageFormat.mm,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 6),
                    pw.Text(
                      c.name,
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text('Gartenpflege · Objektpflege · Winterdienst', style: pw.TextStyle(fontSize: 8.5, color: _muted)),
                  ],
                ),
              ),
              pw.Image(a.logo, height: 31 * PdfPageFormat.mm),
            ],
          ),
        ),
        pw.SizedBox(height: 7 * PdfPageFormat.mm),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 85 * PdfPageFormat.mm,
              height: 40 * PdfPageFormat.mm,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.only(bottom: 1.5),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: _muted, width: 0.4)),
                    ),
                    child: pw.Text(sender, style: pw.TextStyle(fontSize: 6.5, color: _muted)),
                  ),
                  pw.SizedBox(height: 8),
                  ...recipient.map((l) => pw.Text(l, style: const pw.TextStyle(fontSize: 10.5, color: _ink, lineSpacing: 2))),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Container(
              width: 70 * PdfPageFormat.mm,
              padding: const pw.EdgeInsets.only(top: 14),
              child: pw.Column(
                children: info
                    .map(
                      (e) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 1.6),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(e.$1, style: const pw.TextStyle(fontSize: 9, color: _ink)),
                            pw.Text(e.$2, style: const pw.TextStyle(fontSize: 9, color: _ink)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4 * PdfPageFormat.mm),
      ],
    );
  }

  pw.Widget title(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _ink),
    ),
  );

  pw.Widget paragraph(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(text, style: body),
  );

  pw.Widget totalsBox(List<(String, String, bool)> rows) => pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Container(
      width: 85 * PdfPageFormat.mm,
      margin: const pw.EdgeInsets.only(top: 6, bottom: 14),
      child: pw.Column(
        children: rows.map((r) {
          final strong = r.$3;
          final style = pw.TextStyle(fontSize: strong ? 10.5 : 9.5, color: _ink, fontWeight: strong ? pw.FontWeight.bold : null);
          return pw.Container(
            padding: pw.EdgeInsets.only(top: strong ? 5 : 2.5, bottom: strong ? 4 : 2.5, left: 4, right: 4),
            decoration: strong
                ? const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: _ink, width: 0.8),
                      bottom: pw.BorderSide(color: _ink, width: 2, style: pw.BorderStyle.solid),
                    ),
                  )
                : null,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(r.$1, style: style),
                pw.Text(r.$2, style: style),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  );

  pw.Widget noteBox(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 9, color: _ink, lineSpacing: 1.4)),
  );

  pw.Widget paymentBlock({required String text, required double amount, required String reference}) {
    final c = company;
    final canQr = c.iban.trim().isNotEmpty && amount > 0;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: pw.Text(text, style: body)),
        if (canQr) ...[
          pw.SizedBox(width: 12),
          pw.Column(
            children: [
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium),
                drawText: false,
                data: girocode(
                  name: c.accountHolder.isNotEmpty ? c.accountHolder : c.name,
                  iban: c.iban,
                  bic: c.bic,
                  amount: amount,
                  reference: reference,
                ),
                width: 22 * PdfPageFormat.mm,
                height: 22 * PdfPageFormat.mm,
              ),
              pw.SizedBox(height: 2),
              pw.Text('GiroCode – mit Banking-App scannen', style: pw.TextStyle(fontSize: 6, color: _muted)),
            ],
          ),
        ],
      ],
    );
  }
}

String formatIban(String iban) {
  final s = iban.replaceAll(' ', '').toUpperCase();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && i % 4 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

String _salutation(Customer c) => 'Sehr geehrte Damen und Herren,';

String _servicePeriod(Document d) {
  final from = d.serviceFrom;
  final to = d.serviceTo;
  if (from == null) return dmy(d.date);
  if (to == null || to == from) return dmy(from);
  return '${dmy(from)} – ${dmy(to)}';
}

pw.Widget _itemsTable(_Letter l, Document d) {
  final head = pw.TextStyle(fontSize: 9, color: _ink, fontWeight: pw.FontWeight.bold);
  final cell = const pw.TextStyle(fontSize: 9, color: _ink);
  final showVat = !d.smallBusiness && d.items.map((e) => e.vatRate).toSet().length > 1;
  pw.Widget c(String t, {pw.TextAlign align = pw.TextAlign.left, pw.TextStyle? style}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
    child: pw.Text(t, style: style ?? cell, textAlign: align),
  );
  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _ink, width: 0.8),
          bottom: pw.BorderSide(color: _ink, width: 0.8),
        ),
      ),
      children: [
        c('Pos.', style: head),
        c('Bezeichnung', style: head),
        c('Menge', style: head, align: pw.TextAlign.right),
        c('Einheit', style: head),
        c('Einzelpreis', style: head, align: pw.TextAlign.right),
        if (showVat) c('USt.', style: head, align: pw.TextAlign.right),
        c('Gesamtpreis', style: head, align: pw.TextAlign.right),
      ],
    ),
  ];
  for (var i = 0; i < d.items.length; i++) {
    final it = d.items[i];
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.4)),
        ),
        children: [
          c('${i + 1}'),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(it.title, style: cell),
                if (it.description.isNotEmpty) pw.Text(it.description, style: pw.TextStyle(fontSize: 8, color: _muted)),
              ],
            ),
          ),
          c(qty(it.quantity), align: pw.TextAlign.right),
          c(it.unit),
          c(eur(it.unitPrice), align: pw.TextAlign.right),
          if (showVat) c(vatLabel(it.vatRate), align: pw.TextAlign.right),
          c(eur(it.net), align: pw.TextAlign.right),
        ],
      ),
    );
  }
  return pw.Table(
    columnWidths: {
      0: const pw.FixedColumnWidth(26),
      1: const pw.FlexColumnWidth(),
      2: const pw.FixedColumnWidth(40),
      3: const pw.FixedColumnWidth(44),
      4: const pw.FixedColumnWidth(62),
      if (showVat) 5: const pw.FixedColumnWidth(36),
      showVat ? 6 : 5: const pw.FixedColumnWidth(66),
    },
    children: rows,
  );
}

List<(String, String, bool)> _totalRows(Document d, {String grossLabel = 'Rechnungsbetrag'}) {
  final t = d.totals;
  if (d.smallBusiness) {
    return [(grossLabel, eur(t.gross), true)];
  }
  return [
    ('Nettobetrag', eur(t.net), false),
    for (final e in t.vatByRate.entries) ('zzgl. ${vatLabel(e.key)} USt.', eur(e.value), false),
    ('$grossLabel (brutto)', eur(t.gross), true),
  ];
}

Future<Uint8List> buildDocumentPdf(Document d, Company company) async {
  final a = await _loadAssets(company);
  final l = _Letter(company, a);
  final cust = d.customer;
  final isInvoice = d.isInvoice;
  final cancelled = d.status == DocStatus.cancelled;
  final t = d.totals;

  final info = <(String, String)>[
    (isInvoice ? 'Rechnungs-Nr.' : 'Angebots-Nr.', d.number),
    (isInvoice ? 'Rechnungsdatum' : 'Datum', dmy(d.date)),
    ('Erstellt am', dmyHm(d.createdAt)),
    if (isInvoice) ('Leistungsdatum', _servicePeriod(d)),
    if (cust.number.isNotEmpty) ('Kunden-Nr.', cust.number),
    if (isInvoice) ('Zahlbar bis', dmy(d.dueDate)) else ('Gültig bis', dmy(d.dueDate)),
    if (cust.vatId.isNotEmpty) ('USt-IdNr. Kunde', cust.vatId),
  ];

  final doc = pw.Document(title: '${isInvoice ? 'Rechnung' : 'Angebot'} ${d.number}', author: company.name, creator: 'GanzJahr App');
  doc.addPage(
    pw.MultiPage(
      pageTheme: l.theme(),
      header: l.header,
      footer: l.footer,
      build: (ctx) => [
        l.letterhead(recipient: cust.addressLines, info: info),
        l.title('${cancelled ? 'STORNIERT – ' : ''}${isInvoice ? 'Rechnung' : 'Angebot'} Nr. ${d.number}'),
        if (cust.propertyAddress.isNotEmpty) l.paragraph('Objekt / Leistungsort: ${cust.propertyAddress}'),
        if (d.sourceQuoteNumber != null) l.paragraph('Bezug: unser Angebot Nr. ${d.sourceQuoteNumber}'),
        l.paragraph(_salutation(cust)),
        l.paragraph(
          d.intro.isNotEmpty
              ? d.intro
              : isInvoice
              ? 'vielen Dank für Ihren Auftrag. Für die erbrachten Leistungen erlauben wir uns, Ihnen Folgendes in Rechnung zu stellen:'
              : 'vielen Dank für Ihre Anfrage. Gerne unterbreiten wir Ihnen folgendes Angebot:',
        ),
        _itemsTable(l, d),
        l.totalsBox(_totalRows(d, grossLabel: isInvoice ? 'Rechnungsbetrag' : 'Angebotssumme')),
        if (d.smallBusiness) l.noteBox('Gemäß § 19 UStG wird keine Umsatzsteuer berechnet (Kleinunternehmerregelung).'),
        if (d.showLabourNote && t.labourGross > 0)
          l.noteBox(
            'Hinweis gemäß § 35a EStG: Im ${isInvoice ? 'Rechnungsbetrag' : 'Angebotsbetrag'} sind Arbeits- und Fahrtkosten in Höhe von ${eur(t.labourGross)} '
            '${d.smallBusiness ? '' : '(inkl. USt.) '}enthalten. Diese können als haushaltsnahe Dienstleistung steuerlich geltend gemacht werden. '
            'Voraussetzung ist eine unbare Zahlung (Überweisung) auf unser Konto.',
          ),
        if (d.notes.isNotEmpty) l.paragraph(d.notes),
        if (isInvoice && !cancelled)
          l.paymentBlock(
            text:
                'Bitte überweisen Sie den Rechnungsbetrag von ${eur(t.gross)} ohne Abzug bis zum ${dmy(d.dueDate)} '
                'unter Angabe der Rechnungsnummer ${d.number} auf das unten genannte Konto'
                '${company.iban.isNotEmpty ? ' (IBAN ${formatIban(company.iban)})' : ''}.\n\n'
                'Vielen Dank für Ihr Vertrauen!\nMit freundlichen Grüßen\n${company.owner.isNotEmpty ? company.owner : company.name}',
            amount: t.gross,
            reference: d.number,
          )
        else if (!isInvoice)
          l.paragraph(
            'Dieses Angebot ist gültig bis zum ${dmy(d.dueDate)}. Wir freuen uns auf Ihren Auftrag!\n\n'
            'Mit freundlichen Grüßen\n${company.owner.isNotEmpty ? company.owner : company.name}',
          ),
      ],
    ),
  );
  return doc.save();
}

String reminderTitle(int level) => switch (level) {
  0 => 'Zahlungserinnerung',
  1 => '1. Mahnung',
  _ => '2. Mahnung',
};

/// Payment reminder ("Zahlungserinnerung" / "Mahnung") for an overdue invoice.
Future<Uint8List> buildReminderPdf(Document d, Company company, {required int level}) async {
  final a = await _loadAssets(company);
  final l = _Letter(company, a);
  final cust = d.customer;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final newDue = today.add(const Duration(days: 7));
  final fee = level == 0 ? 0.0 : company.reminderFee;
  final open = d.totals.gross;
  final total = open + fee;
  final title = reminderTitle(level);

  final doc = pw.Document(title: '$title ${d.number}', author: company.name);
  doc.addPage(
    pw.MultiPage(
      pageTheme: l.theme(),
      header: l.header,
      footer: l.footer,
      build: (ctx) => [
        l.letterhead(
          recipient: cust.addressLines,
          info: [
            ('Datum', dmy(today)),
            ('Erstellt am', dmyHm(now)),
            ('Rechnungs-Nr.', d.number),
            ('Rechnungsdatum', dmy(d.date)),
            if (cust.number.isNotEmpty) ('Kunden-Nr.', cust.number),
            ('Neue Frist', dmy(newDue)),
          ],
        ),
        l.title('$title zur Rechnung Nr. ${d.number}'),
        l.paragraph(_salutation(cust)),
        l.paragraph(
          level == 0
              ? 'sicherlich ist es Ihrer Aufmerksamkeit entgangen, dass unsere Rechnung Nr. ${d.number} vom ${dmy(d.date)} '
                    'mit Fälligkeit am ${dmy(d.dueDate)} noch nicht beglichen wurde. Wir bitten Sie freundlich, den offenen Betrag bis zum ${dmy(newDue)} zu überweisen.'
              : 'leider konnten wir trotz unserer Zahlungserinnerung bis heute keinen Zahlungseingang zu unserer Rechnung Nr. ${d.number} '
                    'vom ${dmy(d.date)} feststellen. Wir fordern Sie hiermit auf, den nachstehenden Betrag bis spätestens ${dmy(newDue)} zu begleichen.',
        ),
        l.totalsBox([
          ('Offener Rechnungsbetrag', eur(open), false),
          if (fee > 0) ('Mahngebühr', eur(fee), false),
          ('Zu zahlender Betrag', eur(total), true),
        ]),
        l.paymentBlock(
          text:
              'Bitte überweisen Sie ${eur(total)} unter Angabe der Rechnungsnummer ${d.number} auf das unten genannte Konto. '
              'Sollten Sie die Zahlung bereits veranlasst haben, betrachten Sie dieses Schreiben bitte als gegenstandslos.\n\n'
              'Mit freundlichen Grüßen\n${company.owner.isNotEmpty ? company.owner : company.name}',
          amount: total,
          reference: d.number,
        ),
      ],
    ),
  );
  return doc.save();
}

/// Annual certificate of labour costs for household-related services (§ 35a EStG).
Future<Uint8List> buildLabourCertificatePdf(Customer cust, int year, List<Document> invoices, Company company) async {
  final a = await _loadAssets(company);
  final l = _Letter(company, a);
  final now = DateTime.now();
  final total = invoices.fold<double>(0, (s, d) => s + d.totals.labourGross);
  final head = pw.TextStyle(fontSize: 9, color: _ink, fontWeight: pw.FontWeight.bold);
  final cell = const pw.TextStyle(fontSize: 9, color: _ink);

  final doc = pw.Document(title: 'Bescheinigung § 35a EStG $year – ${cust.displayName}', author: company.name);
  doc.addPage(
    pw.MultiPage(
      pageTheme: l.theme(),
      header: l.header,
      footer: l.footer,
      build: (ctx) => [
        l.letterhead(
          recipient: cust.addressLines,
          info: [('Datum', dmyHm(now)), if (cust.number.isNotEmpty) ('Kunden-Nr.', cust.number), ('Kalenderjahr', '$year')],
        ),
        l.title('Bescheinigung über haushaltsnahe Dienstleistungen ($year)'),
        if (cust.propertyAddress.isNotEmpty) l.paragraph('Objekt / Leistungsort: ${cust.propertyAddress}'),
        l.paragraph(
          'Hiermit bestätigen wir, dass im Kalenderjahr $year folgende Arbeitskosten für haushaltsnahe Dienstleistungen '
          'im Sinne des § 35a EStG angefallen und unbar bezahlt worden sind:',
        ),
        pw.TableHelper.fromTextArray(
          headerStyle: head,
          headerDecoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: _ink, width: 0.8),
              bottom: pw.BorderSide(color: _ink, width: 0.8),
            ),
          ),
          border: null,
          rowDecoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.4)),
          ),
          cellStyle: cell,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
          },
          headers: ['Rechnung', 'Datum', 'Bezahlt am', 'Rechnungsbetrag', 'davon Arbeitskosten'],
          data: invoices
              .map((d) => [d.number, dmy(d.date), d.paidAt == null ? '-' : dmy(d.paidAt!), eur(d.totals.gross), eur(d.totals.labourGross)])
              .toList(),
        ),
        l.totalsBox([('Summe Arbeitskosten', eur(total), true)]),
        l.paragraph('Die Arbeitskosten enthalten Lohn-, Maschinen- und Fahrtkosten inklusive Umsatzsteuer, jedoch keine Materialkosten.'),
        l.paragraph('Mit freundlichen Grüßen\n${company.owner.isNotEmpty ? company.owner : company.name}'),
      ],
    ),
  );
  return doc.save();
}

Future<Uint8List> buildEarningsPdf({
  required Company company,
  required String title,
  required String periodHeader,
  required List<(String, EarningsRow)> rows,
  required EarningsRow total,
}) async {
  final a = await _loadAssets(company);
  final l = _Letter(company, a);
  final head = pw.TextStyle(fontSize: 9, color: _ink, fontWeight: pw.FontWeight.bold);
  final cell = const pw.TextStyle(fontSize: 9, color: _ink);
  pw.TableRow tableRow(List<String> cells, pw.TextStyle style, PdfColor line, double width, {bool top = false}) => pw.TableRow(
    decoration: pw.BoxDecoration(
      border: pw.Border(
        top: top ? pw.BorderSide(color: line, width: width) : pw.BorderSide.none,
        bottom: pw.BorderSide(color: line, width: width),
      ),
    ),
    children: [
      for (var i = 0; i < cells.length; i++)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: pw.Text(cells[i], style: style, textAlign: i == 0 ? pw.TextAlign.left : pw.TextAlign.right),
        ),
    ],
  );
  final doc = pw.Document(title: title, author: company.name);
  doc.addPage(
    pw.MultiPage(
      pageTheme: l.theme(),
      footer: l.footer,
      build: (ctx) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(company.name, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(company.addressLine, style: l.small),
              ],
            ),
            pw.Image(a.logo, height: 60),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('Erstellt am ${dmyHm(DateTime.now())}', style: l.small),
        pw.SizedBox(height: 14),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(2.4),
            1: pw.FlexColumnWidth(1.6),
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(2),
            4: pw.FlexColumnWidth(2),
            5: pw.FlexColumnWidth(2.4),
          },
          children: [
            tableRow([periodHeader, 'Anzahl', 'Netto', 'USt', 'Brutto', 'Zahlungseingang'], head, _ink, 0.8, top: true),
            for (final (label, r) in rows) tableRow([label, '${r.count}', eur(r.net), eur(r.vat), eur(r.gross), eur(r.received)], cell, _line, 0.4),
            tableRow(['Summe', '${total.count}', eur(total.net), eur(total.vat), eur(total.gross), eur(total.received)], head, _ink, 1.2),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Text(
          'Rechnungen werden nach Rechnungsdatum gezählt, Zahlungseingänge nach Zahlungsdatum. '
          'Stornierte Rechnungen und Entwürfe sind nicht enthalten.',
          style: l.small,
        ),
      ],
    ),
  );
  return doc.save();
}
