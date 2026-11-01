import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'table_reservation_plan_screen.dart';

class TableReservationNotificationDetailScreen extends StatelessWidget {
  final String businessId;
  final String sourceCollection;
  final String reservationId;
  const TableReservationNotificationDetailScreen({super.key,
    required this.businessId, required this.sourceCollection,
    required this.reservationId});

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF061E12);
    const gold = Color(0xFFFFD700);
    final ref = FirebaseFirestore.instance.collection(sourceCollection)
        .doc(businessId).collection('tableReservations').doc(reservationId);
    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(title: const Text('Ma réservation'),
          backgroundColor: dark, foregroundColor: gold),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text(
              'Impossible de consulter cette réservation.',
              style: TextStyle(color: Colors.white)));
          if (!snapshot.hasData) return const Center(
              child: CircularProgressIndicator(color: gold));
          final data = snapshot.data!.data();
          if (data == null) return const Center(child: Text(
              'Réservation introuvable.', style: TextStyle(color: Colors.white)));
          if (FirebaseAuth.instance.currentUser == null ||
              (data['clientId'] != FirebaseAuth.instance.currentUser!.uid &&
              data['userId'] != FirebaseAuth.instance.currentUser!.uid)) {
            return const Center(child: Text('Accès réservé au client concerné.',
                style: TextStyle(color: Colors.white)));
          }
          final when = data['dateTime'];
          final date = when is Timestamp ? when.toDate().toLocal() : null;
          final dateText = date == null ? 'Non renseignée' :
              '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/${date.year} '
              '${date.hour.toString().padLeft(2, '0')}:'
              '${date.minute.toString().padLeft(2, '0')}';
          final status = (data['status'] ?? 'pending').toString();
          final label = {'pending': 'En attente', 'accepted': 'Acceptée',
            'rejected': 'Refusée', 'cancelled': 'Annulée'}[status] ?? status;
          return ListView(padding: const EdgeInsets.all(20), children: [
            Text('Statut : $label', style: const TextStyle(
                color: gold, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            for (final item in <String>[
              'Date et heure : $dateText',
              'Table : ${data['tableLabel'] ?? data['tableId'] ?? '-'}',
              'Personnes : ${data['guests'] ?? '-'}',
              if ((data['roomName'] ?? '').toString().isNotEmpty)
                'Salle : ${data['roomName']}',
            ]) Padding(padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(item, style: const TextStyle(
                  color: Colors.white, fontSize: 17))),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.map_outlined),
              label: const Text('Voir ma table sur le plan'),
              style: OutlinedButton.styleFrom(foregroundColor: gold),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => TableReservationPlanScreen(
                  businessId: businessId, sourceCollection: sourceCollection,
                  reservationId: reservationId,
                  initialRoomId: data['roomId']?.toString(),
                  initialTableId: data['tableId']?.toString(), initialDate: date,
                ))),
            ),
          ]);
        },
      ),
    );
  }
}
