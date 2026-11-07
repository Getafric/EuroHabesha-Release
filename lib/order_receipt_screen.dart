import 'l10n/app_ui.dart';

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'professional_sales_summary.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OrderReceiptScreen extends StatelessWidget {
  final String orderId;
  final bool professionalCopy;

  const OrderReceiptScreen({
    super.key,
    required this.orderId,
    this.professionalCopy = false,
  });

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);

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

  // Use the saved establishment, never the first profile owned by the seller.
  // Do not read private verification documents or today's mutable profile.
  Map<String, dynamic> _savedProfessional(Map<String, dynamic> orderData) {
    if (professionalOrderSource(orderData) == null) return {};
    return orderMap(orderData['sourceData']);
  }

  Future<Uint8List> _buildPdf(
    Map<String, dynamic> data,
    String viewerUid,
  ) async {
    if (FirebaseAuth.instance.currentUser?.uid != viewerUid ||
        !_canView(data, viewerUid) ||
        (professionalCopy && orderText(data['sellerId']) != viewerUid)) {
      throw StateError('Accès au reçu indisponible.');
    }
    final pdf = pw.Document();

    // Police compatible amharique / tigrinya / ge'ez.
    final ethiopicFont = await PdfGoogleFonts.notoSansEthiopicRegular();

    final latinFont = await PdfGoogleFonts.notoSansRegular();
    final latinBold = await PdfGoogleFonts.notoSansBold();

    final professional = _savedProfessional(data);
    final professionalFields = _fields(professional);

    final items = _items(data['cartItems']);

    final money = OrderMoneySnapshot.fromOrder(data);
    final currency = orderText(data['currency']).isEmpty
        ? 'EUR'
        : orderText(data['currency']).toUpperCase();
    String amount(int? cents) => savedOrderMoney(cents, currency: currency);

    final buyerName = _text(data['buyerName']);
    final buyerPhone = _text(data['buyerPhone']);
    final deliveryAddress = _text(data['deliveryAddress']);
    final notes = _text(data['notes']);

    final createdAt = data['createdAt'] ?? data['orderedAt'];

    final stripeVerified =
        data['paymentProvider'] == 'stripe_connect_live' &&
        data['paymentVerified'] == true;
    final paymentLabel = stripeVerified
        ? data['paymentStatus'] == 'refunded'
              ? 'Remboursement confirmé par Stripe'
              : data['paymentStatus'] == 'partially_refunded'
              ? 'Remboursement partiel confirmé'
              : data['paymentStatus'] == 'disputed'
              ? 'Paiement contesté : contrôle Stripe nécessaire'
              : data['refundStatus'] == 'pending'
              ? 'Remboursement en attente'
              : 'Paiement confirmé par Stripe'
        : savedOrderPaymentLabel(data);
    final method = orderCashPayment(data)
        ? 'Paiement à la livraison / espèces'
        : orderOnlinePayment(data)
        ? 'Paiement en ligne'
        : orderText(data['paymentMethod']).toLowerCase() == 'appdeposit'
        ? 'Acompte dans l’application'
        : 'Mode non renseigné';

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
      sellerName = 'Établissement non renseigné';
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
    const ticketFormat = PdfPageFormat(
      80 * PdfPageFormat.mm,
      250 * PdfPageFormat.mm,
      marginAll: 4 * PdfPageFormat.mm,
    );

    final theme = pw.ThemeData.withFont(
      base: latinFont,
      bold: latinBold,
      fontFallback: [ethiopicFont],
    );

    pdf.addPage(
      pw.MultiPage(
        maxPages: 100,
        pageFormat: ticketFormat,
        theme: theme,
        build: (context) {
          return <pw.Widget>[
            // ─────────────────────────────
            // PROFESSIONAL
            // ─────────────────────────────
            pw.Center(
              child: pw.Text(
                sellerName,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
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
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),

            if (sellerPhone.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  'Tel : $sellerPhone',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),

            if (sellerEmail.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  sellerEmail,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),

            if (siret.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  'SIRET : $siret',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),

            pw.SizedBox(height: 8),

            _ticketDivider(),

            pw.SizedBox(height: 7),

            pw.Center(
              child: pw.Text(
                professionalCopy ? 'RELEVE PROFESSIONNEL' : 'RECU DE COMMANDE',
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 7),

            pw.Text(
              'Commande : #$shortOrderId',
              style: const pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.Text(
              'Date : ${_formatDate(createdAt)}',
              style: const pw.TextStyle(fontSize: 8),
            ),

            pw.SizedBox(height: 7),

            _ticketDivider(),

            pw.SizedBox(height: 7),

            // ─────────────────────────────
            // CLIENT
            // ─────────────────────────────
            pw.Text(
              'CLIENT',
              style: const pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 3),

            pw.Text(
              buyerName.isEmpty ? 'Client' : buyerName,
              style: const pw.TextStyle(fontSize: 8),
            ),

            if (buyerPhone.isNotEmpty)
              pw.Text(
                'Tel : $buyerPhone',
                style: const pw.TextStyle(fontSize: 8),
              ),

            if (deliveryAddress.isNotEmpty)
              pw.Text(deliveryAddress, style: const pw.TextStyle(fontSize: 8)),

            pw.SizedBox(height: 7),

            _ticketDivider(),

            pw.SizedBox(height: 7),

            // ─────────────────────────────
            // ARTICLES
            // ─────────────────────────────
            pw.Text(
              'ARTICLES',
              style: const pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 5),

            ...items.map((item) {
              final rawQuantity = item['quantity'];
              final quantity = rawQuantity == null
                  ? 1
                  : rawQuantity is num &&
                        rawQuantity.isFinite &&
                        rawQuantity > 0 &&
                        rawQuantity == rawQuantity.round()
                  ? rawQuantity.toInt()
                  : null;
              final unitPrice = savedOrderCents(
                item['unitPrice'] ?? item['price'],
              );
              final lineTotal = item.containsKey('total')
                  ? savedOrderCents(item['total'])
                  : unitPrice != null && quantity != null
                  ? unitPrice * quantity
                  : null;

              final name = _text(item['name']).isEmpty
                  ? 'Article'
                  : _text(item['name']);

              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      name,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    _amountRow(
                      '${quantity ?? '?'} x ${amount(unitPrice)}',
                      amount(lineTotal),
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
            if (orderIsTest(data))
              pw.Text(
                'COMMANDE DE TEST - aucun paiement réel',
                style: const pw.TextStyle(fontSize: 9),
              ),
            _amountRow('Sous-total', amount(money.subtotal)),
            _amountRow('Frais clients enregistrés', amount(money.customerFee)),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: const pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    amount(money.consistent ? money.customerTotal : null),
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (!money.consistent)
              pw.Text(
                'Montants incohérents : vérifier la commande.',
                style: const pw.TextStyle(fontSize: 8),
              ),
            if (money.legacyTotal)
              pw.Text(
                'Ancienne commande : les frais ne sont pas détaillés.',
                style: const pw.TextStyle(fontSize: 8),
              ),
            if (professionalCopy) ...[
              pw.SizedBox(height: 8),
              _amountRow(
                'Commission commerçant enregistrée',
                amount(money.businessFee),
              ),
              if (orderOnlinePayment(data))
                _amountRow(
                  'Frais Stripe enregistrés',
                  amount(
                    data['stripeFeeCents'] is int && data['stripeFeeCents'] >= 0
                        ? data['stripeFeeCents'] as int
                        : null,
                  ),
                ),
              pw.Text(
                money.businessFee == 0 ||
                        data['commissionCollectionStatus'] == 'notApplicable'
                    ? 'Aucune commission Euro Habesha'
                    : data['commissionCollectionStatus'] == 'refunded'
                    ? 'Commission remboursée'
                    : data['commissionCollectionStatus'] == 'collected'
                    ? 'Commission marquée prélevée'
                    : 'Prélèvement de la commission non confirmé',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
            pw.SizedBox(height: 8),
            _ticketDivider(),
            pw.SizedBox(height: 7),

            // ─────────────────────────────
            // PAYMENT
            // ─────────────────────────────
            pw.Text(
              'PAIEMENT',
              style: const pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 3),

            pw.Text(method, style: const pw.TextStyle(fontSize: 8)),
            if (stripeVerified &&
                data['refundedAmountCents'] is int &&
                data['refundedAmountCents'] > 0)
              _amountRow(
                'Montant remboursé confirmé',
                amount(data['refundedAmountCents'] as int),
              ),

            pw.SizedBox(height: 3),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 6,
              ),
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
              child: pw.Center(
                child: pw.Text(
                  paymentLabel,
                  style: const pw.TextStyle(
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
                style: const pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(notes, style: const pw.TextStyle(fontSize: 8)),
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
                style: const pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 6),

            pw.Center(
              child: pw.Text(
                'EURO HABESHA',
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 2),

            pw.Center(
              child: pw.Text(
                'Commande #$shortOrderId',
                style: const pw.TextStyle(fontSize: 7),
              ),
            ),

            pw.SizedBox(height: 4),

            pw.Center(
              child: pw.Text(
                'Document issu de la commande. Ne prouve pas un versement bancaire.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ];
        },
      ),
    );

    if (FirebaseAuth.instance.currentUser?.uid != viewerUid) {
      throw StateError('Veuillez vous reconnecter pour ouvrir le reçu.');
    }
    return pdf.save();
  }

  pw.Widget _amountRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        ),
        pw.SizedBox(width: 5),
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ],
    ),
  );

  bool _canView(Map<String, dynamic> data, String uid) =>
      uid.isNotEmpty &&
      (orderText(data['sellerId']) == uid ||
          (orderText(data['buyerId']).isNotEmpty
                  ? orderText(data['buyerId'])
                  : orderText(data['userId'])) ==
              uid);

  pw.Widget _ticketDivider() {
    return pw.Container(height: 0.7, color: PdfColors.grey700);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        title: const AppText(
          'Reçu de commande',
          style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, auth) {
          final user = auth.data;
          if (user == null || user.isAnonymous) {
            return const Center(
              child: AppText(
                'Connectez-vous pour lire ce reçu.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          return _receipt(context, user.uid);
        },
      ),
    );
  }

  Widget _receipt(
    BuildContext context,
    String uid,
  ) => FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    key: ValueKey('$uid:$orderId:$professionalCopy'),
    future: FirebaseFirestore.instance
        .collection('cashOnDeliveryOrders')
        .doc(orderId)
        .get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(color: primaryGold),
        );
      }

      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppText(
              'Impossible de charger le reçu.\n'
              '${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        );
      }

      if (!snapshot.hasData ||
          !snapshot.data!.exists ||
          snapshot.data!.data() == null) {
        return const Center(
          child: AppText(
            'Commande introuvable.',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      final data = snapshot.data!.data()!;
      final seller = orderText(data['sellerId']) == uid;
      if (!_canView(data, uid) || (professionalCopy && !seller)) {
        return const Center(
          child: AppText(
            'Accès au reçu non autorisé.',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      final shortOrderId = orderId.length > 8
          ? orderId.substring(0, 8).toUpperCase()
          : orderId.toUpperCase();

      return Column(
        children: [
          if (seller)
            TextButton.icon(
              icon: const Icon(Icons.description_outlined),
              label: Text(
                professionalCopy
                    ? 'Ouvrir le reçu client'
                    : 'Ouvrir mon relevé professionnel',
              ),
              onPressed: () => Navigator.pushReplacement<void, void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => OrderReceiptScreen(
                    orderId: orderId,
                    professionalCopy: !professionalCopy,
                  ),
                ),
              ),
            ),
          Expanded(
            child: PdfPreview(
              build: (_) => _buildPdf(data, uid),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              pdfFileName:
                  'EuroHabesha_${professionalCopy ? 'Pro' : 'Ticket'}_$shortOrderId.pdf',
            ),
          ),
        ],
      );
    },
  );
}
