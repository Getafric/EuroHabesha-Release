import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'app_session.dart';
import 'subscription_service.dart';
import 'dynamic_submission_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryDarkGreen = const Color(0xFF061E12);
    final Color primaryGold = const Color(0xFFFFD700);
    final Color cardGreen = const Color(0xFF004D40);

    // ── 3 የተለያየ አይነት የኢቨንት ምሳሌዎች ──
    final List<Map<String, dynamic>> eventsList = [
      {
        'title': 'Ethiopian New Year Mega Concert',
        'type': 'Concert & Party',
        'audience': 'Adults Only (18+)',
        'date': 'Sept 11, 2026',
        'time': '09:00 PM - 04:00 AM',
        'endTime': '04:00 AM',
        'location': 'Le Zénith Paris - La Villette, Paris',
        'price': '€45.00',
        'nonRefundable': true,
        'description': 'Join the biggest Ethiopian New Year celebration in Europe! Featuring top artists from home, live band, cultural food, and drinks. Get your tickets early before they sell out.',
        'performerDj': 'Rophnan + Live DJ',
        'amenities': ['VIP', 'Food', 'Shisha'],
        'artists': ['Teddy Afro (Special Guest)', 'Rophnan', 'Live Traditional Band'],
        'image': 'https://images.unsplash.com/photo-1540039155732-d6749b132338?auto=format&fit=crop&w=800&q=80',
      },
      {
        'title': 'Habesha Family & Kids Festival',
        'type': 'Family Entertainment',
        'audience': 'All Ages / Kids Friendly',
        'date': 'July 25, 2026',
        'time': '10:00 AM - 06:00 PM',
        'endTime': '06:00 PM',
        'location': 'Parc de la Tête d\'Or, Lyon',
        'price': '€15.00',
        'description': 'A beautiful day out for the whole family! Face painting for kids, bouncy castles, traditional games (Gebeta, Kuks), fashion show for children, and authentic Habesha BBQ (Tibs).',
        'performerDj': 'DJ Sammy',
        'amenities': ['Kids', 'Food', 'Games'],
        'artists': ['Kids Animators', 'DJ Sammy', 'Cultural Dance Troup'],
        'image': 'https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&w=800&q=80',
      },
      {
        'title': 'Eritrean Independence Day Gala',
        'type': 'Cultural Gala & Dinner',
        'audience': 'General & VIP',
        'date': 'May 24, 2026',
        'time': '07:00 PM - 01:00 AM',
        'endTime': '01:00 AM',
        'location': 'Palais des Congrès de Rome, Italy',
        'price': '€60.00',
        'description': 'A prestigious evening celebrating culture and heritage. The event includes a full course traditional dinner, networking sessions, cultural attire showcase, and live Guaila music.',
        'performerDj': 'Eden Kesete',
        'amenities': ['Dinner', 'VIP', 'Networking'],
        'artists': ['Eden Kesete', 'Korcho', 'Guest Speakers'],
        'image': 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=800&q=80',
      },
    ];

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text('Events & Tickets', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: IconThemeData(color: primaryGold),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: primaryGold),
            tooltip: 'Submit Event',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DynamicSubmissionScreen(type: SubmissionType.event)),
              );
            },
          ),
          if (_canScanTickets())
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.greenAccent),
              tooltip: 'Ticket Scanner',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScannerScreen())),
            ),
          IconButton(
            icon: const Icon(Icons.confirmation_number_outlined, color: Color(0xFFFFD700)),
            tooltip: 'My Tickets',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTicketsScreen())),
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
                final title = fields['title']?.toString() ?? data['title']?.toString() ?? 'Event';
                final type = fields['eventType']?.toString() ?? data['type']?.toString() ?? 'Concert & Party';
                final audience = fields['audience']?.toString() ?? data['audience']?.toString() ?? 'General';
                final date = fields['eventDate']?.toString() ?? data['date']?.toString() ?? 'Upcoming';
                final time = fields['eventTime']?.toString() ?? data['time']?.toString() ?? '';
                final endTime = fields['endTime']?.toString() ?? data['endTime']?.toString() ?? '';
                final location = fields['cityAddress']?.toString() ?? data['location']?.toString() ?? 'Europe';
                final price = fields['ticketPrice']?.toString() ?? data['price']?.toString() ?? '€0.00';
                final description = fields['description']?.toString() ?? data['description']?.toString() ?? '';
                final performer = fields['performer']?.toString() ?? data['performerDj']?.toString() ?? 'Live Show';
                final image = data['imageUrl']?.toString() ?? data['image']?.toString() ?? 'https://images.unsplash.com/photo-1540039155732-d6749b132338?auto=format&fit=crop&w=800&q=80';

                combined.add({
                  'id': doc.id,
                  'title': title,
                  'type': type,
                  'audience': audience,
                  'date': date,
                  'time': time,
                  'endTime': endTime,
                  'location': location,
                  'price': price.startsWith('€') ? price : '€$price',
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
                    MaterialPageRoute(builder: (context) => EventDetailScreen(eventData: event)),
                  );
                },
                child: Card(
                  color: cardGreen,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            child: Image.network(
                              event['image'],
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                height: 180,
                                color: Colors.white10,
                                child: const Icon(Icons.event, color: Colors.white38, size: 48),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 15,
                            right: 15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: primaryGold, borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                event['date'],
                                style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold, fontSize: 13),
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
                            Text(event['title'], style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                                const SizedBox(width: 5),
                                Expanded(child: Text(event['location'], style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (event['performerDj'] != null && (event['performerDj'] as String).isNotEmpty)
                                  _buildEventBadge(Icons.mic, event['performerDj'], primaryGold),
                                if (event['endTime'] != null && (event['endTime'] as String).isNotEmpty)
                                  _buildEventBadge(Icons.schedule, 'Ends ${event['endTime']}', primaryGold),
                                if (event['audience'] != null && (event['audience'] as String).isNotEmpty)
                                  _buildEventBadge(Icons.no_adult_content, event['audience'], primaryGold),
                                if (event['amenities'] is List)
                                  for (final amenity in (event['amenities'] as List)) _buildEventBadge(Icons.local_activity, amenity.toString(), primaryGold),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tickets from: ${event['price']}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: primaryGold.withOpacity(0.2), borderRadius: BorderRadius.circular(5)),
                                  child: const Text('Get Ticket', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12)),
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: primaryGold.withOpacity(0.55)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: Icon(Icons.notifications_active_outlined, color: primaryGold, size: 18),
                                label: const Text('Follow Event Updates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  final followed = await SubscriptionService.follow(
                                    type: 'event',
                                    targetId: event['title'].toString().toLowerCase().replaceAll(' ', '_'),
                                    targetName: event['title'],
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(followed ? 'You will receive updates for this event.' : 'Sign in and verify your email to follow event updates.')),
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
    return AppSession.isSuperAdmin || roles.contains('eventadmin') || roles.contains('event_admin') || roles.contains('organizer');
  }

  Widget _buildEventBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── 💡 የኢቨንቱ ሙሉ ማብራሪያ ገጽ ──
class EventDetailScreen extends StatelessWidget {
  final Map<String, dynamic> eventData;

  const EventDetailScreen({super.key, required this.eventData});

  @override
  Widget build(BuildContext context) {
    final Color primaryDarkGreen = const Color(0xFF061E12);
    final Color primaryGold = const Color(0xFFFFD700);
    final Color cardGreen = const Color(0xFF004D40);
    final eventDetails = eventData['eventDetails'] is Map ? Map<String, dynamic>.from(eventData['eventDetails'] as Map) : const <String, dynamic>{};
    final nonRefundable = eventData['nonRefundable'] == true || eventDetails['nonRefundable'] == true;
    final nonTransferable = eventData['nonTransferable'] == true || eventDetails['nonTransferable'] == true;

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('Event Details', style: TextStyle(color: Color(0xFFFFD700))),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(eventData['image'], height: 220, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eventData['title'], style: TextStyle(color: primaryGold, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  _buildInfoRow(Icons.calendar_today, 'Date & Time', '${eventData['date']} \n${eventData['time']}', primaryGold),
                  const SizedBox(height: 15),
                  _buildInfoRow(Icons.schedule, 'End Time', eventData['endTime'] ?? 'Not specified', primaryGold),
                  const SizedBox(height: 15),
                  _buildInfoRow(Icons.mic, 'Performer / DJ', eventData['performerDj'] ?? 'Not specified', primaryGold),
                  const SizedBox(height: 15),
                  _buildInfoRow(Icons.location_on, 'Location', eventData['location'], primaryGold),
                  const SizedBox(height: 15),
                  _buildInfoRow(Icons.people, 'Audience / Type', '${eventData['audience']} \n${eventData['type']}', primaryGold),
                  if (nonRefundable || nonTransferable) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.16), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.block, color: Colors.redAccent),
                          SizedBox(width: 10),
                          Expanded(child: Text('TICKET POLICY\n${nonRefundable ? 'Tickets cannot be refunded after purchase. ' : ''}${nonTransferable ? 'Tickets cannot be transferred to another person.' : ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, height: 1.4))),
                        ],
                      ),
                    ),
                  ],
                  
                  const Divider(color: Colors.white24, height: 40),

                  Text('About the Event', style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(eventData['description'], style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                  
                  const SizedBox(height: 20),
                  
                  Text('Featuring / Lineup', style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: (eventData['artists'] as List).map((artist) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(20), border: Border.all(color: primaryGold.withOpacity(0.5))),
                      child: Text(artist, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    )).toList(),
                  ),
                  const SizedBox(height: 120), 
                ],
              ),
            ),
          ],
        ),
      ),
      // ── 💡 አዲሱ ወደ ላይ ከፍ ያለ የቲኬት መግዣ ባር (bottomNavigationBar) ──
      bottomNavigationBar: Container(
        color: cardGreen,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 30), // 💡 bottom: 30 አድርገን ከፍ አድርገነዋል!
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ticket Price', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(eventData['price'], style: TextStyle(color: primaryGold, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGold,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => TicketCheckoutScreen(eventData: {...eventData, 'nonRefundable': nonRefundable}))
                    );
                  },
                  child: const Text('Buy Ticket', style: TextStyle(color: Color(0xFF061E12), fontWeight: FontWeight.bold, fontSize: 16)),
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
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 💡 የቲኬት መመዝገቢያ እና መክፈያ ገጽ ──
class TicketCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> eventData;

  const TicketCheckoutScreen({super.key, required this.eventData});

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

  bool get _nonRefundable {
    final eventDetails = widget.eventData['eventDetails'];
    return widget.eventData['nonRefundable'] == true || (eventDetails is Map && eventDetails['nonRefundable'] == true);
  }

  bool get _nonTransferable {
    final eventDetails = widget.eventData['eventDetails'];
    return widget.eventData['nonTransferable'] == true || (eventDetails is Map && eventDetails['nonTransferable'] == true);
  }

  Future<void> _processPayment() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Name and Email.')));
      return;
    }

    if (_nonRefundable) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Non-refundable ticket'),
          content: const Text('This ticket cannot be refunded after purchase. Do you want to continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('I Understand')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in and verify your email before purchasing a ticket.')));
      return;
    }

    setState(() => isProcessing = true);

    final ticketId = 'EH-${DateTime.now().millisecondsSinceEpoch}-${user.uid.substring(0, 6)}';
    final eventId = _eventId(widget.eventData['title'].toString());
    try {
      await FirebaseFirestore.instance.collection('tickets').doc(ticketId).set({
        'ticketId': ticketId,
        'eventId': eventId,
        'eventName': widget.eventData['title'],
        'buyerId': user.uid,
        'buyerEmail': _emailController.text.trim(),
        'attendeeName': _nameController.text.trim(),
        'price': widget.eventData['price'],
        'paymentStatus': 'purchased',
        'checkedIn': false,
        'nonRefundable': _nonRefundable,
        'nonTransferable': _nonTransferable,
        'eventAdminIds': [
          ...((widget.eventData['eventAdminIds'] as List?)?.map((id) => id.toString()) ?? const <String>[]),
          if (widget.eventData['organizerId'] != null) widget.eventData['organizerId'].toString(),
          if (widget.eventData['submittedBy'] != null) widget.eventData['submittedBy'].toString(),
        ].toSet().toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (mounted) {
        setState(() => isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ticket could not be issued: $error')));
      }
      return;
    }
    if (!mounted) return;
    setState(() => isProcessing = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TicketQRCodeScreen(
          eventName: widget.eventData['title'],
          attendeeName: _nameController.text.trim(),
          ticketId: ticketId,
          nonRefundable: _nonRefundable,
          nonTransferable: _nonTransferable,
        ),
      ),
    );
  }

  String _eventId(String title) => title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Color(0xFFFFD700))),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.eventData['image'],
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 70,
                        height: 70,
                        color: primaryDarkGreen,
                        child: Icon(Icons.event, color: primaryGold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.eventData['title'], style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 5),
                        Text('1x Ticket • ${widget.eventData['price']}', style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 25),

            Text('Attendee Details', style: TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Full Name (For Ticket Verification)',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: cardGreen,
                prefixIcon: Icon(Icons.person, color: primaryGold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Email Address (To receive receipt)',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: cardGreen,
                prefixIcon: Icon(Icons.email, color: primaryGold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 25),

            if (_nonRefundable || _nonTransferable)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.16), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent)),
                child: Text('TICKET POLICY: ${_nonRefundable ? 'This ticket cannot be refunded after purchase. ' : ''}${_nonTransferable ? 'This ticket cannot be transferred to another person.' : ''} You must confirm this before payment.', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, height: 1.4)),
              ),
            if (_nonRefundable || _nonTransferable) const SizedBox(height: 16),

            Text('Payment Method', style: TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildPaymentOption('Card', Icons.credit_card, 'Credit or Debit Card'),
            const SizedBox(height: 10),
            _buildPaymentOption('PayPal', Icons.paypal, 'Pay with PayPal account'),
            const SizedBox(height: 10),
            _buildPaymentOption('Apple Pay', Icons.apple, 'Pay seamlessly via Apple Pay'),
            const SizedBox(height: 60), 
          ],
        ),
      ),
      // ── 💡 አዲሱ ወደ ላይ ከፍ ያለ የክፍያ ቁልፍ (bottomNavigationBar) ──
      bottomNavigationBar: Container(
        color: cardGreen,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 30), // 💡 bottom: 30 የተጨመረበት ቦታ
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGold,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isProcessing ? null : _processPayment,
                child: isProcessing 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF061E12), strokeWidth: 3))
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Pay ${widget.eventData['price']} & Get Ticket', style: const TextStyle(color: Color(0xFF061E12), fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String value, IconData icon, String subtitle) {
    bool isSelected = selectedPayment == value;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryGold.withOpacity(0.1) : cardGreen,
          border: Border.all(color: isSelected ? primaryGold : Colors.transparent, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primaryGold : Colors.white54, size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: primaryGold),
          ],
        ),
      ),
    );
  }
}

