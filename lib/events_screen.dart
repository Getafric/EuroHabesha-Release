import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'app_session.dart';
import 'subscription_service.dart';
import 'dynamic_submission_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF061E12);
    const Color primaryGold = Color(0xFFFFD700);
    const Color cardGreen = Color(0xFF004D40);

    // Ã¢â€€Ã¢â€€ 3 Ã¡â€¹Â¨Ã¡â€°Â°Ã¡Ë†Ë†Ã¡â€¹Â«Ã¡â€¹Â¨ Ã¡Å Â Ã¡â€¹Â­Ã¡Å ÂÃ¡â€°Âµ Ã¡â€¹Â¨Ã¡Å Â¢Ã¡â€°Â¨Ã¡Å â€¢Ã¡â€°Âµ Ã¡Ë†ÂÃ¡Ë†Â³Ã¡Ë†Å’Ã¡â€¹Å½Ã¡â€°Â½ Ã¢â€€Ã¢â€€
    final List<Map<String, dynamic>> eventsList = [
      {
        'title': 'Ethiopian New Year Mega Concert',
        'type': 'Concert & Party',
        'audience': 'Adults Only (18+)',
        'date': 'Sept 11, 2026',
        'time': '09:00 PM - 04:00 AM',
        'endTime': '04:00 AM',
        'location': 'Le ZÃƒÂ©nith Paris - La Villette, Paris',
        'price': 'Ã¢â€šÂ¬45.00',
        'nonRefundable': true,
        'description':
            'Join the biggest Ethiopian New Year celebration in Europe! Featuring top artists from home, live band, cultural food, and drinks. Get your tickets early before they sell out.',
        'performerDj': 'Rophnan + Live DJ',
        'amenities': ['VIP', 'Food', 'Shisha'],
        'artists': [
          'Teddy Afro (Special Guest)',
          'Rophnan',
          'Live Traditional Band'
        ],
        'image':
            'https://images.unsplash.com/photo-1540039155732-d6749b132338?auto=format&fit=crop&w=800&q=80',
      },
      {
        'title': 'Habesha Family & Kids Festival',
        'type': 'Family Entertainment',
        'audience': 'All Ages / Kids Friendly',
        'date': 'July 25, 2026',
        'time': '10:00 AM - 06:00 PM',
        'endTime': '06:00 PM',
        'location': 'Parc de la TÃƒÂªte d\'Or, Lyon',
        'price': 'Ã¢â€šÂ¬15.00',
        'description':
            'A beautiful day out for the whole family! Face painting for kids, bouncy castles, traditional games (Gebeta, Kuks), fashion show for children, and authentic Habesha BBQ (Tibs).',
        'performerDj': 'DJ Sammy',
        'amenities': ['Kids', 'Food', 'Games'],
        'artists': ['Kids Animators', 'DJ Sammy', 'Cultural Dance Troup'],
        'image':
            'https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&w=800&q=80',
      },
      {
        'title': 'Eritrean Independence Day Gala',
        'type': 'Cultural Gala & Dinner',
        'audience': 'General & VIP',
        'date': 'May 24, 2026',
        'time': '07:00 PM - 01:00 AM',
        'endTime': '01:00 AM',
        'location': 'Palais des CongrÃƒÂ¨s de Rome, Italy',
        'price': 'Ã¢â€šÂ¬60.00',
        'description':
            'A prestigious evening celebrating culture and heritage. The event includes a full course traditional dinner, networking sessions, cultural attire showcase, and live Guaila music.',
        'performerDj': 'Eden Kesete',
        'amenities': ['Dinner', 'VIP', 'Networking'],
        'artists': ['Eden Kesete', 'Korcho', 'Guest Speakers'],
        'image':
            'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=800&q=80',
      },
    ];

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('Events & Tickets',
            style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: primaryGold),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: primaryGold),
            tooltip: 'Submit Event',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DynamicSubmissionScreen(
                        type: SubmissionType.event)),
              );
            },
          ),
          if (_canScanTickets())
            IconButton(
              icon:
                  const Icon(Icons.qr_code_scanner, color: Colors.greenAccent),
              tooltip: 'Ticket Scanner',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminScannerScreen(),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.confirmation_number_outlined,
                color: Color(0xFFFFD700)),
            tooltip: 'My Tickets',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyTicketsScreen())),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          final List<Map<String, dynamic>> combined = [];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data();
              final status = data['status']?.toString() ?? 'published';
              if (status == 'published' || status == 'approved') {
                final fields = Map<String, dynamic>.from(data['fields'] ?? {});
                final title = fields['title']?.toString() ??
                    data['title']?.toString() ??
                    'Event';
                final type = fields['eventType']?.toString() ??
                    data['type']?.toString() ??
                    'Concert & Party';
                final audience = fields['audience']?.toString() ??
                    data['audience']?.toString() ??
                    'General';
                final date = fields['eventDate']?.toString() ??
                    data['date']?.toString() ??
                    'Upcoming';
                final time = fields['eventTime']?.toString() ??
                    data['time']?.toString() ??
                    '';
                final endTime = fields['endTime']?.toString() ??
                    data['endTime']?.toString() ??
                    '';
                final location = fields['cityAddress']?.toString() ??
                    data['location']?.toString() ??
                    'Europe';
                final rawTicketTypes = data['ticketTypes'];

                final activeTicketPrices = <double>[];

                if (rawTicketTypes is List) {
                  for (final rawTicket in rawTicketTypes) {
                    if (rawTicket is! Map) {
                      continue;
                    }

                    final ticket = Map<String, dynamic>.from(rawTicket);

                    if (ticket['active'] == false) {
                      continue;
                    }

                    final rawPrice = ticket['price'];

                    double? ticketPrice;

                    if (rawPrice is num) {
                      ticketPrice = rawPrice.toDouble();
                    } else {
                      ticketPrice = double.tryParse(
                        rawPrice
                            .toString()
                            .replaceAll(',', '.')
                            .replaceAll(RegExp(r'[^0-9.\-]'), ''),
                      );
                    }

                    if (ticketPrice != null && ticketPrice >= 0) {
                      activeTicketPrices.add(ticketPrice);
                    }
                  }
                }

                String price;

                if (activeTicketPrices.isNotEmpty) {
                  activeTicketPrices.sort();

                  final lowestPrice = activeTicketPrices.first;

                  price = lowestPrice == 0
                      ? 'Free'
                      : 'Ã¢â€šÂ¬${lowestPrice.toStringAsFixed(2)}';
                } else {
                  final legacyPrice =
                      fields['ticketPrice']?.toString().trim() ??
                          data['price']?.toString().trim() ??
                          '';

                  price = legacyPrice.isEmpty
                      ? 'Unavailable'
                      : legacyPrice.startsWith('Ã¢â€šÂ¬')
                          ? legacyPrice
                          : 'Ã¢â€šÂ¬$legacyPrice';
                }
                final description = fields['description']?.toString() ??
                    data['description']?.toString() ??
                    '';
                final performer = fields['performer']?.toString() ??
                    data['performerDj']?.toString() ??
                    'Live Show';
                final eventMediaRaw = data['eventMedia'];
                final eventMedia = eventMediaRaw is Map
                    ? Map<String, dynamic>.from(eventMediaRaw)
                    : <String, dynamic>{};

                final mediaRaw = data['media'];
                final media = mediaRaw is Map
                    ? Map<String, dynamic>.from(mediaRaw)
                    : <String, dynamic>{};

                String image = data['imageUrl']?.toString().trim() ?? '';

                if (image.isEmpty) {
                  image = data['image']?.toString().trim() ?? '';
                }

                if (image.isEmpty) {
                  image = eventMedia['coverUrl']?.toString().trim() ?? '';
                }

                if (image.isEmpty) {
                  final photoUrls = eventMedia['photoUrls'];

                  if (photoUrls is List && photoUrls.isNotEmpty) {
                    image = photoUrls.first.toString().trim();
                  }
                }

                if (image.isEmpty) {
                  final photoUrls = media['photoUrls'];

                  if (photoUrls is List && photoUrls.isNotEmpty) {
                    image = photoUrls.first.toString().trim();
                  }
                }

                combined.add({
                  'id': doc.id,
                  'title': title,
                  'type': type,
                  'audience': audience,
                  'date': date,
                  'time': time,
                  'endTime': endTime,
                  'location': location,
                  'price': price,
                  'nonRefundable': true,
                  'description': description,
                  'performerDj': performer,
                  'amenities': ['VIP', 'Food'],
                  'artists': [performer],
                  'image': image,
                });
              }
            }
          }

          for (final starter in eventsList) {
            if (!combined.any((e) => e['title'] == starter['title'])) {
              combined.add(starter);
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: combined.length,
            itemBuilder: (context, index) {
              final event = combined[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            EventDetailScreen(eventData: event)),
                  );
                },
                child: Card(
                  color: cardGreen,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15)),
                            child: Image.network(
                              event['image'],
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                height: 180,
                                color: Colors.white10,
                                child: const Icon(Icons.event,
                                    color: Colors.white38, size: 48),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 15,
                            right: 15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                  color: primaryGold,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                event['date'],
                                style: const TextStyle(
                                    color: primaryDarkGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event['title'],
                                style: const TextStyle(
                                    color: primaryGold,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.white70, size: 16),
                                const SizedBox(width: 5),
                                Expanded(
                                    child: Text(event['location'],
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (event['performerDj'] != null &&
                                    (event['performerDj'] as String).isNotEmpty)
                                  _buildEventBadge(Icons.mic,
                                      event['performerDj'], primaryGold),
                                if (event['endTime'] != null &&
                                    (event['endTime'] as String).isNotEmpty)
                                  _buildEventBadge(Icons.schedule,
                                      'Ends ${event['endTime']}', primaryGold),
                                if (event['audience'] != null &&
                                    (event['audience'] as String).isNotEmpty)
                                  _buildEventBadge(Icons.no_adult_content,
                                      event['audience'], primaryGold),
                                if (event['amenities'] is List)
                                  for (final amenity
                                      in (event['amenities'] as List))
                                    _buildEventBadge(Icons.local_activity,
                                        amenity.toString(), primaryGold),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tickets from: ${event['price']?.toString().trim().isNotEmpty == true ? event['price'].toString().replaceAll(RegExp(r'^[^0-9]*'), '\u20AC') : 'Free'}',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                      color: primaryGold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(5)),
                                  child: const Text('Get Ticket',
                                      style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 12)),
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color:
                                          primaryGold.withValues(alpha: 0.55)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(
                                    Icons.notifications_active_outlined,
                                    color: primaryGold,
                                    size: 18),
                                label: const Text('Follow Event Updates',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  final followed =
                                      await SubscriptionService.follow(
                                    type: 'event',
                                    targetId: event['title']
                                        .toString()
                                        .toLowerCase()
                                        .replaceAll(' ', '_'),
                                    targetName: event['title'],
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(followed
                                            ? 'You will receive updates for this event.'
                                            : 'Sign in and verify your email to follow event updates.')),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static bool _canScanTickets() {
    final roles = AppSession.roles.map((role) => role.toLowerCase()).toSet();
    return AppSession.isSuperAdmin ||
        roles.contains('eventadmin') ||
        roles.contains('event_admin') ||
        roles.contains('organizer');
  }

  Widget _buildEventBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// Ã¢â€€Ã¢â€€ Ã°Å¸â€™Â¡ Ã¡â€¹Â¨Ã¡Å Â¢Ã¡â€°Â¨Ã¡Å â€¢Ã¡â€°Â± Ã¡Ë†â„¢Ã¡Ë†â€° Ã¡Ë†â€ºÃ¡â€°Â¥Ã¡Ë†Â«Ã¡Ë†ÂªÃ¡â€¹Â« Ã¡Å’Ë†Ã¡Å’Â½ Ã¢â€€Ã¢â€€
class EventDetailScreen extends StatelessWidget {
  final Map<String, dynamic> eventData;

  const EventDetailScreen({super.key, required this.eventData});

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF061E12);
    const Color primaryGold = Color(0xFFFFD700);
    const Color cardGreen = Color(0xFF004D40);
    final eventDetails = eventData['eventDetails'] is Map
        ? Map<String, dynamic>.from(eventData['eventDetails'] as Map)
        : const <String, dynamic>{};
    final nonRefundable = eventData['nonRefundable'] == true ||
        eventDetails['nonRefundable'] == true;
    final nonTransferable = eventData['nonTransferable'] == true ||
        eventDetails['nonTransferable'] == true;

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('Event Details',
            style: TextStyle(color: Color(0xFFFFD700))),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              eventData['image']?.toString() ?? '',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 220,
                  width: double.infinity,
                  color: const Color(0xFF0F5257),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_rounded,
                        color: Color(0xFFFFB800),
                        size: 58,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Event image unavailable',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventData['title']?.toString().trim().isNotEmpty == true
                        ? eventData['title'].toString()
                        : 'Untitled Event',
                    style: const TextStyle(
                      color: primaryGold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildInfoRow(
                      Icons.calendar_today,
                      'Date & Time',
                      '${eventData['date']} \n${eventData['time']}',
                      primaryGold),
                  const SizedBox(height: 15),
                  _buildInfoRow(Icons.schedule, 'End Time',
                      eventData['endTime'] ?? 'Not specified', primaryGold),
                  const SizedBox(height: 15),
                  _buildInfoRow(Icons.mic, 'Performer / DJ',
                      eventData['performerDj'] ?? 'Not specified', primaryGold),
                  const SizedBox(height: 15),
                  _buildInfoRow(
                    Icons.location_on,
                    'Location',
                    eventData['location']?.toString().trim().isNotEmpty == true
                        ? eventData['location'].toString()
                        : 'Not specified',
                    primaryGold,
                  ),
                  const SizedBox(height: 15),
                  _buildInfoRow(
                      Icons.people,
                      'Audience / Type',
                      '${eventData['audience']} \n${eventData['type']}',
                      primaryGold),
                  if (nonRefundable || nonTransferable) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.redAccent)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.block, color: Colors.redAccent),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(
                                  'TICKET POLICY\n${nonRefundable ? 'Tickets cannot be refunded after purchase. ' : ''}${nonTransferable ? 'Tickets cannot be transferred to another person.' : ''}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      height: 1.4))),
                        ],
                      ),
                    ),
                  ],
                  const Divider(color: Colors.white24, height: 40),
                  const Text('About the Event',
                      style: TextStyle(
                          color: primaryGold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    eventData['description']?.toString().trim().isNotEmpty ==
                            true
                        ? eventData['description'].toString()
                        : 'No description available.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Featuring / Lineup',
                      style: TextStyle(
                          color: primaryGold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: (eventData['artists'] is List
                            ? eventData['artists'] as List
                            : const [])
                        .map((artist) {
                      final artistName = artist is Map
                          ? (artist['name']?.toString() ?? 'Artist')
                          : artist?.toString() ?? 'Artist';

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cardGreen,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryGold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          artistName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
      // Ã¢â€€Ã¢â€€ Ã°Å¸â€™Â¡ Ã¡Å Â Ã¡â€¹Â²Ã¡Ë†Â± Ã¡â€¹Ë†Ã¡â€¹Â° Ã¡Ë†â€¹Ã¡â€¹Â­ Ã¡Å Â¨Ã¡ÂÂ Ã¡â€¹Â«Ã¡Ë†Ë† Ã¡â€¹Â¨Ã¡â€°Â²Ã¡Å Â¬Ã¡â€°Âµ Ã¡Ë†ËœÃ¡Å’ÂÃ¡â€¹Â£ Ã¡â€°Â£Ã¡Ë†Â­ (bottomNavigationBar) Ã¢â€€Ã¢â€€
      bottomNavigationBar: Container(
        color: cardGreen,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 15,
                bottom:
                    30), // Ã°Å¸â€™Â¡ bottom: 30 Ã¡Å Â Ã¡â€¹ÂµÃ¡Ë†Â­Ã¡Å’Ë†Ã¡Å â€¢ Ã¡Å Â¨Ã¡ÂÂ Ã¡Å Â Ã¡â€¹ÂµÃ¡Ë†Â­Ã¡Å’Ë†Ã¡Å ÂÃ¡â€¹â€¹Ã¡Ë†Â!
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ticket Price',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      eventData['price']?.toString().trim().isNotEmpty == true
                          ? eventData['price']
                              .toString()
                              .replaceAll(RegExp(r'^[^0-9]*'), '\u20AC')
                          : 'Free',
                      style: const TextStyle(
                        color: primaryGold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGold,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TicketCheckoutScreen(
                                    eventData: {
                                      ...eventData,
                                      'nonRefundable': nonRefundable
                                    })));
                  },
                  child: const Text('Buy Ticket',
                      style: TextStyle(
                          color: Color(0xFF061E12),
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, Color gold) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: gold, size: 22),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

// Ã¢â€€Ã¢â€€ Ã°Å¸â€™Â¡ Ã¡â€¹Â¨Ã¡â€°Â²Ã¡Å Â¬Ã¡â€°Âµ Ã¡Ë†ËœÃ¡Ë†ËœÃ¡â€¹ÂÃ¡Å’Ë†Ã¡â€°Â¢Ã¡â€¹Â« Ã¡Å Â¥Ã¡Å â€œ Ã¡Ë†ËœÃ¡Å Â­Ã¡ÂË†Ã¡â€¹Â« Ã¡Å’Ë†Ã¡Å’Â½ Ã¢â€€Ã¢â€€
class TicketCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> eventData;

  const TicketCheckoutScreen({
    super.key,
    required this.eventData,
  });

  @override
  State<TicketCheckoutScreen> createState() => _TicketCheckoutScreenState();
}

class _TicketCheckoutScreenState extends State<TicketCheckoutScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String selectedPayment = 'Card';

  bool isProcessing = false;
  bool _loadingTicketing = true;

  List<Map<String, dynamic>> _ticketTypes = [];

  String? _selectedTicketTypeId;
  int _quantity = 1;

  DateTime? _salesStart;
  DateTime? _salesEnd;
  bool _ticketingEnabled = true;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    _emailController.text = user?.email ?? '';

    _loadTicketing();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _nonRefundable {
    final eventDetails = widget.eventData['eventDetails'];

    return widget.eventData['nonRefundable'] == true ||
        (eventDetails is Map && eventDetails['nonRefundable'] == true);
  }

  bool get _nonTransferable {
    final eventDetails = widget.eventData['eventDetails'];

    return widget.eventData['nonTransferable'] == true ||
        (eventDetails is Map && eventDetails['nonTransferable'] == true);
  }

  String get _firestoreEventId {
    return widget.eventData['id']?.toString().trim() ?? '';
  }

  String get _eventIdValue {
    if (_firestoreEventId.isNotEmpty) {
      return _firestoreEventId;
    }

    return _eventId(
      widget.eventData['title']?.toString() ?? 'event',
    );
  }

  Map<String, dynamic>? get _selectedTicket {
    if (_selectedTicketTypeId == null) {
      return null;
    }

    for (final ticket in _ticketTypes) {
      if (ticket['id']?.toString() == _selectedTicketTypeId) {
        return ticket;
      }
    }

    return null;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    final cleaned = (value?.toString() ?? '')
        .trim()
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.\-]'), '');

    return double.tryParse(cleaned) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  int _remainingFor(
    Map<String, dynamic> ticket,
  ) {
    final capacity = _toInt(ticket['capacity']);
    final sold = _toInt(ticket['sold']);

    final remaining = capacity - sold;

    return remaining < 0 ? 0 : remaining;
  }

  double get _unitPrice {
    final ticket = _selectedTicket;

    if (ticket == null) {
      return 0;
    }

    return _toDouble(ticket['price']);
  }

  double get _totalPrice {
    return _unitPrice * _quantity;
  }

  String _money(double value) {
    return '${value.toStringAsFixed(2)} €';
  }

  bool get _salesAreOpen {
    if (!_ticketingEnabled) {
      return false;
    }

    final now = DateTime.now();

    if (_salesStart != null && now.isBefore(_salesStart!)) {
      return false;
    }

    if (_salesEnd != null && now.isAfter(_salesEnd!)) {
      return false;
    }

    return true;
  }

  String get _salesStatusText {
    if (!_ticketingEnabled) {
      return 'Ticket sales are currently disabled.';
    }

    final now = DateTime.now();

    if (_salesStart != null && now.isBefore(_salesStart!)) {
      return 'Ticket sales have not started yet.';
    }

    if (_salesEnd != null && now.isAfter(_salesEnd!)) {
      return 'Ticket sales are closed.';
    }

    return '';
  }

  Future<void> _loadTicketing() async {
    try {
      Map<String, dynamic> data = Map<String, dynamic>.from(widget.eventData);

      if (_firestoreEventId.isNotEmpty) {
        final snapshot = await FirebaseFirestore.instance
            .collection('events')
            .doc(_firestoreEventId)
            .get();

        if (snapshot.exists) {
          data = snapshot.data() ?? data;
        }
      }

      final rawTypes = data['ticketTypes'];

      final loaded = <Map<String, dynamic>>[];

      if (rawTypes is List) {
        for (final raw in rawTypes) {
          if (raw is! Map) continue;

          final ticket = Map<String, dynamic>.from(raw);

          if (ticket['active'] == false) {
            continue;
          }

          final capacity = _toInt(ticket['capacity']);

          final sold = _toInt(ticket['sold']);

          if (capacity <= sold) {
            continue;
          }

          loaded.add(ticket);
        }
      }

      // Fallback temporaire pour les anciens ÃƒÂ©vÃƒÂ©nements
      // qui n'ont pas encore de configuration ticketTypes.
      if (loaded.isEmpty && data['ticketTypes'] == null) {
        final legacyPrice = _toDouble(data['price']);

        loaded.add({
          'id': 'general',
          'name': 'Standard',
          'price': legacyPrice,
          'capacity': 999999,
          'sold': 0,
          'active': true,
        });
      }

      if (!mounted) return;

      setState(() {
        _ticketingEnabled = data['ticketingEnabled'] != false;

        _salesStart = _toDateTime(data['ticketSalesStart']);

        _salesEnd = _toDateTime(data['ticketSalesEnd']);

        _ticketTypes = loaded;

        if (_ticketTypes.isNotEmpty) {
          _selectedTicketTypeId = _ticketTypes.first['id']?.toString();
        }

        _quantity = 1;
        _loadingTicketing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingTicketing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ticket options could not be loaded: $error',
          ),
        ),
      );
    }
  }

  void _selectTicket(
    Map<String, dynamic> ticket,
  ) {
    setState(() {
      _selectedTicketTypeId = ticket['id']?.toString();

      _quantity = 1;
    });
  }

  void _increaseQuantity() {
    final ticket = _selectedTicket;

    if (ticket == null) return;

    final remaining = _remainingFor(ticket);

    if (_quantity >= remaining) {
      return;
    }

    // Limite raisonnable par achat.
    if (_quantity >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum 10 tickets per purchase.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _quantity++;
    });
  }

  void _decreaseQuantity() {
    if (_quantity <= 1) return;

    setState(() {
      _quantity--;
    });
  }

  Future<void> _processPayment() async {
    final ticket = _selectedTicket;

    if (ticket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a ticket type.',
          ),
        ),
      );
      return;
    }

    if (!_salesAreOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_salesStatusText),
        ),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your Name and Email.',
          ),
        ),
      );
      return;
    }

    final remaining = _remainingFor(ticket);

    if (_quantity > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'There are not enough tickets remaining.',
          ),
        ),
      );
      return;
    }

    if (_nonRefundable) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Non-refundable ticket',
          ),
          content: const Text(
            'This ticket cannot be refunded after '
            'purchase. Do you want to continue?',
          ),
          actions: [
            // CANCEL
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F5257),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF0F5257),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFB800),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'I Understand',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !user.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please sign in and verify your email '
            'before purchasing a ticket.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    final eventId = _eventIdValue;

    final ticketTypeId = ticket['id']?.toString() ?? 'general';

    final ticketTypeName = ticket['name']?.toString() ?? 'Standard';

    final unitPrice = _toDouble(ticket['price']);

    final totalPrice = unitPrice * _quantity;

    final createdTicketIds = <String>[];

    try {
      if (totalPrice > 0) {
        final paymentIntentId = await _payWithStripe(
          eventId: eventId,
          ticketTypeId: ticketTypeId,
          quantity: _quantity,
        );

        if (!mounted) return;

        final ticketId = await _waitForStripeTicket(
          paymentIntentId: paymentIntentId,
          eventId: eventId,
          buyerId: user.uid,
        );
        if (!mounted) return;

        setState(() {
          isProcessing = false;
        });

        if (ticketId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Payment successful. Your ticket is still being prepared. '
                'Please check My Tickets.',
              ),
            ),
          );

          Navigator.pop(context);
          return;
        }

        await _showPaymentSuccessDialog();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TicketQRCodeScreen(
              eventName: widget.eventData['title']?.toString() ?? 'Event',
              attendeeName: _nameController.text.trim(),
              ticketId: ticketId,
              nonRefundable: _nonRefundable,
              nonTransferable: _nonTransferable,
            ),
          ),
        );

        return;
      }

      // Billet gratuit : crÃƒÂ©ation directe.
      for (var index = 0; index < _quantity; index++) {
        final ticketId = 'EH-${DateTime.now().microsecondsSinceEpoch}'
            '-$index-${user.uid.substring(0, 6)}';

        await FirebaseFirestore.instance
            .collection('tickets')
            .doc(ticketId)
            .set({
          'ticketId': ticketId,
          'eventId': eventId,
          'eventName': widget.eventData['title']?.toString() ?? 'Event',
          'ticketTypeId': ticketTypeId,
          'ticketTypeName': ticketTypeName,
          'buyerId': user.uid,
          'buyerEmail': _emailController.text.trim(),
          'attendeeName': _nameController.text.trim(),
          'unitPrice': 0,
          'price': 0,
          'purchaseQuantity': _quantity,
          'purchaseTotal': 0,
          'paymentStatus': 'purchased',
          'paymentMethod': 'Free',
          'checkedIn': false,
          'nonRefundable': _nonRefundable,
          'nonTransferable': _nonTransferable,
          'eventAdminIds': {
            ...((widget.eventData['eventAdminIds'] as List?)?.map(
                  (id) => id.toString(),
                ) ??
                const <String>[]),
            if (widget.eventData['organizerId'] != null)
              widget.eventData['organizerId'].toString(),
            if (widget.eventData['submittedBy'] != null)
              widget.eventData['submittedBy'].toString(),
            if (widget.eventData['ownerId'] != null)
              widget.eventData['ownerId'].toString(),
          }.toList(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        createdTicketIds.add(ticketId);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ticket could not be issued: $error',
          ),
        ),
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      isProcessing = false;
    });

    if (createdTicketIds.isEmpty) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TicketQRCodeScreen(
          eventName: widget.eventData['title']?.toString() ?? 'Event',
          attendeeName: _nameController.text.trim(),
          ticketId: createdTicketIds.first,
          nonRefundable: _nonRefundable,
          nonTransferable: _nonTransferable,
        ),
      ),
    );
  }

  Future<String?> _waitForStripeTicket({
    required String paymentIntentId,
    required String eventId,
    required String buyerId,
  }) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final snapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where(
            'stripePaymentIntentId',
            isEqualTo: paymentIntentId,
          )
          .get();

      for (final document in snapshot.docs) {
        final data = document.data();

        final ticketEventId = data['eventId']?.toString() ?? '';
        final ticketBuyerId = data['buyerId']?.toString() ?? '';
        final paymentStatus = data['paymentStatus']?.toString() ?? '';

        if (ticketEventId == eventId &&
            ticketBuyerId == buyerId &&
            paymentStatus == 'purchased') {
          return document.id;
        }
      }

      await Future.delayed(
        const Duration(seconds: 1),
      );
    }

    return null;
  }

  Future<void> _showPaymentSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF073D2B),
                  Color(0xFF021A12),
                  Color(0xFF050B08),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFFFD700),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Euro Habesha',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 105,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B5039),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                  child: const Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.confirmation_number_rounded,
                        color: Color(0xFFFFD700),
                        size: 58,
                      ),
                      Icon(
                        Icons.qr_code_2_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Payment Successful!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Thank you for your purchase.\n'
                  'Your ticket is ready.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE7E7E7),
                    fontSize: 17,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(
                      Icons.confirmation_number_rounded,
                    ),
                    label: const Text(
                      'View My Ticket',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _payWithStripe({
    required String eventId,
    required String ticketTypeId,
    required int quantity,
  }) async {
    final functions = FirebaseFunctions.instanceFor(
      region: 'europe-west1',
    );

    final callable = functions.httpsCallable(
      'createTicketPaymentIntent',
    );

    final result = await callable.call({
      'eventId': eventId,
      'ticketTypeId': ticketTypeId,
      'quantity': quantity,
      'attendeeName': _nameController.text.trim(),
      'buyerEmail': _emailController.text.trim(),
      'nonRefundable': _nonRefundable,
      'nonTransferable': _nonTransferable,
    });

    final data = Map<String, dynamic>.from(
      result.data as Map,
    );

    final clientSecret = data['clientSecret']?.toString();
    final paymentIntentId = data['paymentIntentId']?.toString();

    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('Stripe client secret missing.');
    }

    if (paymentIntentId == null || paymentIntentId.isEmpty) {
      throw Exception('Stripe payment intent ID missing.');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Euro Habesha',
        style: ThemeMode.system,
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    return paymentIntentId;
  }

  String _eventId(String title) {
    return title
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '_',
        )
        .replaceAll(
          RegExp(r'^_|_$'),
          '',
        );
  }

  @override
  Widget build(BuildContext context) {
    final selectedTicket = _selectedTicket;

    final remaining =
        selectedTicket == null ? 0 : _remainingFor(selectedTicket);

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFFFFD700),
          ),
        ),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(
          color: Color(0xFFFFD700),
        ),
      ),
      body: _loadingTicketing
          ? Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: cardGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.eventData['image']?.toString() ?? '',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) =>
                                Container(
                              width: 70,
                              height: 70,
                              color: primaryDarkGreen,
                              child: Icon(
                                Icons.event,
                                color: primaryGold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            widget.eventData['title']?.toString() ?? 'Event',
                            style: TextStyle(
                              color: primaryGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'Choose Ticket',
                    style: TextStyle(
                      color: primaryGold,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_salesAreOpen)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.orange,
                        ),
                      ),
                      child: Text(
                        _salesStatusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (!_salesAreOpen) const SizedBox(height: 14),
                  if (_ticketTypes.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No tickets are currently '
                        'available for this event.',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  for (final ticket in _ticketTypes)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: _buildTicketTypeOption(
                        ticket,
                      ),
                    ),
                  if (selectedTicket != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quantity',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$remaining remaining',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _quantity > 1 ? _decreaseQuantity : null,
                            icon: const Icon(
                              Icons.remove_circle,
                            ),
                            color: primaryGold,
                          ),
                          Text(
                            '$_quantity',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          IconButton(
                            onPressed: _quantity < remaining
                                ? _increaseQuantity
                                : null,
                            icon: const Icon(
                              Icons.add_circle,
                            ),
                            color: primaryGold,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryGold.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryGold,
                        ),
                      ),
                      child: Column(
                        children: [
                          _priceRow(
                            'Ticket',
                            selectedTicket['name']?.toString() ?? 'Standard',
                          ),
                          const SizedBox(height: 8),
                          _priceRow(
                            'Unit price',
                            _money(_unitPrice),
                          ),
                          const SizedBox(height: 8),
                          _priceRow(
                            'Quantity',
                            '$_quantity',
                          ),
                          const Divider(
                            color: Colors.white24,
                            height: 22,
                          ),
                          _priceRow(
                            'Total',
                            _money(_totalPrice),
                            strong: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 25),
                  Text(
                    'Attendee Details',
                    style: TextStyle(
                      color: primaryGold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Full Name (For Ticket Verification)',
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                      ),
                      filled: true,
                      fillColor: cardGreen,
                      prefixIcon: Icon(
                        Icons.person,
                        color: primaryGold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Email Address (To receive receipt)',
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                      ),
                      filled: true,
                      fillColor: cardGreen,
                      prefixIcon: Icon(
                        Icons.email,
                        color: primaryGold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (_nonRefundable || _nonTransferable)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.redAccent,
                        ),
                      ),
                      child: Text(
                        'TICKET POLICY: '
                        '${_nonRefundable ? 'This ticket cannot be refunded after purchase. ' : ''}'
                        '${_nonTransferable ? 'This ticket cannot be transferred to another person.' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ),
                  if (_nonRefundable || _nonTransferable)
                    const SizedBox(height: 16),
                  if (_totalPrice > 0) ...[
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        color: primaryGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentOption(
                      'Card',
                      Icons.credit_card,
                      'Credit or Debit Card',
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentOption(
                      'PayPal',
                      Icons.paypal,
                      'Pay with PayPal account',
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentOption(
                      'Apple Pay',
                      Icons.apple,
                      'Pay seamlessly via Apple Pay',
                    ),
                  ] else if (selectedTicket != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardGreen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryGold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.confirmation_number_outlined,
                            color: primaryGold,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'This is a free ticket. No payment method is required.',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 60),
                ],
              ),
            ),
      bottomNavigationBar: _loadingTicketing
          ? null
          : Container(
              color: cardGreen,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    15,
                    20,
                    20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isProcessing ||
                              selectedTicket == null ||
                              !_salesAreOpen
                          ? null
                          : _processPayment,
                      child: isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFF061E12),
                                strokeWidth: 3,
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _totalPrice <= 0
                                    ? 'Get Free Ticket'
                                    : 'Pay ${_money(_totalPrice)} & Get Ticket',
                                style: const TextStyle(
                                  color: Color(0xFF061E12),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTicketTypeOption(
    Map<String, dynamic> ticket,
  ) {
    final id = ticket['id']?.toString() ?? '';
    final name = ticket['name']?.toString() ?? 'Ticket';
    final price = _toDouble(ticket['price']);
    final remaining = _remainingFor(ticket);

    final selected = _selectedTicketTypeId == id;

    return GestureDetector(
      onTap: () => _selectTicket(ticket),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? primaryGold.withValues(alpha: 0.12) : cardGreen,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? primaryGold : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? primaryGold : Colors.white54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$remaining remaining',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _money(price),
              style: TextStyle(
                color: primaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    bool strong = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong ? Colors.white : Colors.white70,
              fontWeight: strong ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: strong ? primaryGold : Colors.white,
            fontWeight: strong ? FontWeight.bold : FontWeight.w600,
            fontSize: strong ? 17 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    String value,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = selectedPayment == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPayment = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryGold.withValues(alpha: 0.1) : cardGreen,
          border: Border.all(
            color: isSelected ? primaryGold : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryGold : Colors.white54,
              size: 28,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: primaryGold,
              ),
          ],
        ),
      ),
    );
  }
}

// Ã¢â€€Ã¢â€€ Ã°Å¸â€™Â¡ Ã¡â€¹Â¨ QR Ã¡Å Â®Ã¡â€¹Âµ Ã¡Ë†â€ºÃ¡Ë†Â³Ã¡â€¹Â« Ã¢â€€Ã¢â€€
class TicketQRCodeScreen extends StatelessWidget {
  final String eventName;
  final String attendeeName;
  final String ticketId;
  final bool nonRefundable;
  final bool nonTransferable;

  const TicketQRCodeScreen(
      {super.key,
      required this.eventName,
      required this.attendeeName,
      required this.ticketId,
      this.nonRefundable = false,
      this.nonTransferable = false});

  @override
  Widget build(BuildContext context) {
    final qrPayload = 'EURO_HABESHA_TICKET|$ticketId|$eventName|$attendeeName';

    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
          title: const Text('My Ticket',
              style: TextStyle(color: Color(0xFFFFD700))),
          backgroundColor: const Color(0xFF061E12)),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('EURO HABESHA TICKET',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              const Divider(color: Colors.black26),
              const SizedBox(height: 10),
              Text(eventName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 210,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, color: Colors.black54, size: 16),
                    const SizedBox(width: 5),
                    Text(attendeeName,
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text('Ticket ID: $ticketId',
                  style: const TextStyle(color: Colors.black54, fontSize: 14)),
              if (nonRefundable) ...[
                const SizedBox(height: 10),
                const Text('NON-REFUNDABLE',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ],
              if (nonTransferable) ...[
                const SizedBox(height: 6),
                const Text('NON-TRANSFERABLE',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 10),
              const Text('Present this QR code at the entrance.',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _TicketMessageScreen(
          message: 'Sign in to view your tickets.');
    }

    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        title: const Text('My Tickets',
            style: TextStyle(color: Color(0xFFFFD700))),
        backgroundColor: const Color(0xFF061E12),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('buyerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _TicketMessage(
              message: 'Tickets could not be loaded.',
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD700),
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

          if (tickets.isEmpty) {
            return const _TicketMessage(
              message: 'Your purchased tickets will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];

              return _MyTicketCard(
                ticketId: ticket.id,
                data: ticket.data(),
              );
            },
          );
        },
      ),
    );
  }
}

class _MyTicketCard extends StatelessWidget {
  const _MyTicketCard({
    required this.ticketId,
    required this.data,
  });

  final String ticketId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final eventId = data['eventId']?.toString() ?? '';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: eventId.isEmpty
          ? null
          : FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .snapshots(),
      builder: (context, snapshot) {
        final eventData = snapshot.data?.data();
        final status = eventData?['status']?.toString().toLowerCase() ?? '';

        final isCancelled = status == 'cancelled' || status == 'canceled';

        return _buildCard(
          context,
          isCancelled: isCancelled,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required bool isCancelled,
  }) {
    final eventName = data['eventName']?.toString() ?? 'Event';
    final attendeeName = data['attendeeName']?.toString() ?? '';
    final checkedIn = data['checkedIn'] == true;

    return Card(
      color: const Color(0xFF004D40),
      child: ListTile(
        title: Text(
          eventName,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              attendeeName,
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              checkedIn ? 'Checked in' : 'Unused',
              style: const TextStyle(color: Colors.white70),
            ),
            if (isCancelled)
              const Text(
                'EVENT CANCELLED',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Icon(
          isCancelled ? Icons.block : Icons.qr_code_2,
          color: isCancelled ? Colors.redAccent : const Color(0xFFFFD700),
        ),
        onTap: isCancelled
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TicketQRCodeScreen(
                      eventName: eventName,
                      attendeeName: attendeeName,
                      ticketId: data['ticketId']?.toString() ?? ticketId,
                      nonRefundable: data['nonRefundable'] == true,
                      nonTransferable: data['nonTransferable'] == true,
                    ),
                  ),
                );
              },
      ),
    );
  }
}

