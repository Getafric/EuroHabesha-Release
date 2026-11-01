// Euro Habesha: async profile contexts checked v1
// Euro Habesha: photos et publicites v1
import 'public_profile_photo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import 'package:flutter/material.dart';
import 'business_reviews.dart';

import 'package:url_launcher/url_launcher.dart';

import 'app_session.dart';

import 'dynamic_submission_screen.dart';

import 'status_badge_widget.dart';

import 'business_menu_screen.dart';
import 'professional_capabilities.dart';
import 'chat_screen.dart';
import 'business_profile_sections.dart';
import 'business_public_media.dart';
import 'table_reservation_option.dart';
import 'marketplace_screen.dart';
import 'habesha_connect/habesha_connect_screen.dart';
import 'events_screen.dart';

// Shared mapping: directory and home must open the same full business profile.
Map<String, dynamic> normalizeBusinessForDetail(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final raw = doc.data() ?? {};

  final fields = Map<String, dynamic>.from(raw['fields'] ?? {});

  final badgeMap = Map<String, dynamic>.from(raw['verificationBadge'] ?? {});

  final name = fields['title']?.toString().isNotEmpty == true
      ? fields['title'].toString()
      : raw['name']?.toString() ?? raw['title']?.toString() ?? 'Business';

  final category = fields['businessCategory']?.toString().isNotEmpty == true
      ? fields['businessCategory'].toString()
      : raw['businessCategory']?.toString() ??
            raw['category']?.toString() ??
            'Restaurants / Food';

  final location = fields['cityAddress']?.toString().isNotEmpty == true
      ? fields['cityAddress'].toString()
      : raw['location']?.toString() ??
            fields['country']?.toString() ??
            'Europe';

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

  final whatsapp = phone.isNotEmpty
      ? 'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}'
      : '';

  final description = fields['description']?.toString().isNotEmpty == true
      ? fields['description'].toString()
      : raw['description']?.toString() ?? '';

  final registration = fields['registration']?.toString().isNotEmpty == true
      ? fields['registration'].toString()
      : raw['registration']?.toString() ?? 'SIRET: Verified Business';

  final openingHours = fields['openingHours']?.toString().isNotEmpty == true
      ? fields['openingHours'].toString()
      : raw['openingHours']?.toString() ?? '';

  final badge = badgeMap['title']?.toString().isNotEmpty == true
      ? badgeMap['title'].toString()
      : raw['badge']?.toString() ?? 'Verified';

  final media = BusinessPublicMedia.resolve([raw]);
  final galleryList = media.gallery;
  final logoUrl = media.logo;
  final coverUrl = media.cover;

  IconData iconData = Icons.storefront;

  final catLower = category.toLowerCase();

  if (catLower.contains('restaurant') ||
      catLower.contains('food') ||
      catLower.contains('injera')) {
    iconData = Icons.restaurant;
  } else if (catLower.contains('hair') ||
      catLower.contains('beauty') ||
      catLower.contains('cosmetic')) {
    iconData = Icons.spa;
  } else if (catLower.contains('grocery') ||
      catLower.contains('market') ||
      catLower.contains('spice')) {
    iconData = Icons.shopping_basket;
  }

  final isVerified =
      raw['isVerified'] == true || raw['verificationStatus'] == 'approved';

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

    'logoUrl': logoUrl,

    'coverUrl': coverUrl,

    'reviews': raw['reviews'] is List ? raw['reviews'] : [],

    'docRef': doc.reference,
    // Liens vers la fiche d'origine, conserves pour les reservations.
    'bookingSourceCollection': raw['bookingSourceCollection'],
    'bookingBusinessId': raw['bookingBusinessId'],
    'sourceCollection': raw['sourceCollection'],
    'sourceId': raw['sourceId'],
    'roomLayoutSourceCollection': raw['roomLayoutSourceCollection'],
    'roomLayoutBusinessId': raw['roomLayoutBusinessId'],

    'ownerId': raw['submittedBy'] ?? raw['ownerId'] ?? '',
  };
}

class BusinessDirectoryScreen extends StatefulWidget {
  const BusinessDirectoryScreen({
    super.key,
    this.initialCategory,
    this.initialSearch,
    this.quickFilter,
    this.openBusinessName,
  });

  final String? initialCategory;
  final String? initialSearch;
  final String? quickFilter;
  final String? openBusinessName;

  @override
  State<BusinessDirectoryScreen> createState() =>
      _BusinessDirectoryScreenState();
}

