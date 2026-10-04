import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventSalesScreen extends StatelessWidget {
  const EventSalesScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  final String eventId;
  final String eventTitle;

  static const Color darkGreen = Color(0xFF062E25);
  static const Color cardGreen = Color(0xFF0F5257);
  static const Color gold = Color(0xFFFFB800);

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(
          value?.toString().replaceAll(',', '.') ?? '',
        ) ??
        0;
  }

  String _money(double value) {
    return '${value.toStringAsFixed(2)} €';
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'Date indisponible';
    }

    final date = value.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Ventes et participants',
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
            return _Message(
              text: 'Impossible de charger les ventes : ${snapshot.error}',
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: gold,
              ),
            );
          }

          final tickets = [...snapshot.data!.docs]..sort((a, b) {
              final aDate = a.data()['createdAt'] as Timestamp?;
              final bDate = b.data()['createdAt'] as Timestamp?;

              return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(
                aDate?.millisecondsSinceEpoch ?? 0,
              );
            });

          final purchasedTickets = tickets.where((doc) {
            return doc.data()['paymentStatus'] == 'purchased';
          }).toList();

          final checkedInCount = purchasedTickets.where((doc) {
            return doc.data()['checkedIn'] == true;
          }).length;

          final revenue = purchasedTickets.fold<double>(
            0,
            (total, doc) {
              return total + _toDouble(doc.data()['price']);
            },
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                eventTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Suivez les ventes, les participants et les entrées.',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Billets vendus',
                      value: '${purchasedTickets.length}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.euro,
                      label: 'Revenus',
                      value: _money(revenue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.login,
                      label: 'Entrées',
                      value: '$checkedInCount',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.schedule,
                      label: 'À entrer',
                      value: '${purchasedTickets.length - checkedInCount}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Participants',
                style: TextStyle(
                  color: gold,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              if (tickets.isEmpty)
                const _Message(
                  text: 'Aucun billet vendu pour cet événement.',
                )
              else
                ...tickets.map(
                  (ticketDocument) {
                    final ticket = ticketDocument.data();

                    final attendee =
                        ticket['attendeeName']?.toString().trim() ?? '';

                    final email = ticket['buyerEmail']?.toString().trim() ?? '';

                    final ticketType =
                        ticket['ticketTypeName']?.toString().trim() ?? 'Billet';

                    final paymentStatus =
                        ticket['paymentStatus']?.toString().trim() ?? 'unknown';

                    final checkedIn = ticket['checkedIn'] == true;

                    final price = _toDouble(ticket['price']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: cardGreen,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white12,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  attendee.isEmpty ? 'Participant' : attendee,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              _StatusBadge(
                                checkedIn: checkedIn,
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoChip(
                                icon: Icons.confirmation_number_outlined,
                                text: ticketType,
                              ),
                              _InfoChip(
                                icon: Icons.euro,
                                text: _money(price),
                              ),
                              _InfoChip(
                                icon: paymentStatus == 'purchased'
                                    ? Icons.check_circle_outline
                                    : Icons.pending_outlined,
                                text: paymentStatus,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Achat : ${_formatDate(ticket['createdAt'])}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Billet : ${ticketDocument.id}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EventSalesScreen.cardGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: EventSalesScreen.gold,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: EventSalesScreen.gold,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.checkedIn,
  });

  final bool checkedIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: checkedIn ? EventSalesScreen.gold : Colors.white12,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        checkedIn ? 'Entré' : 'Non scanné',
        style: TextStyle(
          color: checkedIn ? Colors.black : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
