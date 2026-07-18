import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'access_control.dart';
import 'admin_post_page.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(String title, String body, String category) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final haystack = '$title $body $category'.toLowerCase();
    return haystack.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Events Hub', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF123222), Color(0xFF0A2418), Color(0xFF1F3F2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.35)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Events Hub: Browse, Search, Post',
                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  'See community event updates, filter what you need, and publish official event announcements in one hub.',
                  style: TextStyle(color: Color(0xFFE8D79B), fontSize: 12.5, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search events by title, type, or content',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF0E2E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFF59E0B)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: const Color(0xFF061E12),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              if (!AccessControl.ensureVerified(context, actionLabel: tr('rsvp'))) {
                return;
              }
              final navigator = Navigator.of(context);
              final canOpen = await AccessControl.ensureAdminAccess(
                context,
                actionLabel: 'Publish Event',
              );
              if (!canOpen || !mounted) return;
              navigator.push(
                MaterialPageRoute(builder: (_) => const AdminPanelPage()),
              );
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Publish Event Announcement'),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .orderBy('createdAt', descending: true)
                .limit(80)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final eventDocs = docs.where((doc) {
                final data = doc.data();
                final category = (data['category'] ?? '').toString().toLowerCase();
                final type = (data['type'] ?? '').toString().toLowerCase();
                final title = (data['title'] ?? '').toString();
                final body = (data['body'] ?? '').toString();
                final isEvent = category.contains('event') || type.contains('event');
                return isEvent && _matches(title, body, category);
              }).toList();

              if (eventDocs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E2E1E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Text(
                    'No event announcements found for this search yet.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                );
              }

              return Column(
                children: eventDocs.map((doc) {
                  final data = doc.data();
                  final title = (data['title'] ?? 'Event').toString();
                  final body = (data['body'] ?? '').toString();
                  final category = (data['category'] ?? 'Events').toString();

                  return Card(
                    color: const Color(0xFF0E2E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white10),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  category,
                                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          if (body.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              body,
                              style: const TextStyle(color: Colors.white70, height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
