import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventAttendeesScreen extends StatelessWidget {
  const EventAttendeesScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  final String eventId;
  final String eventTitle;

  static const Color darkGreen = Color(0xFF062E25);
  static const Color cardGreen = Color(0xFF0F5257);
  static const Color gold = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        title: const Text('Participants'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('eventId', isEqualTo: eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Impossible de charger les participants.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: gold),
            );
          }

          final tickets = snapshot.data!.docs
              .where(
                (doc) => doc.data()['paymentStatus'] == 'purchased',
              )
              .toList()
            ..sort((a, b) {
              final aDate = a.data()['createdAt'] as Timestamp?;
              final bDate = b.data()['createdAt'] as Timestamp?;

              return (bDate?.millisecondsSinceEpoch ?? 0)
                  .compareTo(aDate?.millisecondsSinceEpoch ?? 0);
            });

          final checkedInCount =
              tickets.where((doc) => doc.data()['checkedIn'] == true).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                eventTitle,
                style: const TextStyle(
                  color: gold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Billets',
                      value: '${tickets.length}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Check-in',
                      value: '$checkedInCount',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (tickets.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Center(
                    child: Text(
                      'Aucun participant pour le moment.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              else
                for (final ticket in tickets)
                  _AttendeeCard(data: ticket.data()),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EventAttendeesScreen.cardGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: EventAttendeesScreen.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _AttendeeCard extends StatelessWidget {
  const _AttendeeCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final checkedIn = data['checkedIn'] == true;
    final createdAt = data['createdAt'] as Timestamp?;

    final purchaseDate = createdAt == null
        ? ''
        : '${createdAt.toDate().day.toString().padLeft(2, '0')}/'
            '${createdAt.toDate().month.toString().padLeft(2, '0')}/'
            '${createdAt.toDate().year}';

    final price = (data['unitPrice'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EventAttendeesScreen.cardGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: EventAttendeesScreen.darkGreen,
            child: Icon(
              checkedIn ? Icons.check : Icons.person_outline,
              color: checkedIn ? Colors.greenAccent : EventAttendeesScreen.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['attendeeName']?.toString() ?? 'Participant',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data['buyerEmail']?.toString() ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 5),
                Text(
                  '${data['ticketTypeName'] ?? 'Ticket'} • '
                  '${price <= 0 ? 'Gratuit' : '${price.toStringAsFixed(2)} €'}',
                  style: const TextStyle(
                    color: EventAttendeesScreen.gold,
                  ),
                ),
                if (purchaseDate.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Acheté le $purchaseDate',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: checkedIn
                  ? Colors.green.withValues(alpha: 0.18)
                  : Colors.orange.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              checkedIn ? 'CHECK-IN' : 'À VENIR',
              style: TextStyle(
                color: checkedIn ? Colors.greenAccent : Colors.orangeAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
