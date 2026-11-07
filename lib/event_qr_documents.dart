import 'l10n/app_ui.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

const eventQrDark = Color(0xFF061E12);
const eventQrGold = Color(0xFFFFD700);

String publicEventLink(String eventId) => Uri(
  scheme: 'https',
  host: 'eurohabesha.eu',
  fragment: Uri(path: '/event', queryParameters: {'id': eventId}).toString(),
).toString();

/// Only our HTTPS domain and exact event route are accepted by the scanner.
String? publicEventIdFromCode(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != 'eurohabesha.eu' ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort ||
      uri.path.isNotEmpty && uri.path != '/')
    return null;
  final route = Uri.tryParse(uri.fragment);
  if (route == null || route.path != '/event') return null;
  final id = route.queryParameters['id']?.trim() ?? '';
  return validPublicEventId(id) ? id : null;
}

bool validPublicEventId(String id) =>
    id.isNotEmpty &&
    id.length <= 1500 &&
    !id.contains('/') &&
    id != '.' &&
    id != '..' &&
    !id.contains(RegExp(r'[\x00-\x1F\x7F]'));

class EventQrDocumentScreen extends StatelessWidget {
  const EventQrDocumentScreen({
    super.key,
    required this.title,
    required this.payload,
    required this.details,
    required this.isTicket,
    this.nonRefundable = false,
    this.nonTransferable = false,
  });
  final String title;
  final String payload;
  final List<String> details;
  final bool isTicket;
  final bool nonRefundable;
  final bool nonTransferable;

  String get _notice => isTicket
      ? 'À présenter à l’entrée. Un même billet ne peut être validé qu’une fois.'
      : 'Scannez pour découvrir l’événement et réserver votre billet.';

  // Bundled PDF fonts avoid a network dependency when exporting a ticket.
  String _pdfText(String value) =>
      value.runes.map((r) => r <= 255 ? String.fromCharCode(r) : '?').join();

  Future<Uint8List> _pdf(PdfPageFormat format) async {
    final document = pw.Document();
    final green = PdfColor.fromHex('#061E12');
    final gold = PdfColor.fromHex('#FFD700');
    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            color: green,
            child: pw.Text(
              'EURO HABESHA',
              style: pw.TextStyle(
                color: gold,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            isTicket ? 'BILLET PERSONNEL' : 'INVITATION À DÉCOUVRIR',
            style: pw.TextStyle(fontSize: 12, color: green),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            _pdfText(title),
            style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 18),
          for (final detail in details)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(_pdfText(detail)),
            ),
          pw.Center(
            child: pw.Container(
              color: PdfColors.white,
              padding: const pw.EdgeInsets.all(20),
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: payload,
                width: 210,
                height: 210,
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(_pdfText(_notice)),
          if (!isTicket) ...[
            pw.SizedBox(height: 12),
            pw.Text(payload, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 12),
            pw.Text('Ce QR public ne constitue pas un billet d’entrée.'),
          ],
          if (nonRefundable) pw.Text('Non remboursable.'),
          if (nonTransferable) pw.Text('Non échangeable / non transférable.'),
        ],
      ),
    );
    return document.save();
  }

  Future<void> _export(BuildContext context, {required bool share}) async {
    try {
      if (share) {
        final box = context.findRenderObject() as RenderBox?;
        final bounds = box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size;
        await Printing.sharePdf(
          bytes: await _pdf(PdfPageFormat.a4),
          filename: isTicket
              ? 'Euro_Habesha_Billet.pdf'
              : 'Euro_Habesha_Evenement.pdf',
          bounds: bounds,
        );
      } else {
        await Printing.layoutPdf(name: 'Euro Habesha', onLayout: _pdf);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AppText('Impossible de préparer le PDF : $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: eventQrDark,
    appBar: AppBar(
      backgroundColor: eventQrDark,
      foregroundColor: eventQrGold,
      title: Text(isTicket ? 'Mon billet' : 'Partager l’événement'),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004D40),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: eventQrGold),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppText(
                        'EURO HABESHA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: eventQrGold,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final detail in details)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SelectableText(
                            detail,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(18),
                          child: QrImageView(
                            data: payload,
                            version: QrVersions.auto,
                            size: 210,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _notice,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: eventQrGold,
                          fontSize: 15,
                        ),
                      ),
                      if (nonRefundable)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: AppText(
                            'Non remboursable',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      if (nonTransferable)
                        const AppText(
                          'Non échangeable / non transférable',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: eventQrGold,
                    foregroundColor: eventQrDark,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () => _export(context, share: true),
                  icon: const Icon(Icons.ios_share),
                  label: const AppText('Partager / enregistrer le PDF'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: eventQrGold,
                    side: const BorderSide(color: eventQrGold),
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () => _export(context, share: false),
                  icon: const Icon(Icons.print_outlined),
                  label: const AppText('Imprimer / enregistrer en PDF'),
                ),
                if (!isTicket) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: payload));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: AppText('Lien copié.')),
                      );
                    },
                    icon: const Icon(Icons.link),
                    label: const AppText('Copier le lien'),
                    style: TextButton.styleFrom(foregroundColor: eventQrGold),
                  ),
                  const AppText(
                    'Ce QR public ne constitue pas un billet d’entrée.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