// ── 💡 የ QR ኮድ ማሳያ ──
class TicketQRCodeScreen extends StatelessWidget {
  final String eventName;
  final String attendeeName;
  final String ticketId;
  final bool nonRefundable;
  final bool nonTransferable;

  const TicketQRCodeScreen({super.key, required this.eventName, required this.attendeeName, required this.ticketId, this.nonRefundable = false, this.nonTransferable = false});

  @override
  Widget build(BuildContext context) {
    final qrPayload = 'EURO_HABESHA_TICKET|$ticketId|$eventName|$attendeeName';

    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(title: const Text('My Ticket', style: TextStyle(color: Color(0xFFFFD700))), backgroundColor: const Color(0xFF061E12)),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('EURO HABESHA TICKET', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const Divider(color: Colors.black26),
              const SizedBox(height: 10),
              Text(eventName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 210,
                backgroundColor: Colors.white,
              ),
              
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, color: Colors.black54, size: 16),
                    const SizedBox(width: 5),
                    Text(attendeeName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              
              const SizedBox(height: 15),
              Text('Ticket ID: $ticketId', style: const TextStyle(color: Colors.black54, fontSize: 14)),
              if (nonRefundable) ...[
                const SizedBox(height: 10),
                const Text('NON-REFUNDABLE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
              if (nonTransferable) ...[
                const SizedBox(height: 6),
                const Text('NON-TRANSFERABLE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 10),
              const Text('Present this QR code at the entrance.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
      return const _TicketMessageScreen(message: 'Sign in to view your tickets.');
    }

    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        title: const Text('My Tickets', style: TextStyle(color: Color(0xFFFFD700))),
        backgroundColor: const Color(0xFF061E12),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('tickets').where('buyerId', isEqualTo: user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const _TicketMessage(message: 'Tickets could not be loaded.');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
          final tickets = [...snapshot.data!.docs]..sort((a, b) {
            final aDate = a.data()['createdAt'] as Timestamp?;
            final bDate = b.data()['createdAt'] as Timestamp?;
            return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(aDate?.millisecondsSinceEpoch ?? 0);
          });
          if (tickets.isEmpty) return const _TicketMessage(message: 'Your purchased tickets will appear here.');
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final data = tickets[index].data();
              return Card(
                color: const Color(0xFF004D40),
                child: ListTile(
                  title: Text(data['eventName']?.toString() ?? 'Event', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                  subtitle: Text('${data['attendeeName'] ?? ''}\n${data['checkedIn'] == true ? 'Checked in' : 'Unused'}', style: const TextStyle(color: Colors.white70)),
                  trailing: const Icon(Icons.qr_code_2, color: Color(0xFFFFD700)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketQRCodeScreen(
                    eventName: data['eventName']?.toString() ?? 'Event',
                    attendeeName: data['attendeeName']?.toString() ?? '',
                    ticketId: data['ticketId']?.toString() ?? tickets[index].id,
                    nonRefundable: data['nonRefundable'] == true,
                    nonTransferable: data['nonTransferable'] == true,
                  ))),
                ),
              );
            },
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
        appBar: AppBar(title: const Text('My Tickets'), backgroundColor: const Color(0xFF061E12)),
      body: _TicketMessage(message: message),
      );
}

class _TicketMessage extends StatelessWidget {
  final String message;

  const _TicketMessage({required this.message});

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))));
}

// ── 💡 እውነተኛ የካሜራ ስካነር (Admin Scanner) ──
class AdminScannerScreen extends StatefulWidget {
  const AdminScannerScreen({super.key});

