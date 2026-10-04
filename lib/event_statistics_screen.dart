import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventStatisticsScreen extends StatelessWidget {
  const EventStatisticsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  final String eventId;
  final String eventTitle;

  static const Color darkGreen = Color(0xFF062E25);
  static const Color cardGreen = Color(0xFF0F5257);
  static const Color gold = Color(0xFFFFB800);

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

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

  @override
  Widget build(BuildContext context) {
    final eventRef =
        FirebaseFirestore.instance.collection('events').doc(eventId);

    final ticketsQuery = FirebaseFirestore.instance
        .collection('tickets')
        .where('eventId', isEqualTo: eventId);

    return Scaffold(
      backgroundColor: darkGreen,
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Statistiques',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: eventRef.snapshots(),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.hasError) {
            return const _Message(
              text: 'Impossible de charger les statistiques.',
            );
          }

          if (!eventSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: gold,
              ),
            );
          }

          final eventData = eventSnapshot.data!.data() ?? <String, dynamic>{};

          final rawTypes = eventData['ticketTypes'];

          final ticketTypes = <Map<String, dynamic>>[];

          if (rawTypes is List) {
            for (final raw in rawTypes) {
              if (raw is Map) {
                ticketTypes.add(
                  Map<String, dynamic>.from(raw),
                );
              }
            }
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ticketsQuery.snapshots(),
            builder: (context, ticketSnapshot) {
              if (ticketSnapshot.hasError) {
                return const _Message(
                  text: 'Impossible de charger les données des billets.',
                );
              }

              if (!ticketSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: gold,
                  ),
                );
              }

              final purchasedTickets = ticketSnapshot.data!.docs.where((doc) {
                return doc.data()['paymentStatus'] == 'purchased';
              }).toList();

              final sold = purchasedTickets.length;

              final checkedIn = purchasedTickets.where((doc) {
                return doc.data()['checkedIn'] == true;
              }).length;

              final revenue = purchasedTickets.fold<double>(
                0,
                (total, doc) => total + _toDouble(doc.data()['price']),
              );

              final capacity = ticketTypes.fold<int>(
                0,
                (total, type) => total + _toInt(type['capacity']),
              );

              final remaining = (capacity - sold).clamp(0, capacity);

              final checkInRate = sold == 0 ? 0.0 : (checkedIn / sold) * 100;

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
                    'Vue générale des performances de votre événement.',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.confirmation_number_outlined,
                          label: 'Vendus',
                          value: '$sold',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.event_seat_outlined,
                          label: 'Restants',
                          value: '$remaining',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.euro,
                          label: 'Revenus',
                          value: _money(revenue),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.qr_code_scanner,
                          label: 'Entrées',
                          value: '$checkedIn',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.chair_outlined,
                          label: 'Capacité',
                          value: '$capacity',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.percent,
                          label: 'Taux entrée',
                          value: '${checkInRate.toStringAsFixed(1)} %',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Par type de billet',
                    style: TextStyle(
                      color: gold,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (ticketTypes.isEmpty)
                    const _Message(
                      text: 'Aucun type de billet configuré.',
                    )
                  else
                    ...ticketTypes.map((type) {
                      final typeId = type['id']?.toString() ?? '';

                      final name = type['name']?.toString() ?? 'Billet';

                      final typeCapacity = _toInt(type['capacity']);

                      final typeTickets = purchasedTickets.where((doc) {
                        return doc.data()['ticketTypeId']?.toString() == typeId;
                      }).toList();

                      final typeSold = typeTickets.length;

                      final typeChecked = typeTickets.where((doc) {
                        return doc.data()['checkedIn'] == true;
                      }).length;

                      final typeRevenue = typeTickets.fold<double>(
                        0,
                        (total, doc) =>
                            total +
                            _toDouble(
                              doc.data()['price'],
                            ),
                      );

                      final typeRemaining = (typeCapacity - typeSold).clamp(
                        0,
                        typeCapacity,
                      );

                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardGreen,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _Line(
                              label: 'Capacité',
                              value: '$typeCapacity',
                            ),
                            _Line(
                              label: 'Vendus',
                              value: '$typeSold',
                            ),
                            _Line(
                              label: 'Restants',
                              value: '$typeRemaining',
                            ),
                            _Line(
                              label: 'Entrées QR',
                              value: '$typeChecked',
                            ),
                            _Line(
                              label: 'Revenus',
                              value: _money(typeRevenue),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              );
            },
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
        color: EventStatisticsScreen.cardGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: EventStatisticsScreen.gold,
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

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
