import 'l10n/app_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'appointment_booking_screen.dart';

/// Public preferences are read on the original professional profile.
/// These switches control the app's UI; server authorization remains separate.
class ProfessionalCapabilities {
  final bool appointments;
  final bool orders;
  final bool contact;
  final bool chat;
  const ProfessionalCapabilities({
    required this.appointments,
    required this.orders,
    required this.contact,
    required this.chat,
  });

  factory ProfessionalCapabilities.fromData(
    Map<String, dynamic> data, {
    bool legacyOrders = false,
    bool legacyChat = false,
  }) {
    bool option(String key, bool fallback) =>
        data[key] is bool ? data[key] as bool : fallback;
    final model = data['contactModel'];
    final oldChat = model is Map && model['inAppMessagingEnabled'] is bool
        ? model['inAppMessagingEnabled'] as bool
        : legacyChat;
    return ProfessionalCapabilities(
      appointments: option(
        'appointmentsEnabled',
        data['appointmentWorkingHours'] is Map,
      ),
      orders: option('ordersEnabled', legacyOrders),
      contact: option('contactEnabled', true),
      chat: option('chatEnabled', oldChat),
    );
  }

  static const unavailable = ProfessionalCapabilities(
    appointments: false,
    orders: false,
    contact: false,
    chat: false,
  );
}

class ProfessionalSource {
  final String collection;
  final String id;
  const ProfessionalSource(this.collection, this.id);
}

ProfessionalSource? professionalSource(
  Map<String, dynamic> data, {
  DocumentReference<Map<String, dynamic>>? reference,
}) {
  bool valid(String collection, String id) =>
      const ['businessSubmissions', 'jobSubmissions'].contains(collection) &&
      id.isNotEmpty &&
      !id.contains('/');
  for (final keys in const [
    ['bookingSourceCollection', 'bookingBusinessId'],
    ['sourceCollection', 'sourceId'],
    ['roomLayoutSourceCollection', 'roomLayoutBusinessId'],
    ['sourceCollection', 'sourceBusinessId'],
    ['sourceCollection', 'sourceSubmissionId'],
  ]) {
    final collection = data[keys[0]]?.toString().trim() ?? '';
    final id = data[keys[1]]?.toString().trim() ?? '';
    if (valid(collection, id)) return ProfessionalSource(collection, id);
  }
  if (reference != null && valid(reference.parent.id, reference.id)) {
    return ProfessionalSource(reference.parent.id, reference.id);
  }
  return null;
}

class ProfessionalCapabilitiesView extends StatelessWidget {
  final ProfessionalSource? source;
  final Map<String, dynamic> fallback;
  final bool legacyOrders;
  final bool legacyChat;
  final Widget Function(BuildContext, ProfessionalCapabilities) builder;
  const ProfessionalCapabilitiesView({
    super.key,
    required this.source,
    required this.builder,
    this.fallback = const {},
    this.legacyOrders = false,
    this.legacyChat = false,
  });

  @override
  Widget build(BuildContext context) {
    final link = source;
    if (link == null) {
      final options = ProfessionalCapabilities.fromData(
        fallback,
        legacyOrders: legacyOrders,
        legacyChat: legacyChat,
      );
      // An unlinked profile may display its contact/catalogue, but cannot book.
      return builder(
        context,
        ProfessionalCapabilities(
          appointments: false,
          orders: false,
          contact: options.contact,
          chat: false,
        ),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(link.collection)
          .doc(link.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return builder(context, ProfessionalCapabilities.unavailable);
        }
        return builder(
          context,
          ProfessionalCapabilities.fromData(
            snapshot.data!.data()!,
            legacyOrders: legacyOrders,
            legacyChat: legacyChat,
          ),
        );
      },
    );
  }
}

class PublicAppointmentAction extends StatelessWidget {
  final ProfessionalSource? source;
  final String businessName;
  final bool enabled;
  const PublicAppointmentAction({
    super.key,
    required this.source,
    required this.businessName,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final link = source;
    if (!enabled || link == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(link.collection)
          .doc(link.id)
          .collection('appointmentServices')
          .where('enabled', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF061E12),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.event_available_outlined),
              label: const AppText('Prendre rendez-vous'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AppointmentBookingScreen(
                    sourceCollection: link.collection,
                    businessId: link.id,
                    businessName: businessName,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
