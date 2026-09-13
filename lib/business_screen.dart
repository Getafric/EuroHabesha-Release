import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_session.dart';
import 'dynamic_submission_screen.dart';
import 'status_badge_widget.dart';

class BusinessDirectoryScreen extends StatefulWidget {
  const BusinessDirectoryScreen({super.key});

  @override
  State<BusinessDirectoryScreen> createState() => _BusinessDirectoryScreenState();
}

class _BusinessDirectoryScreenState extends State<BusinessDirectoryScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterCategories = [
    'All',
    'Restaurants / Food',
    'Hair & Beauty',
    'Grocery & Spices',
    'Shops & Retail',
    'Services',
  ];

  final List<Map<String, dynamic>> _starterBusinesses = [
    {
      'id': 'starter_lucy',
      'title': 'Authentic Ethiopian Cuisine',
      'name': 'Lucy Habesha Restaurant',
      'location': 'Lyon, France',
      'address': '12 Rue de Marseille, 69007 Lyon, France',
      'rating': '4.9 (320 reviews)',
      'isVerified': true,
      'subscriptionTier': 'vip',
      'category': 'Restaurants / Food',
      'businessCategory': 'Restaurants / Food',
      'registration': 'SIRET: 123 456 789 00012',
      'phone': 'tel:+33400000000',
      'email': 'contact@lucyrestaurant.fr',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/33400000000',
      'openingHours': 'Tue - Sun: 12:00 - 23:00',
      'description': 'Experience the best authentic Ethiopian and Eritrean traditional food in Lyon. We offer Injera with various Wots, Tibs, and traditional coffee ceremonies. Officially registered and inspected.',
      'icon': Icons.restaurant,
      'gallery': [
        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1544025162-83569c72f1a6?auto=format&fit=crop&w=800&q=80',
      ],
      'reviews': [
        {'user': 'Miki C.', 'comment': 'Best Kitfo in town! The vibe is amazing and feels like home.', 'rating': '5.0'},
        {'user': 'Sara K.', 'comment': 'Very clean, professional staff, and delicious food.', 'rating': '4.8'},
      ]
    },
    {
      'id': 'starter_konjo',
      'title': 'Unisex Hair Salon & Cosmetics',
      'name': 'Konjo Beauty Salon',
      'location': 'Paris, France',
      'address': '45 Boulevard de Sébastopol, 75001 Paris, France',
      'rating': '4.7 (150 reviews)',
      'isVerified': true,
      'subscriptionTier': 'pro',
      'category': 'Hair & Beauty',
      'businessCategory': 'Hair & Beauty',
      'registration': 'SIREN: 987 654 321',
      'phone': 'tel:+33122334455',
      'email': 'booking@konjosalon.fr',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/33122334455',
      'openingHours': 'Mon - Sat: 09:30 - 19:30',
      'description': 'Professional hair styling, braiding, coloring, and cosmetics store tailored for Habesha men and women. Officially registered salon in the heart of Paris.',
      'icon': Icons.spa,
      'gallery': [
        'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1522337660859-02fbefca4702?auto=format&fit=crop&w=800&q=80',
      ],
      'reviews': [
        {'user': 'Helen T.', 'comment': 'Love my new braids! The staff is officially certified and very polite.', 'rating': '5.0'},
      ]
    },
    {
      'id': 'starter_supermarket',
      'title': 'Grocery & Traditional Spices',
      'name': 'Habesha Supermarket',
      'location': 'Lyon, France',
      'address': '8 Rue Paul Bert, 69003 Lyon, France',
      'rating': '4.8 (85 reviews)',
      'isVerified': true,
      'subscriptionTier': null,
      'category': 'Grocery & Spices',
      'businessCategory': 'Grocery & Spices',
      'registration': 'SIRET: 456 789 123 00045',
      'phone': 'tel:+33411223344',
      'email': 'market@eurohabesha.eu',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/33411223344',
      'openingHours': 'Mon - Sat: 09:00 - 20:00',
      'description': 'Your one-stop shop for Teff, Berbere, Shiro, and imported traditional items. Fresh Injera available every Tuesday and Friday.',
      'icon': Icons.storefront,
      'gallery': [
        'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?auto=format&fit=crop&w=800&q=80',
      ],
      'reviews': [
        {'user': 'Getu A.', 'comment': 'They have everything I need. Very authentic products!', 'rating': '4.9'},
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
        : raw['name']?.toString() ?? raw['title']?.toString() ?? 'Business';

    final category = fields['businessCategory']?.toString().isNotEmpty == true
        ? fields['businessCategory'].toString()
        : raw['businessCategory']?.toString() ?? raw['category']?.toString() ?? 'Restaurants / Food';

    final location = fields['cityAddress']?.toString().isNotEmpty == true
        ? fields['cityAddress'].toString()
        : raw['location']?.toString() ?? fields['country']?.toString() ?? 'Europe';

    final address = fields['address']?.toString().isNotEmpty == true
        ? fields['address'].toString()
        : raw['address']?.toString() ?? location;

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
        : raw['description']?.toString() ?? '';

    final registration = fields['registration']?.toString().isNotEmpty == true
        ? fields['registration'].toString()
        : raw['registration']?.toString() ?? 'SIRET: Verified Business';

    final openingHours = fields['openingHours']?.toString().isNotEmpty == true
        ? fields['openingHours'].toString()
        : raw['openingHours']?.toString() ?? 'Mon - Sun: Open';

    final badge = badgeMap['title']?.toString().isNotEmpty == true
        ? badgeMap['title'].toString()
        : raw['badge']?.toString() ?? 'Verified';

    final galleryList = raw['gallery'] is List
        ? List<String>.from((raw['gallery'] as List).map((e) => e.toString()))
        : <String>[];

    IconData iconData = Icons.storefront;
    final catLower = category.toLowerCase();
    if (catLower.contains('restaurant') || catLower.contains('food') || catLower.contains('injera')) {
      iconData = Icons.restaurant;
    } else if (catLower.contains('hair') || catLower.contains('beauty') || catLower.contains('cosmetic')) {
      iconData = Icons.spa;
    } else if (catLower.contains('grocery') || catLower.contains('market') || catLower.contains('spice')) {
      iconData = Icons.shopping_basket;
    }

    final isVerified = raw['isVerified'] == true || raw['verificationStatus'] == 'approved';
    final subscriptionTier = raw['subscriptionTier']?.toString();

    return {
      'id': doc.id,
      'name': name,
      'title': fields['businessCategory'] ?? raw['title'] ?? category,
      'location': location,
      'address': address,
      'rating': raw['rating']?.toString() ?? '5.0 (New)',
      'badge': badge,
      'isVerified': isVerified,
      'subscriptionTier': subscriptionTier,
      'category': category,
      'businessCategory': category,
      'registration': registration,
      'phone': phone.startsWith('tel:') ? phone : 'tel:$phone',
      'email': email,
      'website': website,
      'whatsapp': whatsapp,
      'openingHours': openingHours,
      'description': description,
      'icon': iconData,
      'gallery': galleryList,
      'reviews': raw['reviews'] is List ? raw['reviews'] : [],
      'docRef': doc.reference,
      'ownerId': raw['submittedBy'] ?? raw['ownerId'] ?? '',
    };
  }

  bool _matchesFilter(Map<String, dynamic> biz) {
    if (_selectedCategory != 'All') {
      final bizCat = (biz['category'] ?? biz['businessCategory'] ?? '').toString().toLowerCase();
      final filterCat = _selectedCategory.toLowerCase();
      if (!bizCat.contains(filterCat.split(' ').first)) {
        return false;
      }
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      final name = (biz['name'] ?? '').toString().toLowerCase();
      final loc = (biz['location'] ?? '').toString().toLowerCase();
      final desc = (biz['description'] ?? '').toString().toLowerCase();
      final cat = (biz['category'] ?? '').toString().toLowerCase();
      if (!name.contains(query) && !loc.contains(query) && !desc.contains(query) && !cat.contains(query)) {
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
        title: Text('Business Directory', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: IconThemeData(color: primaryGold),
        actions: [
          IconButton(
            icon: Icon(Icons.add_business, color: primaryGold),
            tooltip: 'Register Business',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DynamicSubmissionScreen(type: SubmissionType.business)),
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
                hintText: 'Search restaurants, shops, cities...',
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
              itemCount: _filterCategories.length,
              itemBuilder: (context, index) {
                final cat = _filterCategories[index];
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

          // ── Realtime Stream from Firestore + Starters ──
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('businesses').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryGold));
                }

                final List<Map<String, dynamic>> combined = [];

                // 1. Add Firestore approved/published businesses
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  for (final doc in snapshot.data!.docs) {
                    final data = doc.data();
                    final status = data['status']?.toString() ?? 'published';
                    if (status == 'published' || status == 'approved') {
                      combined.add(_normalizeDoc(doc));
                    }
                  }
                }

                // 2. Add starter businesses if not already duplicated by ID
                for (final starter in _starterBusinesses) {
                  if (!combined.any((b) => b['id'] == starter['id'] || b['name'] == starter['name'])) {
                    combined.add(starter);
                  }
                }

                // 3. Filter by search & category
                final filtered = combined.where(_matchesFilter).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront_outlined, color: primaryGold.withOpacity(0.5), size: 56),
                          const SizedBox(height: 12),
                          const Text('No businesses found.', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Try changing the category or search keyword.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const DynamicSubmissionScreen(type: SubmissionType.business)),
                              );
                            },
                            icon: Icon(Icons.add_circle, color: primaryDarkGreen),
                            label: Text('Register a Business', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold)),
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
                    final biz = filtered[index];
                    return Card(
                      color: cardGreen,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: primaryGold.withOpacity(0.25), width: 1),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BusinessDetailScreen(businessData: biz),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryGold.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(biz['icon'] as IconData? ?? Icons.storefront, color: primaryGold, size: 30),
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
                                            biz['name'] ?? 'Business',
                                            style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    StatusBadgeWidget(
                                      isVerified: biz['isVerified'] == true,
                                      subscriptionTier: biz['subscriptionTier']?.toString(),
                                      compact: true,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(biz['title']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '📍 ${biz['location']} • ⭐ ${biz['rating']}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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

// ── 💡 Interactive Full Business Profile Page ──
class BusinessDetailScreen extends StatefulWidget {
  final Map<String, dynamic> businessData;

  const BusinessDetailScreen({super.key, required this.businessData});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  Future<void> _launchUrl(String urlString, {bool isEmail = false, bool isPhone = false}) async {
    if (urlString.isEmpty) return;
    final Uri uri = isEmail
        ? Uri(scheme: 'mailto', path: urlString)
        : isPhone
            ? Uri.parse(urlString.startsWith('tel:') ? urlString : 'tel:$urlString')
            : Uri.parse(urlString.startsWith('http') ? urlString : 'https://$urlString');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openMap(String address) async {
    final cleanAddress = address.trim();
    if (cleanAddress.isEmpty) return;
    final Uri mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(cleanAddress)}');
    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open map.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Map error: $e')));
    }
  }

  void _showWriteReviewDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before submitting a review.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    double selectedStars = 5.0;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: cardGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Rate & Review', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.businessData['name'] ?? 'Business', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starVal = index + 1.0;
                    return IconButton(
                      icon: Icon(
                        starVal <= selectedStars ? Icons.star : Icons.star_border,
                        color: primaryGold,
                        size: 32,
                      ),
                      onPressed: () => setDialogState(() => selectedStars = starVal),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reviewController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Share your experience with this business...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: primaryDarkGreen,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
              onPressed: () async {
                final text = reviewController.text.trim();
                if (text.isEmpty) return;

                final docRef = widget.businessData['docRef'] as DocumentReference<Map<String, dynamic>>?;
                if (docRef != null) {
                  await docRef.collection('reviews').add({
                    'user': user.displayName ?? user.email ?? 'Customer',
                    'userId': user.uid,
                    'rating': selectedStars.toStringAsFixed(1),
                    'comment': text,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }

                if (mounted) {
                  setState(() {
                    (widget.businessData['reviews'] as List).insert(0, {
                      'user': user.displayName ?? user.email ?? 'Customer',
                      'rating': selectedStars.toStringAsFixed(1),
                      'comment': text,
                    });
                  });
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review submitted. Thank you!')),
                  );
                }
              },
              child: Text('Submit Review', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final biz = widget.businessData;
    final List galleryImages = biz['gallery'] is List ? biz['gallery'] : [];
    final List reviewsList = biz['reviews'] is List ? biz['reviews'] : [];
    final String address = biz['address']?.toString() ?? biz['location']?.toString() ?? 'Address available upon contact';
    final String phone = biz['phone']?.toString() ?? '';
    final String email = biz['email']?.toString() ?? '';
    final String website = biz['website']?.toString() ?? '';
    final String whatsapp = biz['whatsapp']?.toString() ?? '';
    final String openingHours = biz['openingHours']?.toString() ?? 'Mon - Sun: Open';

    final bool isVerified = biz['isVerified'] == true || biz['verificationStatus'] == 'approved';
    final String? subTier = biz['subscriptionTier']?.toString();

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text(biz['name'] ?? 'Business Profile', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: IconThemeData(color: primaryGold),
        actions: [
          if (AppSession.isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Delete Business (Admin)',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: cardGreen,
                    title: const Text('Delete Business?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    content: const Text('This will remove this business profile from the directory.', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final docRef = biz['docRef'] as DocumentReference<Map<String, dynamic>>?;
                  if (docRef != null) {
                    await docRef.delete();
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business deleted.')));
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Header with Icon, Name, Badge, SIRET ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(biz['icon'] as IconData? ?? Icons.storefront, color: primaryGold, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(biz['name'] ?? '', style: TextStyle(color: primaryGold, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      StatusBadgeWidget(isVerified: isVerified, subscriptionTier: subTier),
                      const SizedBox(height: 6),
                      if (biz['registration'] != null && biz['registration'].toString().isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.assignment_turned_in, color: Colors.greenAccent, size: 14),
                            const SizedBox(width: 4),
                            Text(biz['registration'].toString(), style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(biz['title']?.toString() ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── 2. Interactive Action Buttons: Call, Email, Website, WhatsApp ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (phone.isNotEmpty)
                  _buildActionBtn(Icons.phone, 'Call', primaryGold, cardGreen, () => _launchUrl(phone, isPhone: true)),
                if (email.isNotEmpty)
                  _buildActionBtn(Icons.email, 'Email', primaryGold, cardGreen, () => _launchUrl(email, isEmail: true)),
                if (website.isNotEmpty)
                  _buildActionBtn(Icons.language, 'Website', primaryGold, cardGreen, () => _launchUrl(website)),
                if (whatsapp.isNotEmpty)
                  _buildActionBtn(Icons.chat, 'WhatsApp', Colors.greenAccent, cardGreen, () => _launchUrl(whatsapp)),
              ],
            ),
            const SizedBox(height: 24),

            // ── 3. Gallery (Photos) ──
            if (galleryImages.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Business Photos & Atmosphere', style: TextStyle(color: primaryGold, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('(${galleryImages.length} Photos)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: galleryImages.length,
                  itemBuilder: (context, index) {
                    final imgUrl = galleryImages[index].toString();
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryGold.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: cardGreen,
                            child: Icon(Icons.photo, color: primaryGold, size: 36),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── 4. About the Business, Location, Opening Hours & Google Maps ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryGold.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About the Business', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    biz['description']?.toString().isNotEmpty == true
                        ? biz['description'].toString()
                        : 'Authentic Habesha business offering quality traditional services and products in Europe.',
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 10),

                  // Opening hours
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFFFFD700), size: 16),
                      const SizedBox(width: 8),
                      Text('Opening Hours: $openingHours', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Address & Google Maps Direction Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFFFD700), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(address, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(Icons.map, color: primaryDarkGreen, size: 18),
                      onPressed: () => _openMap(address),
                      label: Text('Get Directions / Open Google Maps 🗺️', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 5. Customer Reviews ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Customer Reviews', style: TextStyle(color: primaryGold, fontSize: 15, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _showWriteReviewDialog,
                  icon: const Icon(Icons.rate_review, color: Color(0xFFFFD700), size: 16),
                  label: const Text('Write Review', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (reviewsList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(10)),
                child: const Text('No reviews yet. Be the first to leave a review!', style: TextStyle(color: Colors.white54, fontSize: 12)),
              )
            else
              ...reviewsList.map((rev) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardGreen,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(rev['user']?.toString() ?? 'Customer', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 12)),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                                const SizedBox(width: 3),
                                Text(rev['rating']?.toString() ?? '5.0', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(rev['comment']?.toString() ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3)),
                      ],
                    ),
                  )),
            const SizedBox(height: 25),

            // ── 6. Bottom Reservation Action ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGold,
                  foregroundColor: primaryDarkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.phone_in_talk, size: 20),
                label: const Text('Call for Reservation / Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () => _launchUrl(phone, isPhone: true),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color goldColor, Color bgColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: goldColor.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: goldColor, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
