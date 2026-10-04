import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'dynamic_submission_screen.dart';
import 'event_attendees_screen.dart';
import 'event_payments_payouts_screen.dart';
import 'event_sales_screen.dart';
import 'event_statistics_screen.dart';
import 'event_ticketing_management_screen.dart';
import 'events_screen.dart';

class EventOrganizerDashboardScreen extends StatelessWidget {
  const EventOrganizerDashboardScreen({super.key});

  static const Color darkGreen = Color(0xFF061E12);
  static const Color cardGreen = Color(0xFF0F5257);
  static const Color gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: darkGreen,
      appBar: AppBar(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mon espace Événement',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Vous devez être connecté.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('eventSubmissions')
                  .where('ownerId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Impossible de charger vos événements.\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: gold),
                  );
                }

                final docs = [...?snapshot.data?.docs];

                docs.sort((a, b) {
                  final aDate = a.data()['createdAt'];
                  final bDate = b.data()['createdAt'];

                  if (aDate is Timestamp && bDate is Timestamp) {
                    return bDate.compareTo(aDate);
                  }

                  return 0;
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucun événement trouvé.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                  children: [
                    const Text(
                      'Mes événements',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Gérez vos événements, ventes, billets et entrées.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...docs.map(
                      (doc) => _EventCard(
                        eventId: doc.id,
                        submissionData: doc.data(),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.eventId,
    required this.submissionData,
  });

  final String eventId;
  final Map<String, dynamic> submissionData;

  static const Color darkGreen = Color(0xFF061E12);
  static const Color cardGreen = Color(0xFF0F5257);
  static const Color gold = Color(0xFFFFD700);

  Map<String, dynamic> get fields {
    final value = submissionData['fields'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  String _text(dynamic value, [String fallback = '']) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value == null) {
      return 0;
    }

    var text = value.toString().trim();
    text = text.replaceAll('€', '').replaceAll(' ', '').replaceAll(',', '.');

    return double.tryParse(text) ?? 0;
  }

  String _money(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toStringAsFixed(0)} €';
    }

    return '${value.toStringAsFixed(2)} €';
  }

  String get title => _text(fields['title'], 'Événement');

  String get location => _text(fields['cityAddress'], 'Lieu non renseigné');

  String get performer => _text(
        fields['performerDj'] ?? fields['performer'],
      );

  String get startTime => _text(fields['startTime']);

  String get eventDate => _text(fields['eventDate']);

  String get imageUrl {
    String image = _text(submissionData['imageUrl']);

    if (image.isEmpty) {
      image = _text(submissionData['image']);
    }

    final eventMediaRaw = submissionData['eventMedia'];
    final eventMedia = eventMediaRaw is Map
        ? Map<String, dynamic>.from(eventMediaRaw)
        : <String, dynamic>{};

    if (image.isEmpty) {
      image = _text(eventMedia['coverUrl']);
    }

    if (image.isEmpty) {
      final photos = eventMedia['photoUrls'];

      if (photos is List && photos.isNotEmpty) {
        image = _text(photos.first);
      }
    }

    final mediaRaw = submissionData['media'];
    final media = mediaRaw is Map
        ? Map<String, dynamic>.from(mediaRaw)
        : <String, dynamic>{};

    if (image.isEmpty) {
      final photos = media['photoUrls'];

      if (photos is List && photos.isNotEmpty) {
        image = _text(photos.first);
      }
    }

    return image;
  }

  DateTime? get eventEndDateTime {
    final dateText = eventDate;
    final startText = startTime;
    final endText = _text(fields['endTime']);

    final dateParts = dateText.split('/');
    final endParts = endText.split(':');

    if (dateParts.length != 3 || endParts.length != 2) {
      return null;
    }

    final day = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final year = int.tryParse(dateParts[2]);
    final endHour = int.tryParse(endParts[0]);
    final endMinute = int.tryParse(endParts[1]);

    if (day == null ||
        month == null ||
        year == null ||
        endHour == null ||
        endMinute == null) {
      return null;
    }

    var end = DateTime(
      year,
      month,
      day,
      endHour,
      endMinute,
    );

    final startParts = startText.split(':');

    if (startParts.length == 2) {
      final startHour = int.tryParse(startParts[0]);
      final startMinute = int.tryParse(startParts[1]);

      if (startHour != null && startMinute != null) {
        final start = DateTime(
          year,
          month,
          day,
          startHour,
          startMinute,
        );

        if (!end.isAfter(start)) {
          end = end.add(const Duration(days: 1));
        }
      }
    }

    return end;
  }

  String get status =>
      _text(submissionData['status'], 'pendingApproval').toLowerCase();

  bool get isPublished => status == 'approved' || status == 'published';

  bool get isCancelled => status == 'cancelled' || status == 'canceled';

  bool get isEnded {
    if (status == 'ended' || status == 'completed') {
      return true;
    }

    if (!isPublished) {
      return false;
    }

    final end = eventEndDateTime;
    return end != null && DateTime.now().isAfter(end);
  }

  bool get canManageLiveEvent => isPublished && !isCancelled && !isEnded;

  bool get canViewEventHistory => isPublished || isEnded || isCancelled;

  bool get canEditEvent =>
      !isEnded && !isCancelled && status != 'rejected' && status != 'refused';

  String get statusLabel {
    if (isEnded && !isCancelled) {
      return 'Terminé';
    }

    switch (status) {
      case 'approved':
      case 'published':
        return 'Publié';
      case 'rejected':
      case 'refused':
        return 'Refusé';
      case 'cancelled':
      case 'canceled':
        return 'Annulé';
      case 'ended':
      case 'completed':
        return 'Terminé';
      default:
        return 'En attente';
    }
  }

  Color get statusColor {
    if (isCancelled || status == 'rejected' || status == 'refused') {
      return Colors.redAccent;
    }

    if (isEnded) {
      return Colors.blueGrey;
    }

    if (isPublished) {
      return const Color(0xFF5FE38A);
    }

    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (performer.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    performer,
                    style: const TextStyle(
                      color: gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                if (eventDate.isNotEmpty || startTime.isNotEmpty)
                  _InfoLine(
                    icon: Icons.calendar_month_outlined,
                    text: [
                      if (eventDate.isNotEmpty) eventDate,
                      if (startTime.isNotEmpty) startTime,
                    ].join(' • '),
                  ),
                const SizedBox(height: 7),
                _InfoLine(
                  icon: Icons.location_on_outlined,
                  text: location,
                ),
                const SizedBox(height: 22),
                _buildActions(context),
                const SizedBox(height: 20),
                _EventLiveStats(
                  eventId: eventId,
                  toDouble: _toDouble,
                  money: _money,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 185,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _heroFallback(),
            )
          else
            _heroFallback(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  darkGreen.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: darkGreen.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      color: darkGreen,
      child: const Center(
        child: Icon(
          Icons.event_available_outlined,
          color: gold,
          size: 58,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 20) / 3;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ActionTile(
              width: itemWidth,
              icon: Icons.edit_outlined,
              label: 'Modifier',
              enabled: canEditEvent,
              onTap: () async {
                if (!canEditEvent) return;

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DynamicSubmissionScreen(
                      type: SubmissionType.event,
                      editDocumentId: eventId,
                    ),
                  ),
                );
              },
            ),
            _ActionTile(
              width: itemWidth,
              icon: Icons.confirmation_number_outlined,
              label: 'Billetterie',
              enabled: canManageLiveEvent,
              onTap: () {
                if (!canManageLiveEvent) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventTicketingManagementScreen(
                      eventId: eventId,
                      eventTitle: title,
                    ),
                  ),
                );
              },
            ),
            _ActionTile(
              width: itemWidth,
              icon: Icons.payments_outlined,
              label: 'Ventes',
              enabled: canViewEventHistory,
              onTap: () {
                if (!canViewEventHistory) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventSalesScreen(
                      eventId: eventId,
                      eventTitle: title,
                    ),
                  ),
                );
              },
            ),
            _ActionTile(
              width: itemWidth,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Paiements',
              enabled: canViewEventHistory,
              onTap: () {
                if (!canViewEventHistory) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventPaymentsPayoutsScreen(
                      eventId: eventId,
                      eventTitle: title,
                    ),
                  ),
                );
              },
            ),
            _ActionTile(
              width: itemWidth,
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scanner QR',
              enabled: canManageLiveEvent,
              highlighted: true,
              onTap: () {
                if (!canManageLiveEvent) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminScannerScreen(
                      eventId: eventId,
                    ),
                  ),
                );
              },
            ),
            _ActionTile(
              width: itemWidth,
              icon: Icons.groups_outlined,
              label: 'Participants',
              enabled: canViewEventHistory,
              onTap: () {
                if (!canViewEventHistory) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventAttendeesScreen(
                      eventId: eventId,
                      eventTitle: title,
                    ),
                  ),
                );
              },
            ),
            _ActionTile(
              width: itemWidth,
              icon: Icons.bar_chart_rounded,
              label: 'Statistiques',
              enabled: canViewEventHistory,
              onTap: () {
                if (!canViewEventHistory) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventStatisticsScreen(
                      eventId: eventId,
                      eventTitle: title,
                    ),
                  ),
                );
              },
            ),
            _ActionTile(
              width: itemWidth,
              icon: Icons.visibility_outlined,
              label: 'Page publique',
              enabled: isPublished,
              onTap: () {
                if (!isPublished) return;
                _openPublicEvent(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _openPublicEvent(BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();

      if (!context.mounted) return;

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La page publique de cet événement '
              'n’est pas encore disponible.',
            ),
          ),
        );
        return;
      }

      final data = snapshot.data()!;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(
            eventData: {
              ...data,
              'id': snapshot.id,
            },
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d’ouvrir l’événement : $error',
          ),
        ),
      );
    }
  }
}

