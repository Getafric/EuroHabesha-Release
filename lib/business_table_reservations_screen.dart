import 'l10n/app_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'table_reservation_plan_screen.dart';

class BusinessTableReservationsScreen extends StatelessWidget {
  final String businessId;
  final String sourceCollection;

  const BusinessTableReservationsScreen({
    super.key,
    required this.businessId,
    required this.sourceCollection,
  });

  static const Color _gold = Color(0xFFFFD700);
  static const Color _dark = Color(0xFF061E12);
  static const Color _card = Color(0xFF004D40);

  String _firstNonEmpty(Iterable<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return fallback;
  }

  String _dateLabel(dynamic value) {
    if (value is! Timestamp) return 'Date inconnue';
    final date = value.toDate();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} à '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>> _loadClient(String clientId) async {
    if (clientId.isEmpty) return <String, dynamic>{};
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .get();
      return snapshot.data() ?? <String, dynamic>{};
    } catch (_) {
      // A reservation remains accessible even if profile access is denied.
      return <String, dynamic>{};
    }
  }

  Future<void> _changeStatus(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> reference,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final current = await transaction.get(reference);
        if (!current.exists) throw StateError('Réservation introuvable.');
        final currentStatus = (current.data()?['status'] ?? 'pending')
            .toString();
        if (currentStatus != 'pending') {
          throw StateError('Cette réservation a déjà été traitée.');
        }
        transaction.update(reference, {
          'status': status,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'Réservation acceptée.'
                : 'Réservation refusée.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText('Impossible de modifier la réservation : $error'),
        ),
      );
    }
  }

  Widget _detail(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _gold, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reservationCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final clientId = _firstNonEmpty([data['clientId'], data['userId']]);
    final status = _firstNonEmpty([data['status']], fallback: 'pending');
    final table = _firstNonEmpty([
      data['tableLabel'],
      data['tableName'],
      data['tableNumber'],
      data['tableId'],
    ], fallback: 'Non précisée');
    final guests = _firstNonEmpty([
      data['guests'],
      data['guestCount'],
      data['partySize'],
    ], fallback: 'Non précisé');
    final zone = _firstNonEmpty([
      data['roomName'],
      data['zoneName'],
      data['zoneLabel'],
      data['zone'],
    ]);
    final notes = _firstNonEmpty([data['notes'], data['specialRequests']]);

    return Card(
      color: _card,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openPlan(context, data, doc.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Table $table · $guests personne(s)',
                style: const TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              _detail(Icons.event, _dateLabel(data['dateTime'])),
              _detail(
                Icons.info_outline,
                'Statut : ${tableReservationStatusLabel(status)}',
              ),
              if (zone.isNotEmpty)
                _detail(Icons.place_outlined, 'Zone : $zone'),
              FutureBuilder<Map<String, dynamic>>(
                future:
                    _firstNonEmpty([
                          data['clientName'],
                          data['customerName'],
                          data['userName'],
                        ]).isNotEmpty &&
                        _firstNonEmpty([
                          data['clientPhone'],
                          data['customerPhone'],
                          data['clientEmail'],
                          data['customerEmail'],
                        ]).isNotEmpty
                    ? Future.value(<String, dynamic>{})
                    : _loadClient(clientId),
                builder: (context, profileSnapshot) {
                  final profile = profileSnapshot.data ?? <String, dynamic>{};
                  final name = _firstNonEmpty([
                    data['clientName'],
                    data['customerName'],
                    data['userName'],
                    profile['displayName'],
                    profile['fullName'],
                    profile['name'],
                    profile['firstName'] != null || profile['lastName'] != null
                        ? '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'
                        : null,
                  ], fallback: 'Nom non renseigné');
                  final phone = _firstNonEmpty([
                    data['clientPhone'],
                    data['customerPhone'],
                    profile['phoneNumber'],
                    profile['phone'],
                  ]);
                  final email = _firstNonEmpty([
                    data['clientEmail'],
                    data['customerEmail'],
                    profile['email'],
                  ]);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white24, height: 22),
                      _detail(Icons.person_outline, 'Client : $name'),
                      if (phone.isNotEmpty)
                        _detail(Icons.phone_outlined, phone),
                      if (email.isNotEmpty)
                        _detail(Icons.email_outlined, email),
                      if (phone.isEmpty && email.isEmpty)
                        _detail(
                          Icons.contact_page_outlined,
                          'Coordonnées non disponibles',
                        ),
                    ],
                  );
                },
              ),
              if (notes.isNotEmpty) _detail(Icons.notes, 'Remarque : $notes'),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _openPlan(context, data, doc.id),
                icon: const Icon(Icons.map_outlined),
                label: const AppText('Voir la table sur le plan'),
                style: OutlinedButton.styleFrom(foregroundColor: _gold),
              ),
              if (status == 'pending') ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _changeStatus(context, doc.reference, 'accepted'),
                      icon: const Icon(Icons.check, color: _gold),
                      label: const AppText(
                        'Accepter',
                        style: TextStyle(color: _gold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _changeStatus(context, doc.reference, 'rejected'),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const AppText(
                        'Refuser',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openPlan(BuildContext context, Map<String, dynamic> data, String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TableReservationPlanScreen(
          businessId: businessId,
          sourceCollection: sourceCollection,
          professionalView: true,
          reservationId: id,
          initialRoomId: data['roomId']?.toString(),
          initialTableId: data['tableId']?.toString(),
          initialDate: data['dateTime'] is Timestamp
              ? (data['dateTime'] as Timestamp).toDate()
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collection = FirebaseFirestore.instance
        .collection(sourceCollection)
        .doc(businessId)
        .collection('tableReservations');
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        title: const AppText('Réservations de tables'),
        backgroundColor: _dark,
        foregroundColor: _gold,
        actions: [
          IconButton(
            tooltip: 'Plan des réservations',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TableReservationPlanScreen(
                  businessId: businessId,
                  sourceCollection: sourceCollection,
                  professionalView: true,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: collection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: AppText(
                'Erreur : ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: _gold));
          }
          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final ax = a.data()['dateTime'];
              final x = ax is Timestamp ? ax.millisecondsSinceEpoch : 0;
              final by = b.data()['dateTime'];
              final y = by is Timestamp ? by.millisecondsSinceEpoch : 0;
              return x.compareTo(y);
            });
          if (docs.isEmpty) {
            return const Center(
              child: AppText(
                'Aucune réservation reçue.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) =>
                _reservationCard(context, docs[index]),
          );
        },
      ),
    );
  }
}
