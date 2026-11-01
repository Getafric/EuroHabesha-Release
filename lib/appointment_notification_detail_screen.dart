import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// One appointment, read live using the existing Firestore permissions.
class AppointmentNotificationDetailScreen extends StatefulWidget {
  final String businessId;
  final String sourceCollection;
  final String appointmentId;

  const AppointmentNotificationDetailScreen({
    super.key,
    required this.businessId,
    required this.sourceCollection,
    required this.appointmentId,
  });

  @override
  State<AppointmentNotificationDetailScreen> createState() =>
      _AppointmentNotificationDetailScreenState();
}

class _AppointmentNotificationDetailScreenState
    extends State<AppointmentNotificationDetailScreen> {
  static const dark = Color(0xFF061E12);
  static const gold = Color(0xFFFFD700);
  bool _busy = false;
  late final Future<bool> _ownerFuture;
  DocumentReference<Map<String, dynamic>> get _business =>
      FirebaseFirestore.instance.collection(widget.sourceCollection)
          .doc(widget.businessId);
  DocumentReference<Map<String, dynamic>> get _appointment =>
      _business.collection('appointments').doc(widget.appointmentId);

  @override
  void initState() {
    super.initState();
    _ownerFuture = _isOwner();
  }

  Future<bool> _isOwner() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final data = (await _business.get()).data();
    return data != null && (data['ownerId'] == uid || data['submittedBy'] == uid);
  }

  String _date(dynamic value) {
    if (value is! Timestamp) return 'Date non renseignée';
    final d = value.toDate().toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} à ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _review(String status) async {
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(_appointment);
        if (!snap.exists || snap.data()?['status'] != 'pending') {
          throw StateError('Ce rendez-vous a déjà été traité.');
        }
        tx.update(_appointment, {
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Modification impossible : $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: dark,
    appBar: AppBar(backgroundColor: dark, foregroundColor: gold,
      title: const Text('Détails du rendez-vous')),
    body: SafeArea(child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _appointment.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text(
          'Impossible de lire ce rendez-vous. Vérifiez votre connexion et vos autorisations.',
          style: TextStyle(color: Colors.white)));
        if (!snapshot.hasData) return const Center(
          child: CircularProgressIndicator(color: gold));
        final d = snapshot.data!.data();
        if (d == null) return const Center(child: Text('Rendez-vous introuvable.',
          style: TextStyle(color: Colors.white)));
        final status = (d['status'] ?? 'pending').toString();
        const labels = {'pending': 'En attente de confirmation',
          'confirmed': 'Confirmé', 'rejected': 'Refusé',
          'cancelled': 'Annulé', 'completed': 'Terminé'};
        return ListView(padding: const EdgeInsets.all(20), children: [
          Text('${d['serviceName'] ?? 'Prestation'}', style: const TextStyle(
            color: gold, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Début : ${_date(d['startAt'])}', style: const TextStyle(color: Colors.white)),
          if (d['endAt'] is Timestamp) Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('Fin : ${_date(d['endAt'])}', style: const TextStyle(color: Colors.white))),
          const SizedBox(height: 12),
          Text('Statut : ${labels[status] ?? status}', style: const TextStyle(color: gold)),
          if (d['price'] is num) Padding(padding: const EdgeInsets.only(top: 12),
            child: Text('Prix : ${d['price']} €', style: const TextStyle(color: Colors.white))),
          FutureBuilder<bool>(future: _ownerFuture, builder: (context, owner) {
            if (owner.data != true) return const SizedBox.shrink();
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Divider(height: 32, color: Colors.white24),
              Text('Client : ${d['clientName'] ?? 'Client'}', style: const TextStyle(color: Colors.white)),
              if ((d['clientEmail'] ?? '').toString().isNotEmpty)
                SelectableText('E-mail : ${d['clientEmail']}', style: const TextStyle(color: Colors.white)),
              if ((d['clientPhone'] ?? '').toString().isNotEmpty)
                SelectableText('Téléphone : ${d['clientPhone']}', style: const TextStyle(color: Colors.white)),
              if (status == 'pending') ...[
                const SizedBox(height: 20),
                FilledButton(style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: dark),
                  onPressed: _busy ? null : () => _review('confirmed'), child: const Text('Accepter')),
                TextButton(style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: _busy ? null : () => _review('rejected'), child: const Text('Refuser')),
              ],
            ]);
          }),
        ]);
      },
    )),
  );
}
