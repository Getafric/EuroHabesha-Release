import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class EscfeRomeGuideScreen extends StatefulWidget {
  const EscfeRomeGuideScreen({super.key});

  @override
  State<EscfeRomeGuideScreen> createState() => _EscfeRomeGuideScreenState();
}

class _EscfeRomeGuideScreenState extends State<EscfeRomeGuideScreen> {
  static const Color _gold = Color(0xFFF59E0B);
  static const Color _bg = Color(0xFF061E12);
  static const Color _panel = Color(0xFF0E2E1E);

  final Uri _websiteUri = Uri.parse('https://www.escfe.net');
  final Uri _shareUri = Uri.parse('https://www.escfe.net/rome-2026');

  final List<Map<String, String>> _routes = const [
    {
      'name': 'From Fiumicino Airport (FCO) to Salaria Sport Village',
      'publicTransport': 'Leonardo Express to Roma Termini, then Metro B1 toward Jonio or a taxi to the venue area. If you prefer rail only, continue with the regional/urban connection from Termini to the northern part of the city and finish by taxi.',
      'driving': 'Approx. 32 km | 35-50 minutes by car, depending on traffic on the Grande Raccordo Anulare and inner-city roads.',
      'note': 'Best for international arrivals with luggage and groups.',
    },
    {
      'name': 'From Ciampino Airport (CIA) to Salaria Sport Village',
      'publicTransport': 'Airport shuttle to Roma Termini or Anagnina, then continue by Metro A to Termini and connect to a northern bus/taxi link. The simplest option is usually a pre-booked transfer from the airport terminal.',
      'driving': 'Approx. 28 km | 30-45 minutes by car in normal traffic.',
      'note': 'Usually the quickest arrival for short-haul visitors.',
    },
    {
      'name': 'From Roma Termini to Salaria Sport Village',
      'publicTransport': 'From Termini, use a taxi for the fastest trip. For public transport, connect to the northern bus network from Piazza dei Cinquecento or move by Metro B/B1 toward the Salario area, then finish with a short taxi or local bus ride.',
      'driving': 'Approx. 8 km | 20-30 minutes by car, depending on rush hour.',
      'note': 'Best option for guests already staying in central Rome.',
    },
    {
      'name': 'Driving to Salaria Sport Village',
      'publicTransport': 'Not applicable for drivers. Use parking signage at the venue and the drop-off point first if the event area is busy.',
      'driving': 'Plan 25-45 minutes from central Rome or 35-50 minutes from either airport.',
      'note': 'Arrive early to secure parking and avoid last-minute congestion.',
    },
  ];

  Future<void> _saveToCalendar() async {
    final start = Uri.encodeComponent('2026-07-27T09:00:00Z');
    final end = Uri.encodeComponent('2026-08-01T18:00:00Z');
    final url = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE&text=21st+ESCFE+Annual+Event+Rome+2026&dates=$start/$end&location=Salaria+Sport+Village+Rome&details=ESCFE+Rome+2026',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open calendar app.')),
      );
    }
  }

  Future<void> _openWebsite() async {
    await launchUrl(_websiteUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _shareEvent() async {
    await Clipboard.setData(ClipboardData(text: _shareUri.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Event link copied: ${_shareUri.toString()}')),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Card(
      color: _panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutePath() {
    final stops = const [
      ('FCO', 'Airport'),
      ('CIA', 'Airport'),
      ('Termini', 'Rail hub'),
      ('Venue', 'Salaria Sport Village'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2317), Color(0xFF123424)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Static Route Path',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'A quick visual guide showing the main arrival points and final venue stop.',
            style: TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 132,
            child: Stack(
              children: [
                Positioned(
                  left: 30,
                  top: 12,
                  bottom: 18,
                  child: Container(width: 4, color: Colors.redAccent.withValues(alpha: 0.9)),
                ),
                for (var i = 0; i < stops.length; i++)
                  Positioned(
                    left: 12,
                    top: 8.0 + (i * 34.0),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == stops.length - 1 ? _gold : Colors.white,
                            border: Border.all(color: Colors.redAccent, width: 2),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stops[i].$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                            Text(stops[i].$2, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Map<String, String> route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            route['name']!,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.25),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMetricChip('Public Transport', route['publicTransport']!),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricChip('Driving Details', route['driving']!),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            route['note']!,
            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF061E12), Color(0xFF0F3A24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.14,
              child: Image.network(
                'https://images.unsplash.com/photo-1462917882517-e150004895fa?w=1200',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: const Color(0xFF061E12).withValues(alpha: 0.35)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xFF061E12).withValues(alpha: 0.6),
                        border: Border.all(color: _gold, width: 1.2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/branding/image_1.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.event, color: Color(0xFFF59E0B), size: 36),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '21st ESCFE ANNUAL EVENT — ROME 2026',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '27 July — 1 August 2026',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'SALARIA SPORT VILLAGE',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'ESCFE Official Organizer',
                            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'ESCFE Rome 2026 combines sport, community, and travel planning in one guide. The layout below is static and intentionally simple, so you can scan the route information without opening a live map.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: _bg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _saveToCalendar,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Save to Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        title: const Text('ESCFE Rome 2026'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareEvent,
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildPosterSection(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('At-a-Glance Travel Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _buildRoutePath(),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(child: Text('Route', style: TextStyle(color: Colors.white54, fontSize: 11))),
                    Expanded(child: Text('Public transport', style: TextStyle(color: Colors.white54, fontSize: 11))),
                    Expanded(child: Text('Driving', style: TextStyle(color: Colors.white54, fontSize: 11))),
                  ],
                ),
                const SizedBox(height: 12),
                ..._routes.map(_buildRouteCard),
                const SizedBox(height: 10),
                const Text('Important Visitor Information', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                _buildChecklistCard(),
                const SizedBox(height: 12),
                _buildTipsCard(),
                const SizedBox(height: 18),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: _openWebsite,
                        child: const Text('www.escfe.net', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                      ),
                      TextButton.icon(
                        onPressed: _saveToCalendar,
                        icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFFF59E0B)),
                        label: const Text('Save to Calendar', style: TextStyle(color: Colors.white70)),
                      ),
                      TextButton.icon(
                        onPressed: _shareEvent,
                        icon: const Icon(Icons.share_outlined, color: Color(0xFFF59E0B)),
                        label: const Text('Share this event page', style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Checklist', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          SizedBox(height: 10),
          _BulletText('Match tickets and your ID or passport.'),
          _BulletText('Comfortable sports shoes and light clothing.'),
          _BulletText('Hat, sunblock, and a reusable water bottle.'),
          _BulletText('Community colors or an Ethiopian flag for the atmosphere.'),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Travel Tips', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          SizedBox(height: 10),
          _BulletText('Rome is very hot in July, so plan for shade and water breaks.'),
          _BulletText('Keep valuables secure at airports, stations, and crowded event areas.'),
          _BulletText('Leave early if you are arriving by car to avoid parking delays.'),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, height: 1.45))),
        ],
      ),
    );
  }
}
