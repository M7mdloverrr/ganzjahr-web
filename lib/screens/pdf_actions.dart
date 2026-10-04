import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../widgets.dart';
import '../i18n.dart';

String safeFileName(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9ÄÖÜäöüß_\-. ]'), '_').replaceAll(' ', '_');

Future<void> savePdfToDevice(BuildContext context, Uint8List bytes, String fileName) async {
  try {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/pdf',
      dialogTitle: 'Save PDF'.tr,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (context.mounted && uri != null) toast(context, 'PDF saved: {f}'.trf({'f': fileName}));
  } catch (e) {
    if (context.mounted) toast(context, 'Could not save PDF: {e}'.trf({'e': e}));
  }
}

Future<void> printPdf(Uint8List bytes, String name) => Printing.layoutPdf(onLayout: (_) async => bytes, name: name, format: PdfPageFormat.a4);

Future<void> sharePdf(Uint8List bytes, String fileName, {String? subject, String? body, List<String>? emails}) =>
    Printing.sharePdf(bytes: bytes, filename: fileName, subject: subject, body: body, emails: emails);

/// PDF preview with Print, Save and Send buttons.
class PdfPane extends StatefulWidget {
  final String fileName;
  final Future<Uint8List> Function() builder;
  final String? emailSubject;
  final String? emailBody;
  final String? email;
  final VoidCallback? onOutput;

  const PdfPane({super.key, required this.fileName, required this.builder, this.emailSubject, this.emailBody, this.email, this.onOutput});

  @override
  State<PdfPane> createState() => _PdfPaneState();
}

class _PdfPaneState extends State<PdfPane> {
  late final Future<Uint8List> _future = widget.builder();

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Could not create PDF:\n{e}'.trf({'e': '${snap.error}'}), textAlign: TextAlign.center));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final bytes = snap.data!;
        return Column(
          children: [
            Expanded(
              child: PdfPreview(
                build: (_) async => bytes,
                useActions: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                pdfFileName: w.fileName,
                scrollViewDecoration: const BoxDecoration(color: Color(0xFFE6EBE3)),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await printPdf(bytes, w.fileName);
                          w.onOutput?.call();
                        },
                        icon: const Icon(Icons.print_rounded),
                        label: Text('Print'.tr),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          await savePdfToDevice(context, bytes, w.fileName);
                          w.onOutput?.call();
                        },
                        icon: const Icon(Icons.download_rounded),
                        label: Text('Save PDF'.tr),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          await sharePdf(
                            bytes,
                            w.fileName,
                            subject: w.emailSubject,
                            body: w.emailBody,
                            emails: (w.email ?? '').isEmpty ? null : [w.email!],
                          );
                          w.onOutput?.call();
                        },
                        icon: const Icon(Icons.share_rounded),
                        label: Text('Send'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PdfViewScreen extends StatelessWidget {
  final String title;
  final String fileName;
  final Future<Uint8List> Function() builder;
  final String? emailSubject;
  final String? emailBody;
  final String? email;
  final VoidCallback? onOutput;

  const PdfViewScreen({
    super.key,
    required this.title,
    required this.fileName,
    required this.builder,
    this.emailSubject,
    this.emailBody,
    this.email,
    this.onOutput,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    ),
    body: PdfPane(fileName: fileName, builder: builder, emailSubject: emailSubject, emailBody: emailBody, email: email, onOutput: onOutput),
  );
}
