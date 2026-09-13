import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dynamic_submission_screen.dart';
import 'quote_request_screen.dart';
import 'status_badge_widget.dart';

class ProfessionalsScreen extends StatefulWidget {
  const ProfessionalsScreen({super.key});

  @override
  State<ProfessionalsScreen> createState() => _ProfessionalsScreenState();
}

class _ProfessionalsScreenState extends State<ProfessionalsScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Medical / Doctor',
    'Legal / Lawyer',
    'Accounting / Tax',
    'Translators',
    'Caterers',
    'Photographers',
    'Beauty & Style',
    'Services',
  ];

  // ── የተረጋገጡ ባለሙያዎች (Verified Professionals) መረጃ ──
  final List<Map<String, dynamic>> _starterPros = [
    {
      'id': 'starter_dr_selam',
      'title': 'General Practitioner & Pediatrician',
      'name': 'Dr. Selamawit T.',
      'location': 'Paris, France',
      'category': 'Medical / Doctor',
      'rating': '5.0 (210 reviews)',
      'isVerified': true,
      'subscriptionTier': 'vip',
      'phone': 'tel:+33100000000',
      'email': 'dr.selam@eurohabesha.eu',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/33100000000',
      'description': 'Certified Medical Doctor specializing in general practice and pediatrics. Providing culturally understanding medical consultations, check-ups, and pediatric care for the Habesha diaspora.',
      'icon': Icons.medical_services,
      'gallery': [
        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1638202371092-22538cb097f5?auto=format&fit=crop&w=800&q=80',
      ],
      'reviews': [
        {'user': 'Amanuel D.', 'comment': 'Dr. Selam is incredibly caring and professional. Highly recommended!', 'rating': '5.0'},
        {'user': 'Sara M.', 'comment': 'Best pediatrician in Paris. She speaks Amharic and French fluently.', 'rating': '5.0'},
      ]
    },
    {
      'id': 'starter_dawit_law',
      'title': 'Immigration & Corporate Lawyer',
      'name': 'Dawit Legesse Legal Services',
      'location': 'Lyon & Geneva',
      'category': 'Legal / Lawyer',
      'rating': '4.9 (134 reviews)',
      'isVerified': true,
      'subscriptionTier': 'pro',
      'phone': 'tel:+33611223344',
      'email': 'dawit.law@eurohabesha.eu',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/33611223344',
      'description': 'Licensed attorney helping the Habesha community with asylum cases, residency permits, business registration, and corporate law across France and Switzerland.',
      'icon': Icons.gavel,
      'gallery': [
        'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1505664159816-781512bf6df4?auto=format&fit=crop&w=800&q=80',
      ],
      'reviews': [
        {'user': 'Yonas K.', 'comment': 'Helped me get my residence permit smoothly. Very knowledgeable.', 'rating': '5.0'},
      ]
    },
    {
      'id': 'starter_beth_tax',
      'title': 'Certified Accountant & Tax Advisor',
      'name': 'Bethlehem Financials',
      'location': 'Marseille, France',
      'category': 'Accounting / Tax',
      'rating': '4.8 (95 reviews)',
      'isVerified': true,
      'subscriptionTier': null,
      'phone': 'tel:+33400000000',
      'email': 'beth.tax@eurohabesha.eu',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/33400000000',
      'description': 'Professional tax advisory and accounting services for Habesha-owned small businesses, freelancers, and individuals in France.',
      'icon': Icons.account_balance,
      'gallery': [
        'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=800&q=80',
      ],
      'reviews': [
        {'user': 'Getafric Prod.', 'comment': 'Bethlehem handles all our business taxes. 100% accurate and timely!', 'rating': '4.9'},
      ]
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _normalizeDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final raw = doc.data() ?? {};
    final fields = Map<String, dynamic>.from(raw['fields'] ?? {});
    final badgeMap = Map<String, dynamic>.from(raw['verificationBadge'] ?? {});

    final name = fields['title']?.toString().isNotEmpty == true
        ? fields['title'].toString()
        : raw['name']?.toString() ?? raw['title']?.toString() ?? 'Professional';

    final title = fields['professionTitle']?.toString().isNotEmpty == true
        ? fields['professionTitle'].toString()
        : fields['jobCategory']?.toString() ?? raw['title']?.toString() ?? 'Professional Service';

    final location = fields['cityAddress']?.toString().isNotEmpty == true
        ? fields['cityAddress'].toString()
        : raw['location']?.toString() ?? fields['country']?.toString() ?? 'Europe';

    final phone = fields['phoneNumber']?.toString().isNotEmpty == true
        ? fields['phoneNumber'].toString()
        : raw['phone']?.toString() ?? '';

    final email = fields['emailAddress']?.toString().isNotEmpty == true
        ? fields['emailAddress'].toString()
        : raw['email']?.toString() ?? raw['submitterEmail']?.toString() ?? '';

    final website = fields['websiteUrl']?.toString().isNotEmpty == true
        ? fields['websiteUrl'].toString()
        : raw['website']?.toString() ?? '';

    final whatsapp = phone.isNotEmpty ? 'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}' : '';

    final description = fields['description']?.toString().isNotEmpty == true
        ? fields['description'].toString()
        : raw['description']?.toString() ?? fields['servicesOffered']?.toString() ?? '';

    final badge = badgeMap['title']?.toString().isNotEmpty == true
        ? badgeMap['title'].toString()
        : raw['badge']?.toString() ?? 'Verified';

    final galleryList = raw['gallery'] is List
        ? List<String>.from((raw['gallery'] as List).map((e) => e.toString()))
        : <String>[];

    IconData iconData = Icons.medical_services;
    final tLower = title.toLowerCase();
    if (tLower.contains('law') || tLower.contains('legal')) {
      iconData = Icons.gavel;
    } else if (tLower.contains('tax') || tLower.contains('account')) {
      iconData = Icons.account_balance;
    } else if (tLower.contains('translat')) {
      iconData = Icons.translate;
    } else if (tLower.contains('cater') || tLower.contains('injera') || tLower.contains('food')) {
      iconData = Icons.restaurant_menu;
    } else if (tLower.contains('photo') || tLower.contains('video')) {
      iconData = Icons.camera_alt;
    } else if (tLower.contains('design') || tLower.contains('dress')) {
      iconData = Icons.checkroom;
    }

    final isVerified = raw['isVerified'] == true || raw['verificationStatus'] == 'approved';
    final subscriptionTier = raw['subscriptionTier']?.toString();

    return {
      'id': doc.id,
      'name': name,
      'title': title,
      'location': location,
      'category': title,
      'rating': raw['rating']?.toString() ?? '5.0 (New)',
      'badge': badge,
      'isVerified': isVerified,
      'subscriptionTier': subscriptionTier,
      'phone': phone.startsWith('tel:') ? phone : 'tel:$phone',
      'email': email,
      'website': website,
      'whatsapp': whatsapp,
      'description': description,
      'icon': iconData,
      'gallery': galleryList,
      'reviews': raw['reviews'] is List ? raw['reviews'] : [],
      'docRef': doc.reference,
      'ownerId': raw['submittedBy'] ?? raw['ownerId'] ?? '',
    };
  }

  bool _matchesFilter(Map<String, dynamic> pro) {
    if (_selectedCategory != 'All') {
      final proCat = (pro['category'] ?? pro['title'] ?? '').toString().toLowerCase();
      final filterCat = _selectedCategory.toLowerCase();
      if (!proCat.contains(filterCat.split(' ').first)) {
        return false;
      }
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      final name = (pro['name'] ?? '').toString().toLowerCase();
      final loc = (pro['location'] ?? '').toString().toLowerCase();
      final desc = (pro['description'] ?? '').toString().toLowerCase();
      final title = (pro['title'] ?? '').toString().toLowerCase();
      if (!name.contains(query) && !loc.contains(query) && !desc.contains(query) && !title.contains(query)) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text('Trusted Professionals', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: IconThemeData(color: primaryGold),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add, color: primaryGold),
            tooltip: 'Register as Professional',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DynamicSubmissionScreen(type: SubmissionType.professional)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search doctors, lawyers, translators, cities...',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: primaryGold),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: cardGreen,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // ── Category Chips ──
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: primaryGold,
                    backgroundColor: cardGreen,
                    labelStyle: TextStyle(
                      color: isSelected ? primaryDarkGreen : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(color: isSelected ? primaryGold : Colors.white12),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── Stream + Starters ──
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryGold));
                }

                final List<Map<String, dynamic>> combined = [];

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  for (final doc in snapshot.data!.docs) {
                    final data = doc.data();
                    final status = data['status']?.toString() ?? 'published';
                    if (status == 'published' || status == 'approved') {
                      combined.add(_normalizeDoc(doc));
                    }
                  }
                }

                for (final starter in _starterPros) {
                  if (!combined.any((p) => p['id'] == starter['id'] || p['name'] == starter['name'])) {
                    combined.add(starter);
                  }
                }

                final filtered = combined.where(_matchesFilter).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.badge_outlined, color: primaryGold.withOpacity(0.5), size: 56),
                          const SizedBox(height: 12),
                          const Text('No professionals found.', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Register your professional profile today.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const DynamicSubmissionScreen(type: SubmissionType.professional)),
                              );
                            },
                            icon: Icon(Icons.person_add, color: primaryDarkGreen),
                            label: Text('Register as Professional', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final pro = filtered[index];
                    return Card(
                      color: cardGreen,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: primaryGold.withOpacity(0.3), width: 1),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProDetailScreen(proData: pro),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: primaryGold.withOpacity(0.2),
                                child: Icon(pro['icon'] as IconData? ?? Icons.work, color: primaryGold, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            pro['name'] ?? '',
                                            style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    StatusBadgeWidget(
                                      isVerified: pro['isVerified'] == true,
                                      subscriptionTier: pro['subscriptionTier']?.toString(),
                                      compact: true,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(pro['title']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '📍 ${pro['location']} • ⭐ ${pro['rating']}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── 💡 የባለሙያው ዝርዝር ገጽ (Detail Screen with Actions) ──
class ProDetailScreen extends StatelessWidget {
  final Map<String, dynamic> proData;

  const ProDetailScreen({super.key, required this.proData});

  Future<void> _launchUrl(String urlString, {bool isEmail = false, bool isPhone = false}) async {
    final Uri uri = isEmail 
        ? Uri(scheme: 'mailto', path: urlString)
        : isPhone 
            ? Uri.parse(urlString)
            : Uri.parse(urlString);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryDarkGreen = const Color(0xFF061E12);
    final Color primaryGold = const Color(0xFFFFD700);
    final Color cardGreen = const Color(0xFF004D40);

    final List<dynamic> galleryImages = proData['gallery'] ?? [];
    final List<dynamic> reviewsList = proData['reviews'] ?? [];
    final bool isVerified = proData['isVerified'] == true || proData['verificationStatus'] == 'approved';
    final String? subTier = proData['subscriptionTier']?.toString();

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text(proData['name'], style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: IconThemeData(color: primaryGold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. የባለሙያው ስም፣ ርዕስ እና ባጅ ──
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryGold.withOpacity(0.2),
                  child: Icon(proData['icon'], color: primaryGold, size: 35),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(proData['name'], style: TextStyle(color: primaryGold, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      StatusBadgeWidget(isVerified: isVerified, subscriptionTier: subTier),
                      const SizedBox(height: 6),
                      Text(proData['title'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 2. የኮንታክት አዝራሮች ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionBtn(Icons.phone, 'Call', primaryGold, cardGreen, () => _launchUrl(proData['phone'], isPhone: true)),
                _buildActionBtn(Icons.email, 'Email', primaryGold, cardGreen, () => _launchUrl(proData['email'], isEmail: true)),
                _buildActionBtn(Icons.language, 'Website', primaryGold, cardGreen, () => _launchUrl(proData['website'])),
              ],
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuoteRequestScreen(provider: proData))),
                icon: const Icon(Icons.request_quote),
                label: const Text('Request a Quote'),
              ),
            ),
            const SizedBox(height: 20),

            // ── 3. ጋለሪ (Portfolio/Certificates) ──
            if (galleryImages.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Certifications & Office', style: TextStyle(color: primaryGold, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('(${galleryImages.length} Photos)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: galleryImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primaryGold.withOpacity(0.3)),
                        image: DecorationImage(
                          image: NetworkImage(galleryImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),
            ],

            // ── 4. ሙሉ ማብራሪያ (About Professional) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardGreen, 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryGold.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Professional Overview', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(proData['description'], style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFFFD700), size: 15),
                      const SizedBox(width: 4),
                      Text(proData['location'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 20),
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 15),
                      const SizedBox(width: 4),
                      Text(proData['rating'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 5. ሪቪው ──
            Text('Client Reviews', style: TextStyle(color: primaryGold, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...reviewsList.map((rev) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(rev['user'], style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 12)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFD700), size: 13),
                          const SizedBox(width: 3),
                          Text(rev['rating'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(rev['comment'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            )),
            const SizedBox(height: 25),

            // ── 6. የተነጣጠሉ የ WhatsApp እና In-app Chat አዝራሮች ──
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.phone_in_talk, size: 20),
                    label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => _launchUrl(proData['whatsapp']),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGold, 
                      foregroundColor: primaryDarkGreen,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: const Text('In-app Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProDirectChatScreen(
                            chatName: proData['name'], 
                            iconData: proData['icon']
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color goldColor, Color bgColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: goldColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: goldColor, size: 16),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ── 💡 የባለሙያዎች የውስጥ ቻት ገጽ ──
class ProDirectChatScreen extends StatefulWidget {
  final String chatName;
  final IconData iconData;

  const ProDirectChatScreen({super.key, required this.chatName, required this.iconData});

  @override
  State<ProDirectChatScreen> createState() => _ProDirectChatScreenState();
}

class _ProDirectChatScreenState extends State<ProDirectChatScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello! How can I assist you professionally today?',
      'isMe': false,
      'time': 'Online',
    }
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': _messageController.text.trim(),
        'isMe': true,
        'time': 'Now',
      });
    });
    _messageController.clear();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': 'Thank you for your message. I am currently reviewing your request and will reply shortly.',
            'isMe': false,
            'time': 'Now',
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        iconTheme: IconThemeData(color: primaryGold),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: cardGreen,
              child: Icon(widget.iconData, color: primaryGold, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.chatName, style: TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text('Verified Pro • Online', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'];
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? primaryGold : cardGreen,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: Radius.circular(isMe ? 15 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg['text'], style: TextStyle(color: isMe ? primaryDarkGreen : Colors.white, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text(msg['time'], style: TextStyle(color: isMe ? primaryDarkGreen.withOpacity(0.6) : Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardGreen,
              border: Border(top: BorderSide(color: primaryGold.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_file, color: primaryGold),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Message Professional...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: primaryDarkGreen,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    backgroundColor: primaryGold,
                    child: Icon(Icons.send, color: primaryDarkGreen, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
