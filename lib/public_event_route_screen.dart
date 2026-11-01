import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'event_qr_documents.dart';
import 'events_screen.dart';

/// Reads the published collection only; never exposes a submission or writes data.
class PublicEventRouteScreen extends StatelessWidget {
  const PublicEventRouteScreen({super.key, required this.eventId, this.showPoster = false});
  final String eventId;
  final bool showPoster;

  @override
  Widget build(BuildContext context) {
    if (!validPublicEventId(eventId)) return _message('Lien d’événement invalide.');
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('events').doc(eventId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _message('Impossible de charger cet événement. Vérifiez votre connexion ou réessayez plus tard.');
        if (!snapshot.hasData) return Scaffold(backgroundColor: eventQrDark,
          appBar: AppBar(backgroundColor: eventQrDark, foregroundColor: eventQrGold),
          body: const Center(child: CircularProgressIndicator(color: eventQrGold)));
        final doc = snapshot.data!;
        final data = doc.data();
        if (!doc.exists || data == null) return _message('Cet événement n’est plus disponible.');
        final status = data['status']?.toString().trim().toLowerCase() ?? '';
        // Legacy public documents may have no status, as on the existing list.
        if (status.isNotEmpty && status != 'published' && status != 'approved') {
          return _message('Cet événement n’est pas disponible au public.');
        }
        if (showPoster) return EventQrDocumentScreen(
          title: data['title']?.toString() ?? 'Événement',
          payload: publicEventLink(doc.id), isTicket: false,
          details: [for (final key in ['date', 'time', 'location'])
            if ((data[key]?.toString().trim() ?? '').isNotEmpty) data[key].toString()],
        );
        return EventDetailScreen(eventData: {...data, 'id': doc.id});
      },
    );
  }

  Widget _message(String message) => Scaffold(backgroundColor: eventQrDark,
    appBar: AppBar(title: const Text('Événement'), backgroundColor: eventQrDark,
      foregroundColor: eventQrGold),
    body: Center(child: Padding(padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white)))));
}
