import 'l10n/app_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'customer_table_reservation_screen.dart';

/// These are the source collections already supported by the table rules.
bool supportsTableReservations(String source) =>
    const ['businessSubmissions', 'jobSubmissions'].contains(source);

/// Used only for profiles which have not explicitly saved an option yet.
bool initialTableReservationOption(
  Map<String, dynamic> data, {
  required String category,
  bool hasLayout = false,
}) {
  final explicit = data['tableReservationsEnabled'];
  if (explicit is bool) return explicit;
  final normalized = category.toLowerCase();
  return hasLayout ||
      ['restaurant', 'café', 'cafe', 'event venue'].any(normalized.contains);
}

/// The client reads the same original profile as the professional dashboard.
/// It does not copy or create a room layout on the public business document.
class PublicTableReservationAction extends StatelessWidget {
  final String sourceCollection;
  final String businessId;
  final String businessName;
  const PublicTableReservationAction({
    super.key,
    required this.sourceCollection,
    required this.businessId,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    if (!supportsTableReservations(sourceCollection) || businessId.isEmpty) {
      return const SizedBox.shrink();
    }
    const gold = Color(0xFFFFD700);
    const dark = Color(0xFF061E12);
    final source = FirebaseFirestore.instance
        .collection(sourceCollection)
        .doc(businessId);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: source.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: AppText(
              'Réservation de tables momentanément indisponible.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.data()!;
        final explicit = data['tableReservationsEnabled'];
        if (explicit == false) return const SizedBox.shrink();
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: source.collection('roomLayouts').doc('main').snapshots(),
          builder: (context, layout) {
            if (layout.hasError) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: AppText(
                  'Le plan de salle est momentanément indisponible.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            if (!layout.hasData) return const SizedBox.shrink();
            final layoutData = layout.data!.data();
            // A saved layout opt-out overrides the profile's legacy fallback.
            if (layoutData?['reservationsEnabled'] == false) {
              return const SizedBox.shrink();
            }
            final rooms = layoutData?['rooms'];
            final hasLayout =
                rooms is List &&
                rooms.any(
                  (room) =>
                      room is Map &&
                      room['tables'] is List &&
                      (room['tables'] as List).isNotEmpty,
                );
            if (!hasLayout) return const SizedBox.shrink();
            // Existing layouts remain accessible until a choice is saved.
            if (explicit != true && !hasLayout) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: dark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.table_restaurant_outlined),
                  label: const AppText('Réserver une table'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ClientTableReservationScreen(
                        businessId: businessId,
                        sourceCollection: sourceCollection,
                        businessName: businessName,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
