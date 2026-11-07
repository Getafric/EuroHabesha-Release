import 'l10n/app_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'event_financial_summary.dart';

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

  // EH_EVENT_RECORDED_FEES_V1: saved facts, no hard-coded commission.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const AppText(
          'Paiements et versements',
          style: TextStyle(fontWeight: FontWeight.w800),
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
            return const Center(child: CircularProgressIndicator(color: gold));
          }

          final finance = EventFinancialSummary.fromTickets(
            snapshot.data!.docs.map((doc) => doc.data()),
            eventId,
          );

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
              const AppText(
                'Montants enregistrés pour cet événement',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 22),
              _PaymentSummaryCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Ventes de billets enregistrées',
                amount: eventSavedMoney(finance.grossCents),
                subtitle:
                    '${finance.count} billets enregistrés ; ${finance.unknownMode} sans mode de paiement confirmé',
              ),
              const SizedBox(height: 12),
              _PaymentSummaryCard(
                icon: Icons.receipt_long_outlined,
                title: 'Commission Euro Habesha',
                amount: eventSavedMoney(finance.merchantCommissionCents),
                subtitle:
                    'Commission professionnelle enregistrée, hors frais Stripe',
              ),
              const SizedBox(height: 12),
              _PaymentSummaryCard(
                icon: Icons.payments_outlined,
                title: 'Net calculable avec les frais connus',
                amount: eventSavedMoney(finance.merchantNetCents),
                subtitle: 'Après frais enregistrés. Aucun virement bancaire confirmé ici.',
                highlighted: true,
              ),
              const SizedBox(height: 24),
              AppText(
                'Frais clients enregistrés : ${eventSavedMoney(finance.customerFeesCents)}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              AppText(
                'Frais Stripe enregistrés : ${eventSavedMoney(finance.stripeFeesCents)}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
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
            child: Icon(icon, color: EventPaymentsPayoutsScreen.gold, size: 26),
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
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
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
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: EventPaymentsPayoutsScreen.gold),
          SizedBox(width: 12),
          Expanded(
            child: AppText(
              'Les frais proviennent des données sauvegardées au paiement. '
              'Un montant absent reste non renseigné. Les frais clients ne '
              'sont pas une commission professionnelle. Aucun forfait de '
              '0,50 € n’est déduit automatiquement par cet écran.',
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
  const _PaymentMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