class _BusinessDirectoryScreenState extends State<BusinessDirectoryScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);

  final Color primaryGold = const Color(0xFFFFD700);

  final Color cardGreen = const Color(0xFF004D40);

  String _selectedCategory = 'Tout';

  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final category = widget.initialCategory?.trim() ?? '';
    if (const [
      'Tout',
      'Restaurants',
      'Commerces',
      'Services',
      'Événements',
    ].contains(category)) {
      _selectedCategory = category;
    }
    final search = (widget.initialSearch?.trim().isNotEmpty == true)
        ? widget.initialSearch!.trim()
        : (widget.openBusinessName?.trim() ?? '');
    _searchQuery = search;
    _searchController.text = search;
  }

  final List<String> _filterCategories = [
    'Tout',
    'Restaurants',
    'Commerces',
    'Services',
    'Événements',
    'Habesha Connect',
    'Marketplace',
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

      'description':
          'Experience the best authentic Ethiopian and Eritrean traditional food in Lyon. We offer Injera with various Wots, Tibs, and traditional coffee ceremonies. Officially registered and inspected.',

      'icon': Icons.restaurant,

      'gallery': [
        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=800&q=80',

        'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&w=800&q=80',

        'https://images.unsplash.com/photo-1544025162-83569c72f1a6?auto=format&fit=crop&w=800&q=80',
      ],

      'reviews': [
        {
          'user': 'Miki C.',

          'comment':
              'Best Kitfo in town! The vibe is amazing and feels like home.',

          'rating': '5.0',
        },

        {
          'user': 'Sara K.',

          'comment': 'Very clean, professional staff, and delicious food.',

          'rating': '4.8',
        },
      ],
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

      'description':
          'Professional hair styling, braiding, coloring, and cosmetics store tailored for Habesha men and women. Officially registered salon in the heart of Paris.',

      'icon': Icons.spa,

      'gallery': [
        'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=800&q=80',

        'https://images.unsplash.com/photo-1522337660859-02fbefca4702?auto=format&fit=crop&w=800&q=80',
      ],

      'reviews': [
        {
          'user': 'Helen T.',

          'comment':
              'Love my new braids! The staff is officially certified and very polite.',

          'rating': '5.0',
        },
      ],
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

      'description':
          'Your one-stop shop for Teff, Berbere, Shiro, and imported traditional items. Fresh Injera available every Tuesday and Friday.',

      'icon': Icons.storefront,

      'gallery': [
        'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',

        'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?auto=format&fit=crop&w=800&q=80',
      ],

      'reviews': [
        {
          'user': 'Getu A.',

          'comment': 'They have everything I need. Very authentic products!',

          'rating': '4.9',
        },
      ],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  Map<String, dynamic> _normalizeDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => normalizeBusinessForDetail(doc);

  bool _matchesFilter(Map<String, dynamic> biz) {
    if (_selectedCategory != 'Tout') {
      final cat = (biz['category'] ?? biz['businessCategory'] ?? '')
          .toString()
          .toLowerCase();
      bool ok = false;
      if (_selectedCategory == 'Restaurants') {
        ok = cat.contains('restaurant') || cat.contains('food');
      } else if (_selectedCategory == 'Commerces') {
        ok =
            cat.contains('shop') ||
            cat.contains('retail') ||
            cat.contains('grocery') ||
            cat.contains('market') ||
            cat.contains('spice') ||
            cat.contains('commerce');
      } else if (_selectedCategory == 'Services') {
        ok =
            cat.contains('service') ||
            cat.contains('hair') ||
            cat.contains('beauty') ||
            cat.contains('professional');
      } else if (_selectedCategory == 'Événements') {
        ok = cat.contains('event') || cat.contains('événement');
      }
      if (!ok) return false;
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      final name = (biz['name'] ?? '').toString().toLowerCase();
      final loc = (biz['location'] ?? '').toString().toLowerCase();
      final desc = (biz['description'] ?? '').toString().toLowerCase();
      final cat = (biz['category'] ?? '').toString().toLowerCase();
      if (!name.contains(query) &&
          !loc.contains(query) &&
          !desc.contains(query) &&
          !cat.contains(query)) {
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
        title: Text(
          'Découvrir',

          style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
        ),

        backgroundColor: primaryDarkGreen,

        iconTheme: IconThemeData(color: primaryGold),

        actions: [
          IconButton(
            icon: Icon(Icons.add_business_outlined, color: primaryGold),

            tooltip: 'Ajouter un commerce',

            onPressed: () {
              Navigator.push(
                context,

                MaterialPageRoute(
                  builder: (_) => const DynamicSubmissionScreen(
                    type: SubmissionType.business,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Découvrir',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Trouvez des restaurants, commerces et services près de vous.',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),

            child: TextField(
              controller: _searchController,

              onChanged: (val) => setState(() => _searchQuery = val),

              style: const TextStyle(color: Colors.white),

              decoration: InputDecoration(
                hintText: 'Rechercher un restaurant, service, ville...',

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

                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),

                  borderSide: BorderSide.none,
                ),
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

                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,

                      fontSize: 12,
                    ),

                    side: BorderSide(
                      color: isSelected ? primaryGold : Colors.white12,
                    ),

                    onSelected: (selected) {
                      if (!selected) return;
                      if (cat == 'Marketplace') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MarketplaceScreen(),
                          ),
                        );
                      } else if (cat == 'Habesha Connect') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HabeshaConnectScreen(),
                          ),
                        );
                      } else if (cat == 'Événements') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EventsScreen(),
                          ),
                        );
                      } else {
                        setState(() => _selectedCategory = cat);
                      }
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
              stream: FirebaseFirestore.instance
                  .collection('businesses')
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryGold),
                  );
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
                  if (!combined.any(
                    (b) =>
                        b['id'] == starter['id'] ||
                        b['name'] == starter['name'],
                  )) {
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
                          Icon(
                            Icons.storefront_outlined,

                            color: primaryGold.withValues(alpha: 0.5),

                            size: 56,
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Aucun résultat trouvé.',

                            style: TextStyle(
                              color: Colors.white70,

                              fontSize: 16,

                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            'Essayez une autre catégorie ou une autre recherche.',

                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 16),

                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGold,
                            ),

                            onPressed: () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (_) => const DynamicSubmissionScreen(
                                    type: SubmissionType.business,
                                  ),
                                ),
                              );
                            },

                            icon: Icon(
                              Icons.add_circle,
                              color: primaryDarkGreen,
                            ),

                            label: Text(
                              'Ajouter un commerce',

                              style: TextStyle(
                                color: primaryDarkGreen,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

                        side: BorderSide(
                          color: primaryGold.withValues(alpha: 0.25),

                          width: 1,
                        ),
                      ),

                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),

                        onTap: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (context) =>
                                  BusinessDetailScreen(businessData: biz),
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
                                  color: primaryGold.withValues(alpha: 0.18),

                                  borderRadius: BorderRadius.circular(12),

                                  border: Border.all(
                                    color: primaryGold.withValues(alpha: 0.35),
                                  ),
                                ),

                                clipBehavior: Clip.antiAlias,

                                child:
                                    (biz['logoUrl']
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ??
                                        false)
                                    ? Image.network(
                                        biz['logoUrl'].toString(),

                                        fit: BoxFit.cover,

                                        errorBuilder: (_, __, ___) => Icon(
                                          biz['icon'] as IconData? ??
                                              Icons.storefront,

                                          color: primaryGold,

                                          size: 30,
                                        ),
                                      )
                                    : Icon(
                                        biz['icon'] as IconData? ??
                                            Icons.storefront,

                                        color: primaryGold,

                                        size: 30,
                                      ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,

                                      children: [
                                        Expanded(
                                          child: Text(
                                            biz['name'] ?? 'Business',

                                            style: TextStyle(
                                              color: primaryGold,

                                              fontWeight: FontWeight.bold,

                                              fontSize: 16,
                                            ),

                                            maxLines: 1,

                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        const Icon(
                                          Icons.arrow_forward_ios,

                                          color: Colors.white38,
                                          size: 14,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    StatusBadgeWidget(
                                      isVerified: biz['isVerified'] == true,

                                      subscriptionTier: biz['subscriptionTier']
                                          ?.toString(),

                                      compact: true,
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      biz['title']?.toString() ?? '',

                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      '📍 ${biz['location']} • ⭐ ${biz['rating']}',

                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),

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

  Future<void> _launchUrl(
    String urlString, {
    bool isEmail = false,
    bool isPhone = false,
  }) async {
    if (urlString.isEmpty) return;

    final Uri uri = isEmail
        ? Uri(scheme: 'mailto', path: urlString)
        : isPhone
        ? Uri.parse(urlString.startsWith('tel:') ? urlString : 'tel:$urlString')
        : Uri.parse(
            urlString.startsWith('http') ? urlString : 'https://$urlString',
          );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _openMap(String address) async {
    final cleanAddress = address.trim();

    if (cleanAddress.isEmpty) return;

    final Uri mapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(cleanAddress)}',
    );

    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open map.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Map error: $e')));
      }
    }
  }

  // EH_CADRAGE_AVIS_V1
  void _showWriteReviewDialog() {
    showBusinessReviewDialog(context, widget.businessData);
  }

  @override
  Widget build(BuildContext context) => BusinessProfileMediaView(
    data: widget.businessData,
    builder: _buildProfile,
  );

  Widget _buildProfile(BuildContext context, BusinessPublicMedia media) {
    final biz = widget.businessData;

    final galleryImages = media.gallery;
    final cover = media.cover;

final String address =
        biz['address']?.toString() ??
        biz['location']?.toString() ??
        'Address available upon contact';

    final String phone = biz['phone']?.toString() ?? '';

    final String email = biz['email']?.toString() ?? '';

    final String website = biz['website']?.toString() ?? '';

    final String whatsapp = biz['whatsapp']?.toString() ?? '';

    final String openingHours = biz['openingHours']?.toString() ?? '';

    final bool isVerified =
        biz['isVerified'] == true || biz['verificationStatus'] == 'approved';

    final String? subTier = biz['subscriptionTier']?.toString();

    final categoryForShop = (biz['category'] ?? biz['businessCategory'] ?? '')
        .toString()
        .toLowerCase();
    final isFoodBusiness =
        categoryForShop.contains('restaurant') ||
        categoryForShop.contains('food') ||
        categoryForShop.contains('catering');
    // Booking is available only for service businesses with a real Firestore profile.
    final businessDocRef =
        biz['docRef'] is DocumentReference<Map<String, dynamic>>
        ? biz['docRef'] as DocumentReference<Map<String, dynamic>>
        : null;
    final sourceLink = professionalSource(biz, reference: businessDocRef);
    final bookingCollection = sourceLink?.collection ?? '';
    final bookingId = sourceLink?.id ?? '';
    final shopButtonLabel = isFoodBusiness
        ? 'Voir le menu'
        : 'Voir les produits et services';
    final shopButtonIcon = isFoodBusiness
        ? Icons.restaurant_menu
        : Icons.storefront_outlined;

    return ProfessionalCapabilitiesView(
      source: sourceLink,
      fallback: biz,
      legacyOrders: true,
      builder: (context, actions) => Scaffold(
        backgroundColor: primaryDarkGreen,

        appBar: AppBar(
          title: Text(
            biz['name'] ?? 'Business Profile',

            style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
          ),

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

                      title: const Text(
                        'Delete Business?',

                        style: TextStyle(
                          color: Colors.redAccent,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      content: const Text(
                        'This will remove this business profile from the directory.',

                        style: TextStyle(color: Colors.white70),
                      ),

                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),

                          child: const Text('Cancel'),
                        ),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),

                          onPressed: () => Navigator.pop(ctx, true),

                          child: const Text(
                            'Delete',

                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final docRef =
                        biz['docRef']
                            as DocumentReference<Map<String, dynamic>>?;

                    if (docRef != null) {
                      await docRef.delete();
                    }

                    if (mounted && context.mounted) {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Business deleted.')),
                      );
                    }
                  }
                },
              ),
          ],
        ),

        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            24 + MediaQuery.of(context).viewPadding.bottom,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // Public profile cover and identity.
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: double.infinity,
                  height: cover.isEmpty ? 120 : 190,
                  child: PublicProfilePhoto(
                    urls: media.covers,
                    semanticLabel: 'Photo de couverture de l’établissement',
                    fallback: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF123629), Color(0xFF004D40)],
                        ),
                      ),
                      child: Icon(
                        biz['icon'] as IconData? ?? Icons.storefront,
                        color: primaryGold,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: cardGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryGold.withValues(alpha: .6),
                      ),
                    ),
                    child: BusinessProfileImage(
                      urls: media.logos,
                      semanticLabel: 'Logo de l’établissement',
                      fallback: Icon(
                        biz['icon'] as IconData? ?? Icons.storefront,
                        color: primaryGold,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          biz['name']?.toString() ?? '',
                          style: TextStyle(
                            color: primaryGold,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          biz['title']?.toString() ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          biz['location']?.toString() ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StatusBadgeWidget(
                          isVerified: isVerified,
                          subscriptionTier: subTier,
                        ),
                        if (biz['registration']?.toString().trim().isNotEmpty ??
                            false)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              biz['registration'].toString(),
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── 2. Interactive Action Buttons: Call, Email, Website, WhatsApp ──
              if (actions.contact)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,

                  children: [
                    if (phone.isNotEmpty)
                      _buildActionBtn(
                        Icons.phone,
                        'Appeler',
                        primaryGold,
                        cardGreen,

                        () => _launchUrl(phone, isPhone: true),
                      ),

                    if (email.isNotEmpty)
                      _buildActionBtn(
                        Icons.email,
                        'E-mail',
                        primaryGold,
                        cardGreen,

                        () => _launchUrl(email, isEmail: true),
                      ),

                    if (website.isNotEmpty)
                      _buildActionBtn(
                        Icons.language,
                        'Site web',
                        primaryGold,

                        cardGreen,
                        () => _launchUrl(website),
                      ),

                    if (whatsapp.isNotEmpty)
                      _buildActionBtn(
                        Icons.chat,
                        'WhatsApp',
                        primaryGold,

                        cardGreen,
                        () => _launchUrl(whatsapp),
                      ),
                  ],
                ),

              const SizedBox(height: 24),

              PublicTableReservationAction(
                sourceCollection: bookingCollection,
                businessId: bookingId,
                businessName: biz['name']?.toString() ?? 'Établissement',
              ),

              PublicAppointmentAction(
                source: sourceLink,
                businessName: biz['name']?.toString() ?? 'Établissement',
                enabled: actions.appointments,
              ),
              if (actions.chat)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryGold,
                        foregroundColor: primaryDarkGreen,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Discuter'),
                      onPressed: () => openDirectChat(
                        context: context,
                        otherUserId:
                            [
                                  biz['ownerId'],
                                  biz['submittedBy'],
                                  biz['creatorId'],
                                ]
                                .map((value) => value?.toString().trim() ?? '')
                                .firstWhere(
                                  (value) => value.isNotEmpty,
                                  orElse: () => '',
                                ),
                        otherUserName:
                            biz['name']?.toString() ?? 'Professionnel',
                        professionalSourceCollection: sourceLink?.collection,
                        professionalBusinessId: sourceLink?.id,
                      ),
                    ),
                  ),
                ),
              if (biz['docRef'] is DocumentReference<Map<String, dynamic>>) ...[
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      final docRef =
                          biz['docRef']
                              as DocumentReference<Map<String, dynamic>>;

                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (context) => BusinessMenuScreen(
                            businessId: sourceLink?.id ?? docRef.id,
                            sourceCollection:
                                sourceLink?.collection ?? 'businessSubmissions',

                            businessName: biz['name']?.toString() ?? 'Business',
                          ),
                        ),
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGold,

                      foregroundColor: primaryDarkGreen,

                      padding: const EdgeInsets.symmetric(vertical: 15),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    icon: Icon(shopButtonIcon),
                    label: Text(
                      actions.orders && isFoodBusiness
                          ? 'Voir le menu / Commander'
                          : shopButtonLabel,

                      style: const TextStyle(
                        fontSize: 15,

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],

              BusinessProfileCard(
                icon: Icons.description_outlined,
                title: 'À propos',
                child: Text(
                  biz['description']?.toString().trim().isNotEmpty == true
                      ? biz['description'].toString()
                      : 'Description non renseignée.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              BusinessProfileHours(raw: openingHours),
              const SizedBox(height: 14),
              if (galleryImages.isNotEmpty) ...[
                BusinessProfileGallery(photos: galleryImages),
                const SizedBox(height: 14),
              ],
              BusinessProfileCard(
                icon: Icons.location_on_outlined,
                title: 'Adresse',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectableText(
                      address,
                      style: const TextStyle(color: Colors.white, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryGold,
                        side: BorderSide(color: primaryGold),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _openMap(address),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Itinéraire'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 5. Customer Reviews ──
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,

                children: [
                  Text(
                    'Avis clients',

                    style: TextStyle(
                      color: primaryGold,

                      fontSize: 15,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  TextButton.icon(
                    onPressed: _showWriteReviewDialog,

                    icon: const Icon(
                      Icons.rate_review,

                      color: Color(0xFFFFD700),
                      size: 16,
                    ),

                    label: const Text(
                      'Donner un avis',

                      style: TextStyle(
                        color: Color(0xFFFFD700),

                        fontSize: 12,

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              BusinessReviewsList(data: biz),

              const SizedBox(height: 25),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn(
    IconData icon,
    String label,
    Color goldColor,

    Color bgColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(12),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

        decoration: BoxDecoration(
          color: bgColor,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(color: goldColor.withValues(alpha: 0.5)),
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(icon, color: goldColor, size: 20),

            const SizedBox(height: 4),

            Text(
              label,

              style: TextStyle(
                color: goldColor,

                fontWeight: FontWeight.bold,

                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
