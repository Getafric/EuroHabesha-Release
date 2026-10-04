import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OrderReceiptScreen extends StatelessWidget {
  final String orderId;

  const OrderReceiptScreen({
    super.key,
    required this.orderId,
  });

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    return '${_toDouble(value).toStringAsFixed(2)} EUR';
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'Date non disponible';
    }

    final date = value.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _text(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  List<Map<String, dynamic>> _items(dynamic rawItems) {
    if (rawItems is! List) {
      return <Map<String, dynamic>>[];
    }

    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _fields(Map<String, dynamic> data) {
    final raw = data['fields'];

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _loadProfessional(
    Map<String, dynamic> orderData,
  ) async {
    final sellerId = _text(orderData['sellerId']);

    if (sellerId.isEmpty) {
      return <String, dynamic>{};
    }

    final firestore = FirebaseFirestore.instance;

    // 1. Professional / Catering submission
    try {
      final query = await firestore
          .collection('jobSubmissions')
          .where('ownerId', isEqualTo: sellerId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
    } catch (_) {}

    // 2. Business submission
    try {
      final query = await firestore
          .collection('businessSubmissions')
          .where('ownerId', isEqualTo: sellerId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
    } catch (_) {}

    // 3. Published jobs
    try {
      final query = await firestore
          .collection('jobs')
          .where('ownerId', isEqualTo: sellerId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
    } catch (_) {}

    return <String, dynamic>{};
  }

  Future<Uint8List> _buildPdf(
    Map<String, dynamic> data,
  ) async {
    final pdf = pw.Document();

    // Police compatible amharique / tigrinya / ge'ez.
    final ethiopicFont = await PdfGoogleFonts.notoSansEthiopicRegular();

    final ethiopicBold = await PdfGoogleFonts.notoSansEthiopicBold();

    final professional = await _loadProfessional(data);
    final professionalFields = _fields(professional);

    final items = _items(data['cartItems']);

    final total = data['orderTotal'] ?? data['cartTotal'] ?? 0;

    final buyerName = _text(data['buyerName']);
    final buyerPhone = _text(data['buyerPhone']);
    final deliveryAddress = _text(data['deliveryAddress']);
    final notes = _text(data['notes']);

    final createdAt = data['createdAt'] ?? data['orderedAt'];

    final isPaid = data['paymentStatus'] == 'paid' || data['isPaid'] == true;

    String sellerName = _text(professionalFields['title']);

    if (sellerName.isEmpty) {
      sellerName = _text(professional['title']);
    }

    if (sellerName.isEmpty) {
      sellerName = _text(professional['name']);
    }

    if (sellerName.isEmpty) {
      sellerName = _text(data['sellerName']);
    }

    if (sellerName.isEmpty) {
      sellerName = 'EURO HABESHA';
    }

    String sellerPhone = _text(professionalFields['phone']);

    if (sellerPhone.isEmpty) {
      sellerPhone = _text(professionalFields['phoneNumber']);
    }

    if (sellerPhone.isEmpty) {
      sellerPhone = _text(professional['phone']);
    }

    if (sellerPhone.isEmpty) {
      sellerPhone = _text(data['sellerContact']);
    }

    String sellerEmail = _text(professionalFields['emailAddress']);

    if (sellerEmail.isEmpty) {
      sellerEmail = _text(professionalFields['email']);
    }

    if (sellerEmail.isEmpty) {
      sellerEmail = _text(professional['email']);
    }

    if (sellerEmail.isEmpty) {
      sellerEmail = _text(professional['submitterEmail']);
    }

    String sellerAddress = _text(professionalFields['address']);

    if (sellerAddress.isEmpty) {
      sellerAddress = _text(professionalFields['cityAddress']);
    }

    if (sellerAddress.isEmpty) {
      sellerAddress = _text(professional['address']);
    }

    if (sellerAddress.isEmpty) {
      sellerAddress = _text(professional['location']);
    }

    String siret = _text(professionalFields['siret']);

    if (siret.isEmpty) {
      siret = _text(professional['siret']);
    }

    if (siret.toLowerCase().startsWith('siret:')) {
      siret = siret.substring(6).trim();
    }

    final shortOrderId = orderId.length > 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();

    /*
     * Ticket thermique 80 mm.
     *
     * La hauteur est volontairement assez grande.
     * Le PDF n'est plus une feuille A4.
     */
    final ticketFormat = PdfPageFormat(
      80 * PdfPageFormat.mm,
      250 * PdfPageFormat.mm,
      marginAll: 4 * PdfPageFormat.mm,
    );

    final theme = pw.ThemeData.withFont(
      base: ethiopicFont,
      bold: ethiopicBold,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: ticketFormat,
        theme: theme,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 2,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ─────────────────────────────
                // PROFESSIONAL
                // ─────────────────────────────

                pw.Center(
                  child: pw.Text(
                    sellerName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.SizedBox(height: 4),

                if (sellerAddress.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      sellerAddress,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 8,
                      ),
                    ),
                  ),

                if (sellerPhone.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      'Tel : $sellerPhone',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 8,
                      ),
                    ),
                  ),

                if (sellerEmail.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      sellerEmail,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 8,
                      ),
                    ),
                  ),

                if (siret.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      'SIRET : $siret',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 8,
                      ),
                    ),
                  ),

                pw.SizedBox(height: 8),

                _ticketDivider(),

                pw.SizedBox(height: 7),

                pw.Center(
                  child: pw.Text(
                    'RECU DE COMMANDE',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.SizedBox(height: 7),

                pw.Text(
                  'Commande : #$shortOrderId',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.Text(
                  'Date : ${_formatDate(createdAt)}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                  ),
                ),

                pw.SizedBox(height: 7),

                _ticketDivider(),

                pw.SizedBox(height: 7),

                // ─────────────────────────────
                // CLIENT
                // ─────────────────────────────

                pw.Text(
                  'CLIENT',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 3),

                pw.Text(
                  buyerName.isEmpty ? 'Client' : buyerName,
                  style: const pw.TextStyle(
                    fontSize: 8,
                  ),
                ),

                if (buyerPhone.isNotEmpty)
                  pw.Text(
                    'Tel : $buyerPhone',
                    style: const pw.TextStyle(
                      fontSize: 8,
                    ),
                  ),

                if (deliveryAddress.isNotEmpty)
                  pw.Text(
                    deliveryAddress,
                    style: const pw.TextStyle(
                      fontSize: 8,
                    ),
                  ),

                pw.SizedBox(height: 7),

                _ticketDivider(),

                pw.SizedBox(height: 7),

                // ─────────────────────────────
                // ARTICLES
                // ─────────────────────────────

                pw.Text(
                  'ARTICLES',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 5),

                ...items.map((item) {
                  final quantity = (item['quantity'] as num?)?.toInt() ?? 1;

                  final unitPrice = _toDouble(item['price']);

                  final lineTotal = item['total'] != null
                      ? _toDouble(item['total'])
                      : unitPrice * quantity;

                  final name = _text(item['name']).isEmpty
                      ? 'Article'
                      : _text(item['name']);

                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(
                      bottom: 5,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          name,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '$quantity x ${_money(unitPrice)}',
                              style: const pw.TextStyle(
                                fontSize: 8,
                              ),
                            ),
                            pw.Text(
                              _money(lineTotal),
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 3),

                _ticketDivider(),

                pw.SizedBox(height: 7),

                // ─────────────────────────────
                // TOTAL
                // ─────────────────────────────

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _money(total),
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 8),

                _ticketDivider(),

                pw.SizedBox(height: 7),

                // ─────────────────────────────
                // PAYMENT
                // ─────────────────────────────

                pw.Text(
                  'PAIEMENT',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 3),

                pw.Text(
                  'Paiement a la livraison',
                  style: const pw.TextStyle(
                    fontSize: 8,
                  ),
                ),

                pw.SizedBox(height: 3),

                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      width: 1,
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      isPaid ? 'PAYE' : 'NON PAYE',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                if (notes.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  _ticketDivider(),
                  pw.SizedBox(height: 7),
                  pw.Text(
                    'NOTE',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    notes,
                    style: const pw.TextStyle(
                      fontSize: 8,
                    ),
                  ),
                ],

                pw.SizedBox(height: 10),

                _ticketDivider(),

                pw.SizedBox(height: 8),

                // ─────────────────────────────
                // EURO HABESHA
                // ─────────────────────────────

                pw.Center(
                  child: pw.Text(
                    'Merci pour votre commande',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.SizedBox(height: 6),

                pw.Center(
                  child: pw.Text(
                    'EURO HABESHA',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.SizedBox(height: 2),

                pw.Center(
                  child: pw.Text(
                    'Commande #$shortOrderId',
                    style: const pw.TextStyle(
                      fontSize: 7,
                    ),
                  ),
                ),

                pw.SizedBox(height: 4),

                pw.Center(
                  child: pw.Text(
                    'Recu genere par Euro Habesha',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _ticketDivider() {
    return pw.Container(
      height: 0.7,
      color: PdfColors.grey700,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        title: const Text(
          'Reçu de commande',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('cashOnDeliveryOrders')
            .doc(orderId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Impossible de charger le reçu.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists ||
              snapshot.data!.data() == null) {
            return const Center(
              child: Text(
                'Commande introuvable.',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            );
          }

          final data = snapshot.data!.data()!;

          final shortOrderId = orderId.length > 8
              ? orderId.substring(0, 8).toUpperCase()
              : orderId.toUpperCase();

          return PdfPreview(
            build: (_) => _buildPdf(data),
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            pdfFileName: 'EuroHabesha_Ticket_$shortOrderId.pdf',
          );
        },
      ),
    );
  }
}