class _TicketMessageScreen extends StatelessWidget {
  final String message;

  const _TicketMessageScreen({required this.message});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF061E12),
        appBar: AppBar(
          title: const Text('My Tickets'),
          backgroundColor: const Color(0xFF061E12),
        ),
        body: _TicketMessage(message: message),
      );
}

class _TicketMessage extends StatelessWidget {
  final String message;

  const _TicketMessage({required this.message});

  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70))));
}

// Ã¢â€€Ã¢â€€ Ã°Å¸â€™Â¡ Ã¡Å Â¥Ã¡â€¹ÂÃ¡Å ÂÃ¡â€°Â°Ã¡Å â€º Ã¡â€¹Â¨Ã¡Å Â«Ã¡Ë†Å“Ã¡Ë†Â« Ã¡Ë†ÂµÃ¡Å Â«Ã¡Å ÂÃ¡Ë†Â­ (Admin Scanner) Ã¢â€€Ã¢â€€
class AdminScannerScreen extends StatefulWidget {
  const AdminScannerScreen({
    super.key,
    this.eventId,
  });

  final String? eventId;

  @override
  State<AdminScannerScreen> createState() => _AdminScannerScreenState();
}

class _AdminScannerScreenState extends State<AdminScannerScreen> {
  bool _isScanned = false;
  String? _resultMessage;
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: true,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void initState() {
    super.initState();
    if (!_canScanTickets()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scannerController.start().catchError((_) {});
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canScanTickets()) {
      return const _TicketMessageScreen(
        message: 'Only an authorized event organizer can scan tickets.',
      );
    }

    const darkGreen = Color(0xFF061E12);
    const gold = Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan Tickets',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: darkGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _scannerController,
                fit: BoxFit.cover,
                placeholderBuilder: (context) => Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: gold),
                      SizedBox(height: 14),
                      Text(
                        'Starting camera...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                errorBuilder: (context, error) => Container(
                  color: darkGreen,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.no_photography_outlined,
                        color: gold,
                        size: 60,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Camera could not start',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _scannerController.start().catchError((_) {}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: darkGreen,
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Camera'),
                      ),
                    ],
                  ),
                ),
                onDetect: (capture) {
                  if (_isScanned) return;

                  final code = capture.barcodes.firstOrNull?.rawValue;

                  if (code == null || code.isEmpty) return;

                  _verifyTicket(code);
                },
              ),
            ),

            // Dark overlay at the top.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 115,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      darkGreen.withValues(alpha: 0.95),
                      darkGreen.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),

            // Camera controls.
            Positioned(
              top: 18,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _scannerControlButton(
                    icon: Icons.flashlight_on,
                    onPressed: () => _scannerController.toggleTorch(),
                  ),
                  _scannerControlButton(
                    icon: Icons.cameraswitch,
                    onPressed: () => _scannerController.switchCamera(),
                  ),
                ],
              ),
            ),

            // QR scanning frame.
            Center(
              child: Transform.translate(
                offset: const Offset(0, -55),
                child: Container(
                  width: 245,
                  height: 245,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: gold,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: gold.withValues(alpha: 0.20),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.qr_code_2,
                      color: Colors.white24,
                      size: 70,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom information + button.
            Positioned(
              left: 20,
              right: 20,
              bottom: 28,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: darkGreen.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              color: gold,
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Place the ticket QR code inside the frame',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_resultMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _resultMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _resultMessage!.startsWith('VALID')
                                  ? Colors.greenAccent
                                  : gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isScanned = false;
                        _resultMessage = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: darkGreen,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      size: 25,
                    ),
                    label: const Text(
                      'Scan Next Ticket',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scannerControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF061E12).withValues(alpha: 0.88),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFFD700),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: const Color(0xFFFFD700),
        ),
      ),
    );
  }

  Future<void> _playScannerSound(String result) async {
    try {
      final player = AudioPlayer();

      if (result == 'valid') {
        await player.play(AssetSource('sounds/valid_ticket.wav'));
      } else if (result == 'already') {
        await player.play(AssetSource('sounds/already_scanned.wav'));
      } else {
        await player.play(AssetSource('sounds/invalid_ticket.wav'));
      }
    } catch (_) {
      // Le scanner continue de fonctionner mÃƒÂªme si le son ÃƒÂ©choue.
    }
  }

  bool _canScanTickets() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return false;
    }

    // Super Admin peut scanner.
    if (AppSession.isSuperAdmin) {
      return true;
    }

    final roles = AppSession.roles.map((role) => role.toLowerCase()).toSet();

    // Administrateur Events autorisÃƒÂ©.
    if (roles.contains('eventadmin') ||
        roles.contains('event_admin') ||
        roles.contains('manage_events') ||
        roles.contains('scan_tickets')) {
      return true;
    }

    // Lorsqu'on ouvre le scanner depuis le dashboard personnel,
    // l'autorisation prÃƒÂ©cise de l'organisateur sera vÃƒÂ©rifiÃƒÂ©e
    // avec le ticket et l'eventId pendant le scan.
    return widget.eventId != null && widget.eventId!.trim().isNotEmpty;
  }

  Future<void> _verifyTicket(String rawCode) async {
    final parts = rawCode.split('|');

    final ticketId = parts.length >= 2 && parts.first == 'EURO_HABESHA_TICKET'
        ? parts[1]
        : rawCode;

    if (!mounted) return;

    setState(() {
      _isScanned = true;
      _resultMessage = 'Checking ticket...';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (!mounted) return;

        setState(() {
          _resultMessage = 'INVALID: organizer is not signed in.';
        });
        return;
      }

      final selectedEventId = widget.eventId?.trim() ?? '';

      if (selectedEventId.isEmpty) {
        if (!mounted) return;

        setState(() {
          _resultMessage =
              'INVALID: open the scanner from your event dashboard.';
        });
        return;
      }

      // ---------------------------------------------------------
      // 1. Verify who owns/manages this specific event.
      // ---------------------------------------------------------

      final eventSubmissionSnapshot = await FirebaseFirestore.instance
          .collection('eventSubmissions')
          .doc(selectedEventId)
          .get();

      if (!eventSubmissionSnapshot.exists) {
        if (!mounted) return;

        setState(() {
          _resultMessage = 'INVALID: event was not found.';
        });
        return;
      }

      final eventData = eventSubmissionSnapshot.data()!;

      final ownerId = eventData['ownerId']?.toString().trim() ?? '';

      final eventStatus =
          eventData['status']?.toString().trim().toLowerCase() ?? '';

      final isEventOwner = ownerId.isNotEmpty && ownerId == currentUser.uid;

      final roles = AppSession.roles.map((role) => role.toLowerCase()).toSet();

      final isGlobalAdmin = AppSession.isSuperAdmin;

      final hasEventAdminRole = roles.contains('eventadmin') ||
          roles.contains('event_admin') ||
          roles.contains('manage_events') ||
          roles.contains('scan_tickets');

      final isPublished =
          eventStatus == 'approved' || eventStatus == 'published';

      if (!isPublished) {
        if (!mounted) return;

        setState(() {
          _resultMessage = 'INVALID: this event is not approved or published.';
        });
        return;
      }
      final publicEventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(selectedEventId)
          .get();

      if (!publicEventSnapshot.exists) {
        if (!mounted) return;

        setState(() {
          _resultMessage = 'INVALID: public event is not available.';
        });
        return;
      }

      final publicEventData = publicEventSnapshot.data()!;

      final publicEventStatus =
          publicEventData['status']?.toString().trim().toLowerCase() ?? '';

      final publicEventIsActive =
          publicEventStatus == 'approved' || publicEventStatus == 'published';

      if (!publicEventIsActive) {
        if (!mounted) return;

        setState(() {
          _resultMessage = 'INVALID: this event is cancelled or unavailable.';
        });
        return;
      }
      if (!isEventOwner && !isGlobalAdmin && !hasEventAdminRole) {
        if (!mounted) return;

        setState(() {
          _resultMessage = 'INVALID: you are not the organizer of this event.';
        });
        return;
      }

      // ---------------------------------------------------------
      // 2. Verify the scanned ticket.
      // ---------------------------------------------------------

      final ticketRef =
          FirebaseFirestore.instance.collection('tickets').doc(ticketId);

      Map<String, dynamic>? ticket;
      String? failureReason;
      var valid = false;

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final snapshot = await transaction.get(ticketRef);

          if (!snapshot.exists) {
            failureReason = 'INVALID: ticket was not found.';
            return;
          }

          final data = snapshot.data()!;
          ticket = data;

          final ticketEventId = data['eventId']?.toString().trim() ?? '';

          final paymentStatus =
              data['paymentStatus']?.toString().trim().toLowerCase() ?? '';

          final alreadyCheckedIn = data['checkedIn'] == true;

          // Ticket must belong to the event whose dashboard
          // opened this scanner.
          if (ticketEventId != selectedEventId) {
            failureReason = 'INVALID: this ticket belongs to another event.';
            return;
          }

          if (paymentStatus != 'purchased') {
            failureReason = 'INVALID: payment is not confirmed.';
            return;
          }

          if (alreadyCheckedIn) {
            failureReason =
                'ALREADY SCANNED: this ticket has already been used.';
            return;
          }

          valid = true;

          transaction.update(
            ticketRef,
            {
              'checkedIn': true,
              'checkedInAt': FieldValue.serverTimestamp(),
              'checkedInBy': currentUser.uid,
            },
          );
        },
      );

      if (!mounted) return;

      final data = ticket;

      String soundResult = 'invalid';

      setState(() {
        if (valid && data != null) {
          final attendeeName = data['attendeeName']?.toString().trim();

          _resultMessage =
              'VALID: ${attendeeName?.isNotEmpty == true ? attendeeName : 'customer'} - '
              'checked in successfully.';

          soundResult = 'valid';
        } else {
          _resultMessage =
              failureReason ?? 'INVALID: ticket could not be verified.';

          if (_resultMessage!.startsWith('ALREADY SCANNED')) {
            soundResult = 'already';
          }
        }
      });

      await _playScannerSound(soundResult);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _resultMessage = 'Could not verify ticket: $error';
      });
    }
  }
}