  @override
  State<AdminScannerScreen> createState() => _AdminScannerScreenState();
}

class _AdminScannerScreenState extends State<AdminScannerScreen> {
  bool _isScanned = false;
  String? _lastCode;
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
      return const _TicketMessageScreen(message: 'Only an authorized event organizer can scan tickets.');
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Tickets', style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.black, 
        iconTheme: const IconThemeData(color: Colors.white)
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            fit: BoxFit.cover,
            placeholderBuilder: (context) => Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFFD700)),
                  SizedBox(height: 14),
                  Text('Starting camera...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            errorBuilder: (context, error) => Container(
              color: Colors.black,
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.no_photography_outlined, color: Color(0xFFFFD700), size: 64),
                  const SizedBox(height: 14),
                  const Text('Camera could not start', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(error.errorDetails?.message ?? error.errorCode.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
                    onPressed: () => _scannerController.start().catchError((_) {}),
                    icon: const Icon(Icons.refresh, color: Color(0xFF061E12)),
                    label: const Text('Retry Camera', style: TextStyle(color: Color(0xFF061E12), fontWeight: FontWeight.bold)),
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
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFD700), width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  onPressed: () => _scannerController.toggleTorch(),
                  icon: const Icon(Icons.flashlight_on, color: Color(0xFFFFD700)),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  onPressed: () => _scannerController.switchCamera(),
                  icon: const Icon(Icons.cameraswitch, color: Color(0xFFFFD700)),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_lastCode != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
                    child: Text(_lastCode!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_resultMessage != null) ...[
                  Text(_resultMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                ],
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), minimumSize: const Size(double.infinity, 48)),
                  onPressed: () => setState(() {
                    _isScanned = false;
                    _lastCode = null;
                    _resultMessage = null;
                  }),
                  icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF061E12)),
                  label: const Text('Scan Next Ticket', style: TextStyle(color: Color(0xFF061E12), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static bool _canScanTickets() {
    final roles = AppSession.roles.map((role) => role.toLowerCase()).toSet();
    return AppSession.isSuperAdmin || roles.contains('eventadmin') || roles.contains('event_admin') || roles.contains('organizer');
  }

  Future<void> _verifyTicket(String rawCode) async {
    final parts = rawCode.split('|');
    final ticketId = parts.length >= 2 && parts.first == 'EURO_HABESHA_TICKET' ? parts[1] : rawCode;
    setState(() {
      _isScanned = true;
      _lastCode = rawCode;
      _resultMessage = 'Checking ticket...';
    });

    try {
      final ticketRef = FirebaseFirestore.instance.collection('tickets').doc(ticketId);
      Map<String, dynamic>? ticket;
      var valid = false;
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ticketRef);
        if (!snapshot.exists) return;
        ticket = snapshot.data();
        final data = ticket!;
        valid = data['paymentStatus'] == 'purchased' && data['checkedIn'] != true;
        if (valid) {
          transaction.update(ticketRef, {'checkedIn': true, 'checkedInAt': FieldValue.serverTimestamp(), 'checkedInBy': FirebaseAuth.instance.currentUser?.uid});
        }
      });
      if (!mounted) return;
      final data = ticket;
      setState(() {
        _resultMessage = data == null
            ? 'INVALID: ticket was not found.'
            : valid
                ? 'VALID: purchased for ${data['attendeeName'] ?? 'customer'}. Checked in successfully.'
                : data['checkedIn'] == true
                    ? 'INVALID: this ticket was already checked in.'
                    : 'INVALID: payment is not confirmed.';
      });
    } catch (error) {
      if (mounted) setState(() => _resultMessage = 'Could not verify ticket: $error');
    }
  }
}
