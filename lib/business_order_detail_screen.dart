import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_receipt_screen.dart';

class BusinessOrderDetailScreen extends StatelessWidget {
  final String orderId;

  const BusinessOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  String _formatMoney(dynamic value) {
    final amount = _toDouble(value);

    if (amount == null) {
      return '—';
    }

    return '${amount.toStringAsFixed(2)} €';
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return '—';
    }

    final date = value.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _statusText(String status) {
    switch (status) {
      case 'placed':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête';
      case 'completed':
        return 'Terminée';
      case 'rejected':
        return 'Refusée';
      case 'cancelled':
        return 'Annulée';
      case 'pendingPayment':
        return 'Paiement en attente';
      default:
        return status;
    }
  }

  String _paymentMethodText(dynamic value) {
    final method = value?.toString().trim().toLowerCase() ?? '';

    if (method.contains('cash') ||
        method.contains('delivery') ||
        method.contains('cod')) {
      return 'Paiement à la livraison';
    }

    if (method.isEmpty) {
      return 'Paiement à la livraison';
    }

    return value.toString();
  }

  List<Map<String, dynamic>> _cartItems(dynamic rawItems) {
    if (rawItems is! List) {
      return <Map<String, dynamic>>[];
    }

    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _updateStatus(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> reference,
    String currentStatus,
    String newStatus,
  ) async {
    try {
      final Map<String, dynamic> update = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'preparing') {
        update['preparingAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'ready') {
        update['readyAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'completed') {
        update['completedAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);

        if (!snapshot.exists) {
          throw Exception('Commande introuvable.');
        }

        final latestStatus = snapshot.data()?['status']?.toString() ?? '';

        if (latestStatus != currentStatus) {
          throw Exception(
            'Le statut de la commande a déjà changé.',
          );
        }

        transaction.update(reference, update);
      });

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande mise à jour.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de modifier la commande : $error',
          ),
        ),
      );
    }
  }

  Future<void> _callPhone(
    BuildContext context,
    String phoneNumber,
  ) async {
    final cleanNumber = phoneNumber.trim();

    if (cleanNumber.isEmpty) {
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    if (!await launchUrl(uri)) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d’ouvrir le téléphone.',
          ),
        ),
      );
    }
  }

  Future<void> _markAsPaid(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    try {
      await reference.update({
        'paymentStatus': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paiement marqué comme payé.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de mettre à jour le paiement : $error',
          ),
        ),
      );
    }
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white54,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: primaryGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryGold.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: primaryGold,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        elevation: 0,
        title: const Text(
          'Détail de la commande',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('cashOnDeliveryOrders')
            .doc(orderId)
            .snapshots(),
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
                  'Impossible de charger la commande.\n'
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

          final document = snapshot.data!;
          final data = document.data()!;

          final sellerId = data['sellerId']?.toString() ?? '';

          final isSeller = user != null && user.uid == sellerId;

          final status = data['status']?.toString() ?? 'placed';

          final buyerName = data['buyerName']?.toString().trim() ?? '';

          final buyerPhone = data['buyerPhone']?.toString().trim() ?? '';

          final deliveryAddress =
              data['deliveryAddress']?.toString().trim() ?? '';

          final notes = data['notes']?.toString().trim() ?? '';

          final sellerName = data['sellerName']?.toString().trim() ?? '';

          final sellerContact = data['sellerContact']?.toString().trim() ?? '';

          final items = _cartItems(data['cartItems']);

          final total = data['orderTotal'] ?? data['cartTotal'];

          final shortOrderId = orderId.length > 8
              ? orderId.substring(0, 8).toUpperCase()
              : orderId.toUpperCase();

          final createdAt = data['createdAt'] ?? data['orderedAt'];

          final paymentMethod = _paymentMethodText(data['paymentMethod']);

          final isPaid =
              data['paymentStatus'] == 'paid' || data['isPaid'] == true;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              32,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardGreen,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: primaryGold.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: primaryGold,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'COMMANDE',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '#$shortOrderId',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _statusBadge(
                          _statusText(status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (sellerName.isNotEmpty) ...[
                      Text(
                        sellerName,
                        style: const TextStyle(
                          color: primaryGold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                    if (sellerContact.isNotEmpty)
                      Text(
                        sellerContact,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    const SizedBox(height: 14),
                    const Divider(
                      color: Colors.white12,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      Icons.calendar_today_outlined,
                      'Date',
                      _formatDate(createdAt),
                    ),
                    _infoRow(
                      Icons.person_outline,
                      'Client',
                      buyerName.isEmpty ? 'Client' : buyerName,
                    ),
                    if (buyerPhone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _callPhone(
                            context,
                            buyerPhone,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  color: primaryGold,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Téléphone',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        buyerPhone,
                                        style: const TextStyle(
                                          color: primaryGold,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.call_outlined,
                                  color: primaryGold,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    _infoRow(
                      Icons.location_on_outlined,
                      'Adresse',
                      deliveryAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Articles',
                      style: TextStyle(
                        color: primaryGold,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (items.isEmpty)
                      const Text(
                        'Aucun détail disponible.',
                        style: TextStyle(
                          color: Colors.white60,
                        ),
                      )
                    else
                      ...items.map((item) {
                        final name = item['name']?.toString() ?? 'Article';

                        final quantity =
                            (item['quantity'] as num?)?.toInt() ?? 1;

                        final lineTotal = item['total'] ?? item['lineTotal'];

                        final unitPrice = item['price'];

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 13,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: primaryGold.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    8,
                                  ),
                                ),
                                child: Text(
                                  '$quantity×',
                                  style: const TextStyle(
                                    color: primaryGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (unitPrice != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 2,
                                        ),
                                        child: Text(
                                          '${_formatMoney(unitPrice)} / unité',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _formatMoney(
                                  lineTotal ??
                                      ((_toDouble(
                                                unitPrice,
                                              ) ??
                                              0) *
                                          quantity),
                                ),
                                style: const TextStyle(
                                  color: primaryGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const Divider(
                      color: Colors.white12,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatMoney(total),
                          style: const TextStyle(
                            color: primaryGold,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Note du client',
                        style: TextStyle(
                          color: primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        notes,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paiement',
                      style: TextStyle(
                        color: primaryGold,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _infoRow(
                      Icons.payments_outlined,
                      'Mode de paiement',
                      paymentMethod,
                    ),
                    Row(
                      children: [
                        Icon(
                          isPaid ? Icons.check_circle : Icons.schedule,
                          color: isPaid ? Colors.greenAccent : primaryGold,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          isPaid ? 'PAYÉ' : 'NON PAYÉ',
                          style: TextStyle(
                            color: isPaid ? Colors.greenAccent : primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (isSeller && !isPaid) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _markAsPaid(
                            context,
                            document.reference,
                          ),
                          icon: const Icon(
                            Icons.payments_outlined,
                          ),
                          label: const Text(
                            'Marquer comme payé',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryGold,
                            side: const BorderSide(
                              color: primaryGold,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderReceiptScreen(
                          orderId: orderId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.receipt_long_outlined,
                  ),
                  label: const Text(
                    'Voir / télécharger le reçu',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGold,
                    foregroundColor: primaryDarkGreen,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              if (isSeller) ...[
                const SizedBox(height: 20),
                if (status == 'placed')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateStatus(
                            context,
                            document.reference,
                            status,
                            'rejected',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          child: const Text('Refuser'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateStatus(
                            context,
                            document.reference,
                            status,
                            'accepted',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGold,
                            foregroundColor: primaryDarkGreen,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          child: const Text('Accepter'),
                        ),
                      ),
                    ],
                  ),
                if (status == 'accepted')
                  _ActionButton(
                    icon: Icons.restaurant_menu,
                    text: 'Commencer la préparation',
                    onPressed: () => _updateStatus(
                      context,
                      document.reference,
                      status,
                      'preparing',
                    ),
                  ),
                if (status == 'preparing')
                  _ActionButton(
                    icon: Icons.check_circle_outline,
                    text: 'Marquer comme prête',
                    onPressed: () => _updateStatus(
                      context,
                      document.reference,
                      status,
                      'ready',
                    ),
                  ),
                if (status == 'ready')
                  _ActionButton(
                    icon: Icons.done_all,
                    text: 'Terminer la commande',
                    onPressed: () => _updateStatus(
                      context,
                      document.reference,
                      status,
                      'completed',
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: BusinessOrderDetailScreen.primaryGold,
          foregroundColor: BusinessOrderDetailScreen.primaryDarkGreen,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
        ),
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