class _EventLiveStats extends StatelessWidget {
  const _EventLiveStats({
    required this.eventId,
    required this.toDouble,
    required this.money,
  });

  final String eventId;
  final double Function(dynamic value) toDouble;
  final String Function(double value) money;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tickets')
          .where('eventId', isEqualTo: eventId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final tickets = snapshot.data?.docs ?? [];

        final purchased = tickets.where((doc) {
          return doc.data()['paymentStatus'] == 'purchased';
        }).toList();

        final participants = purchased.where((doc) {
          return doc.data()['checkedIn'] == true;
        }).length;

        final revenue = purchased.fold<double>(
          0,
          (total, doc) => total + toDouble(doc.data()['price']),
        );

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF061E12).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _StatValue(
                  label: 'VENTES',
                  value: '${purchased.length}',
                ),
              ),
              _divider(),
              Expanded(
                child: _StatValue(
                  label: 'PARTICIPANTS',
                  value: '$participants',
                ),
              ),
              _divider(),
              Expanded(
                child: _StatValue(
                  label: 'REVENUS',
                  value: money(revenue),
                  goldValue: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white12,
    );
  }
}

class _StatValue extends StatelessWidget {
  const _StatValue({
    required this.label,
    required this.value,
    this.goldValue = false,
  });

  final String label;
  final String value;
  final bool goldValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: goldValue ? const Color(0xFFFFD700) : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFFFD700),
          size: 18,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.enabled,
    this.highlighted = false,
  });

  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final background =
        highlighted ? const Color(0xFFFFD700) : const Color(0xFF061E12);

    final foreground =
        highlighted ? const Color(0xFF061E12) : const Color(0xFFFFD700);

    return SizedBox(
      width: width,
      height: 84,
      child: Opacity(
        opacity: enabled ? 1 : 0.38,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(17),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: highlighted
                      ? const Color(0xFFFFD700)
                      : Colors.white.withValues(alpha: 0.07),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: foreground,
                    size: highlighted ? 27 : 24,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          highlighted ? const Color(0xFF061E12) : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
