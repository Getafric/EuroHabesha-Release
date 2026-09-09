import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 🗺️ ማፕ ለመክፈት
import 'subscription_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedReligion;

  final List<Map<String, dynamic>> communities = [
    {
      'name': 'Ethiopian Orthodox Tewahedo Church - Rome',
      'type': 'Orthodox Church',
      'location': 'Rome, Italy',
      'address': 'Via di Monte Polacco, 5, 00184 Roma RM, Italy',
      'phone': '+39 06 1234567',
      'email': 'rome.orthodox@eurohabesha.eu',
      'image': 'https://images.unsplash.com/photo-1543783207-ec64e4d95325?auto=format&fit=crop&w=800&q=80',
      'adminName': 'Kes Geleta (Lead Admin)',
      'isFollowing': false,
      'followersCount': 342,
      'posts': [
        {'author': 'Kes Geleta', 'text': 'እንኳን ለብርሃነ ትንሳኤው በሰላም አደረሳችሁ! የእሁድ መርሃ-ግብር ከጥዋቱ 2:00 ሰዓት ይጀምራል።', 'time': '2 hours ago'},
        {'author': 'Kes Geleta', 'text': 'የሰንበት ትምህርት ቤት መርሃ-ግብር ከሰዓት በኋላ ይካሄዳል።', 'time': '5 hours ago'},
      ]
    },
    {
      'name': 'Habesha Bilal Mosque - Lyon',
      'type': 'Mosque & Islamic Center',
      'location': 'Lyon, France',
      'address': '15 Rue de Marseille, 69007 Lyon, France',
      'phone': '+33 4 78 00 00 00',
      'email': 'lyon.mosque@eurohabesha.eu',
      'image': 'https://images.unsplash.com/photo-1564769625615-f10b0e5a914d?auto=format&fit=crop&w=800&q=80',
      'adminName': 'Sheikh Ahmed (Page Admin)',
      'isFollowing': true,
      'followersCount': 512,
      'posts': [
        {'author': 'Sheikh Ahmed', 'text': 'የጁምዓ ሶላት ከቀኑ 7:00 ሰዓት ይጀምራል። ሁሉም በሰዓቱ እንዲገኙ እናሳስባለን።', 'time': 'Yesterday'},
      ]
    },
    {
      'name': 'Habesha Evangelical Church - Paris',
      'type': 'Protestant Church',
      'location': 'Paris, France',
      'address': '10 Rue de la Paix, 75002 Paris, France',
      'phone': '+33 1 42 00 00 00',
      'email': 'paris.evangelical@eurohabesha.eu',
      'image': 'https://images.unsplash.com/photo-1548625361-1694f454a372?auto=format&fit=crop&w=800&q=80',
      'adminName': 'Pastor Daniel (Admin)',
      'isFollowing': false,
      'followersCount': 280,
      'posts': [
        {'author': 'Pastor Daniel', 'text': 'የሐሙስ የምስጋና ጸሎት ማህበር ከማታው 12:00 ሰዓት ጀምሮ ይካሄዳል።', 'time': '3 days ago'},
      ]
    },
    {
      'name': 'Eritrean Orthodox Community - Stockholm',
      'type': 'Eritrean Orthodox Community',
      'location': 'Stockholm, Sweden',
      'address': 'Central Stockholm, Sweden',
      'phone': '+46 70 000 00 00',
      'email': 'eritrean.stockholm@eurohabesha.eu',
      'image': 'https://images.unsplash.com/photo-1518005020951-eccb494ad742?auto=format&fit=crop&w=800&q=80',
      'adminName': 'Community Admin',
      'isFollowing': false,
      'followersCount': 185,
      'posts': [
        {'author': 'Community Admin', 'text': 'Community gathering and cultural support updates will be posted here.', 'time': 'Today'},
      ]
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCommunities {
    final query = _searchQuery.trim().toLowerCase();
    return communities.where((community) {
      final type = (community['type'] ?? '').toString().toLowerCase();
      final searchableText = [
        community['name'],
        community['type'],
        community['location'],
        community['address'],
        community['adminName'],
      ].whereType<String>().join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchableText.contains(query);
      final matchesReligion = _selectedReligion == null || type.contains(_selectedReligion!.toLowerCase());
      return matchesSearch && matchesReligion;
    }).toList();
  }

  void _showAddPostDialog(BuildContext context, int index) {
    final TextEditingController postController = TextEditingController();
    final community = _filteredCommunities[index];
    final commName = community['name'] ?? 'Community';
    final adminName = community['adminName'] ?? 'Admin';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGreen,
        title: Text('Admin Post: $commName', style: TextStyle(color: primaryGold, fontSize: 15)),
        content: TextField(
          controller: postController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Write official announcement as $adminName...',
            hintStyle: const TextStyle(color: Colors.white54),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
            onPressed: () {
              if (postController.text.isNotEmpty) {
                setState(() {
                  List postsList = community['posts'] ?? [];
                  postsList.insert(0, {
                    'author': adminName,
                    'text': postController.text,
                    'time': 'Just now',
                  });
                  community['posts'] = postsList;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Official announcement published!')),
                );
              }
            },
            child: const Text('Publish', style: TextStyle(color: Color(0xFF061E12), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openCommunityDetail(Map<String, dynamic> comm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityDetailScreen(community: comm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text('Habesha Communities & Churches', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryGold),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search community, city, address...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: primaryGold),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                filled: true,
                fillColor: cardGreen,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ['Orthodox', 'Protestant', 'Muslim', 'Catholic', 'Eritrean'].map((religion) {
                final selected = _selectedReligion == religion;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(religion),
                    selected: selected,
                    backgroundColor: cardGreen,
                    selectedColor: primaryGold,
                    checkmarkColor: primaryDarkGreen,
                    labelStyle: TextStyle(color: selected ? primaryDarkGreen : Colors.white, fontWeight: FontWeight.bold),
                    side: BorderSide(color: selected ? primaryGold : Colors.white24),
                    onSelected: (value) {
                      setState(() {
                        _selectedReligion = value ? religion : null;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _filteredCommunities.isEmpty
                ? const Center(child: Text('No communities found.', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredCommunities.length,
        itemBuilder: (context, index) {
          final comm = _filteredCommunities[index];
          final List posts = comm['posts'] ?? [];
          final String name = comm['name'] ?? '';
          final String type = comm['type'] ?? '';
          final String location = comm['location'] ?? '';
          final String adminName = comm['adminName'] ?? '';
          final int followersCount = comm['followersCount'] ?? 0;
          final String imageUrl = comm['image'] ?? '';

          return GestureDetector(
            onTap: () => _openCommunityDetail(comm),
            child: Card(
              color: cardGreen,
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => CircleAvatar(
                                    backgroundColor: primaryGold.withOpacity(0.2),
                                    child: Icon(Icons.church, color: primaryGold),
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: primaryGold.withOpacity(0.2),
                                  child: Icon(Icons.church, color: primaryGold),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(color: primaryGold, fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('$type • $location', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              Text('Admin: $adminName • $followersCount Followers', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    Text('Latest Announcements:', style: TextStyle(color: primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...List.generate(posts.length > 1 ? 1 : posts.length, (pIndex) {
                      final post = posts[pIndex];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryDarkGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(post['author'] ?? '', style: TextStyle(color: primaryGold, fontSize: 11, fontWeight: FontWeight.bold)),
                                Text(post['time'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(post['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tap for full details & map ➔', style: TextStyle(color: primaryGold.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic)),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: primaryGold, shape: BoxShape.circle),
                            child: Icon(Icons.add, color: primaryDarkGreen, size: 16),
                          ),
                          tooltip: 'Page Admin Post',
                          onPressed: () => _showAddPostDialog(context, index),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
          ),
        ],
      ),
    );
  }
}

class CommunityDetailScreen extends StatelessWidget {
  final Map<String, dynamic> community;
  const CommunityDetailScreen({super.key, required this.community});

  // 🗺️ ሉቋል: ጉግል ማፕ በቀጥታ የሚከፍትበት ፈንክሽን (Google Maps Launcher)
  Future<void> _openMap(String address) async {
    final Uri mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch map for address: $address');
      }
    } catch (e) {
      debugPrint('Error launching map: $e');
    }
  }

  Future<void> _followForUpdates(BuildContext context, String name) async {
    final followed = await SubscriptionService.follow(
      type: 'community',
      targetId: name.toLowerCase().replaceAll(' ', '_'),
      targetName: name,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(followed ? 'You will receive updates from $name.' : 'Sign in and verify your email to follow this community.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryDarkGreen = const Color(0xFF061E12);
    final Color primaryGold = const Color(0xFFFFD700);
    final Color cardGreen = const Color(0xFF004D40);

    final String name = community['name'] ?? '';
    final String type = community['type'] ?? '';
    final String location = community['location'] ?? '';
    final String address = community['address'] ?? 'Not specified';
    final String phone = community['phone'] ?? 'Not specified';
    final String imageUrl = community['image'] ?? '';
    final List posts = community['posts'] ?? [];

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text(name, style: TextStyle(color: primaryGold, fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: IconThemeData(color: primaryGold),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(height: 220, color: cardGreen, child: Icon(Icons.church, color: primaryGold, size: 80)),
                  )
                : Container(height: 220, color: cardGreen, child: Icon(Icons.church, color: primaryGold, size: 80)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(color: primaryGold, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('$type • $location', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        foregroundColor: primaryDarkGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Follow for Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: () => _followForUpdates(context, name),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFFFD700), size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Address: $address', style: const TextStyle(color: Colors.white, fontSize: 13))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.phone, color: Color(0xFFFFD700), size: 20),
                            const SizedBox(width: 8),
                            Text('Phone: $phone', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGold,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              // 🗺️ አሁን ማፑን በቀጥታ ይከፍታል!
                              _openMap(address);
                            },
                            child: Text('Get Directions / Map 🗺️', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Official Announcements (${posts.length})', style: TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...List.generate(posts.length, (i) {
                    final p = posts[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Admin: ${p['author'] ?? 'Admin'}', style: TextStyle(color: primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(p['time'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(p['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
