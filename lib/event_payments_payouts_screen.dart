import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventPaymentsPayoutsScreen extends StatelessWidget {
  const EventPaymentsPayoutsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  final String eventId;
  final String eventTitle;

  static const Color darkGreen = Color(0xFF062E25);
  static const Color cardGreen = Color(0xFF0F5257);
  static const Color gold = Color(0xFFFFB800);

  // Euro Habesha fee per paid ticket.
  static const double platformFeePerPaidTicket = 0.50;

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString().replaceAll(',', '.') ?? '',
        ) ??
        0;
  }

  String _money(double value) {
    return '${value.toStringAsFixed(2)} €';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payments & Payouts',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('eventId', isEqualTo: eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _PaymentMessage(
              message: 'Unable to load payments: ${snapshot.error}',
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: gold,
              ),
            );
          }

          final purchasedTickets = snapshot.data!.docs.where((doc) {
            return doc.data()['paymentStatus'] == 'purchased';
          }).toList();

          final grossRevenue = purchasedTickets.fold<double>(
            0,
            (total, doc) {
              return total + _toDouble(doc.data()['price']);
            },
          );

          final paidTickets = purchasedTickets.where((doc) {
            return _toDouble(doc.data()['price']) > 0;
          }).toList();

          final platformFees = paidTickets.length * platformFeePerPaidTicket;

          final netRevenue = grossRevenue - platformFees;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                eventTitle,
                style: const TextStyle(
                  color: gold,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Financial overview for this event',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 22),
              _PaymentSummaryCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Gross Revenue',
                amount: _money(grossRevenue),
                subtitle: '${purchasedTickets.length} purchased tickets',
              ),
              const SizedBox(height: 12),
              _PaymentSummaryCard(
                icon: Icons.receipt_long_outlined,
                title: 'Euro Habesha Fees',
                amount: _money(platformFees),
                subtitle:
                    '${paidTickets.length} paid tickets × ${_money(platformFeePerPaidTicket)}',
              ),
              const SizedBox(height: 12),
              _PaymentSummaryCard(
                icon: Icons.payments_outlined,
                title: 'Net Revenue',
                amount: _money(netRevenue),
                subtitle: 'Gross revenue minus Euro Habesha fees',
                highlighted: true,
              ),
              const SizedBox(height: 24),
              const _PaymentInfoCard(),
            ],
          );
        },
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({
    required this.icon,
    required this.title,
    required this.amount,
    required this.subtitle,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String amount;
  final String subtitle;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EventPaymentsPayoutsScreen.cardGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? EventPaymentsPayoutsScreen.gold : Colors.white12,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: EventPaymentsPayoutsScreen.gold,
              size: 26,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(
                    color: highlighted
                        ? EventPaymentsPayoutsScreen.gold
                        : Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentInfoCard extends StatelessWidget {
  const _PaymentInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white12,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: EventPaymentsPayoutsScreen.gold,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Euro Habesha charges 0.50 € for each paid ticket. '
              'Free tickets have no platform fee. '
              'Real payouts will be enabled after the payment provider '
              'is connected.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMessage extends StatelessWidget {
  const _PaymentMessage({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
