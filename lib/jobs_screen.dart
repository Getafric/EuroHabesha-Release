import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cash_on_delivery_order_screen.dart';
import 'dynamic_submission_screen.dart';
import 'status_badge_widget.dart';
import 'chat_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  // ── የቢዝነሶች እና የሰርቪስ አቅራቢዎች የተሟላ መረጃ ──
  final List<Map<String, dynamic>> _starterJobs = [
    {
      'id': 'starter_photo',
      'title': 'Professional Photographer & Videographer',
      'name': 'Getafric Production',
      'location': 'Lyon, France',
      'rating': '4.9 (140 reviews)',
      'phone': 'tel:+33600000000',
      'email': 'getafric@eurohabesha.eu',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/33600000000',
      'description':
          'Professional wedding, commercial, and event photography and videography services using Canon EOS 90D and DJI RS 3 Pro equipment across Europe. Capturing your best moments with high-end cinematic quality.',
      'icon': Icons.camera_alt,
      'gallery': [
        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1537633552985-df8429e8048b?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1520854221256-17451cc331bf?auto=format&fit=crop&w=800&q=80',
      ],
      'reviews': [
        {
          'user': 'Dawit M.',
          'comment':
              'Amazing photography work in Lyon! Very professional equipment and great quality.',
          'rating': '5.0'
        },
        {
          'user': 'Hermela T.',
          'comment':
              'Getafric Production covered our wedding event. Highly recommended across France!',
          'rating': '4.8'
        },
      ]
    },
    {
      'id': 'starter_translator',
      'title': 'Translator - Amharic / Tigrinya / French',
      'name': 'Selam Translation Services',
      'location': 'Brussels, Belgium',
      'rating': '4.9 (62 reviews)',
      'phone': 'tel:+3220000000',
      'email': 'translator@eurohabesha.eu',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/3220000000',
      'description':
          'Certified translation for phone calls, appointments, legal letters, and documents. Rates available per hour or per paper.',
      'icon': Icons.translate,
      'serviceType': 'translator',
      'ratePerHour': '€25/hour',
      'ratePerDocument': 'From €30/document',
      'gallery': [],
      'reviews': [
        {
          'user': 'Mebratu K.',
          'comment': 'Very clear and professional translation support.',
          'rating': '5.0'
        },
      ]
    },
    {
      'id': 'starter_designer',
      'title': 'Fashion / Clothes Designer',
      'name': 'Marta Habesha Design',
      'location': 'Frankfurt, Germany',
      'rating': '5.0 (44 reviews)',
      'phone': 'tel:+4915123456789',
      'email': 'designer@eurohabesha.eu',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/4915123456789',
      'description':
          'Custom Habesha Kemis, modern cultural dresses, wedding outfits, and made-to-measure clothing. Orders are paid on delivery or arrival.',
      'icon': Icons.checkroom,
      'serviceType': 'designer',
      'gallery': [
        'https://images.unsplash.com/photo-1583391733958-d15317a86976?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=800&q=80',
      ],
      'reviews': [
        {
          'user': 'Sara T.',
          'comment': 'Beautiful custom dress and perfect fitting.',
          'rating': '5.0'
        },
      ]
    },
    {
      'id': 'starter_catering',
      'title': 'Catering / Injera & Wot Seller',
      'name': 'Taitu Habesha Catering',
      'location': 'Lyon, France',
      'rating': '4.8 (91 reviews)',
      'phone': 'tel:+33622334455',
      'email': 'catering@eurohabesha.eu',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/33622334455',
      'description':
          'Fresh injera, doro wot, tibs, vegan platters, and event catering. Orders are cash on delivery or pay on arrival only.',
      'icon': Icons.restaurant_menu,
      'serviceType': 'catering',
      'depositPercentage': 50,
      'menuItems': [
        {'name': 'Injera pack', 'price': '€10'},
        {'name': 'Doro Wot', 'price': '€18'},
        {'name': 'Tibs Tray', 'price': '€25'},
      ],
      'gallery': [
        'https://images.unsplash.com/photo-1544025162-83569c72f1a6?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=800&q=80',
      ],
      'reviews': [
        {
          'user': 'Dawit A.',
          'comment': 'Fresh injera and fast delivery.',
          'rating': '4.8'
        },
      ]
    },
  ];

  Map<String, dynamic> _normalizeDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final raw = doc.data() ?? {};
    final fields = Map<String, dynamic>.from(raw['fields'] ?? {});

    final name = fields['title']?.toString().isNotEmpty == true
        ? fields['title'].toString()
        : raw['name']?.toString() ??
            raw['title']?.toString() ??
            'Job / Service';

    final title = fields['jobCategory']?.toString().isNotEmpty == true
        ? fields['jobCategory'].toString()
        : raw['title']?.toString() ?? 'Service';

    final location = fields['cityAddress']?.toString().isNotEmpty == true
        ? fields['cityAddress'].toString()
        : raw['location']?.toString() ??
            fields['country']?.toString() ??
            'Europe';

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
        : raw['description']?.toString() ??
            fields['requirements']?.toString() ??
            '';
    final logoUrl = (fields['logoUrl'] ??
            fields['imageUrl'] ??
            fields['photoUrl'] ??
            fields['businessLogoUrl'] ??
            raw['logoUrl'] ??
            raw['imageUrl'] ??
            raw['photoUrl'] ??
            raw['businessLogoUrl'] ??
            raw['profileImageUrl'] ??
            '')
        .toString()
        .trim();

    final coverUrl = (fields['coverUrl'] ??
            fields['coverImageUrl'] ??
            raw['coverUrl'] ??
            raw['coverImageUrl'] ??
            '')
        .toString()
        .trim();
    final serviceType = fields['jobCategory']
                ?.toString()
                .toLowerCase()
                .contains('cater') ==
            true
        ? 'catering'
        : fields['jobCategory']?.toString().toLowerCase().contains('design') ==
                true
            ? 'designer'
            : fields['jobCategory']
                        ?.toString()
                        .toLowerCase()
                        .contains('translat') ==
                    true
                ? 'translator'
                : raw['serviceType']?.toString() ?? 'service';

    final double deposit = (raw['orderingModel'] is Map &&
            raw['orderingModel']['depositPercentage'] != null)
        ? ((raw['orderingModel']['depositPercentage'] as num).toDouble())
        : (raw['depositPercentage'] as num?)?.toDouble() ?? 0;

    final isVerified =
        raw['isVerified'] == true || raw['verificationStatus'] == 'approved';
    final subscriptionTier = raw['subscriptionTier']?.toString();

    return {
      'id': doc.id,
      'submittedBy': raw['submittedBy']?.toString() ?? '',
      'ownerId': raw['ownerId']?.toString() ?? '',
      'creatorId': raw['creatorId']?.toString() ?? '',
      'name': name,
      'title': title,
      'location': location,
      'logoUrl': logoUrl,
      'coverUrl': coverUrl,
      'rating': raw['rating']?.toString() ?? '5.0 (New)',
      'isVerified': isVerified,
      'subscriptionTier': subscriptionTier,
      'phone': phone.startsWith('tel:') ? phone : 'tel:$phone',
      'email': email,
      'website': website,
      'whatsapp': whatsapp,
      'description': description,
      'icon': serviceType == 'catering'
          ? Icons.restaurant_menu
          : serviceType == 'designer'
              ? Icons.checkroom
              : serviceType == 'translator'
                  ? Icons.translate
                  : Icons.work,
      'serviceType': serviceType,
      'depositPercentage': deposit,
      'menuItems': raw['menuItems'] is List ? raw['menuItems'] : [],
      'gallery': raw['gallery'] is List ? raw['gallery'] : [],
      'reviews': raw['reviews'] is List ? raw['reviews'] : [],
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
      builder: (context, snapshot) {
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

        for (final starter in _starterJobs) {
          if (!combined.any((j) =>
              j['id'] == starter['id'] || j['name'] == starter['name'])) {
            combined.add(starter);
          }
        }

        return Scaffold(
          backgroundColor: primaryDarkGreen,
          appBar: AppBar(
            title: Text('Jobs & Services',
                style:
                    TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
            backgroundColor: primaryDarkGreen,
            iconTheme: IconThemeData(color: primaryGold),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search services',
                onPressed: () async {
                  final selected = await showSearch<Map<String, dynamic>?>(
                    context: context,
                    delegate: _ServiceSearchDelegate(combined),
                  );
                  if (!context.mounted || selected == null) return;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => JobDetailScreen(jobData: selected)));
                },
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: primaryGold),
                tooltip: 'Post a Job or Service',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DynamicSubmissionScreen(
                            type: SubmissionType.job)),
                  );
                },
              ),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: combined.length,
            itemBuilder: (context, index) {
              final job = combined[index];
              return Card(
                color: cardGreen,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: primaryGold.withValues(alpha: 0.3), width: 1),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 52,
                    height: 52,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: primaryDarkGreen,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryGold.withValues(alpha: 0.45),
                      ),
                    ),
                    child:
                        (job['logoUrl']?.toString().trim().isNotEmpty ?? false)
                            ? Image.network(
                                job['logoUrl'].toString(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  job['icon'] as IconData? ?? Icons.work,
                                  color: primaryGold,
                                  size: 27,
                                ),
                              )
                            : Icon(
                                job['icon'] as IconData? ?? Icons.work,
                                color: primaryGold,
                                size: 27,
                              ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(job['name'] ?? '',
                            style: TextStyle(
                                color: primaryGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                      StatusBadgeWidget(
                        isVerified: job['isVerified'] == true,
                        subscriptionTier: job['subscriptionTier']?.toString(),
                        compact: true,
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${job['title']}\n📍 ${job['location']} • ⭐ ${job['rating']}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: primaryGold,
                    size: 14,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobDetailScreen(jobData: job),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ServiceSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  final List<Map<String, dynamic>> services;

  _ServiceSearchDelegate(this.services);

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
              icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildMatches(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildMatches(context);

  Widget _buildMatches(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final matches = services.where((service) {
      if (normalized.isEmpty) return true;
      final searchable =
          '${service['name']} ${service['title']} ${service['location']} ${service['serviceType'] ?? ''}'
              .toLowerCase();
      return searchable.contains(normalized);
    }).toList();

    if (matches.isEmpty) {
      return const Center(child: Text('No caterers or services found.'));
    }

    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final service = matches[index];
        return ListTile(
          leading: Container(
            width: 46,
            height: 46,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF061E12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.35),
              ),
            ),
            child: (service['logoUrl']?.toString().trim().isNotEmpty ?? false)
                ? Image.network(
                    service['logoUrl'].toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      service['icon'] as IconData? ?? Icons.work,
                      color: const Color(0xFFFFD700),
                      size: 25,
                    ),
                  )
                : Icon(
                    service['icon'] as IconData? ?? Icons.work,
                    color: const Color(0xFFFFD700),
                    size: 25,
                  ),
          ),
          title: Text(service['name'].toString()),
          subtitle: Text('${service['title']} • ${service['location']}'),
          onTap: () => close(context, service),
        );
      },
    );
  }
}

// ── 💡 የተሟላ የቢዝነስ/ሰርቪስ ዲቴይል ገጽ ──
class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> jobData;

  const JobDetailScreen({
    super.key,
    required this.jobData,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final Map<int, int> _cartQuantities = {};

  Map<String, dynamic> get jobData => widget.jobData;

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  String _text(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  List<dynamic> _list(dynamic value) {
    return value is List ? value : <dynamic>[];
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  double _price(dynamic value) {
    return double.tryParse(
          _text(value, '0').replaceAll('€', '').replaceAll(',', '.').trim(),
        ) ??
        0;
  }

  IconData _serviceIcon(String serviceType) {
    final dynamic storedIcon = jobData['icon'];

    if (storedIcon is IconData) {
      return storedIcon;
    }

    switch (serviceType) {
      case 'catering':
        return Icons.restaurant_menu;
      case 'designer':
        return Icons.checkroom;
      case 'translator':
        return Icons.translate;
      default:
        return Icons.work_outline;
    }
  }

  Future<void> _launchUrl(
    String value, {
    bool isEmail = false,
    bool isPhone = false,
  }) async {
    final cleaned = value.trim();

    if (cleaned.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette information n’est pas disponible.'),
        ),
      );
      return;
    }

    Uri uri;

    if (isEmail) {
      uri = Uri(
        scheme: 'mailto',
        path: cleaned,
      );
    } else if (isPhone) {
      final phone = cleaned.startsWith('tel:') ? cleaned.substring(4) : cleaned;

      uri = Uri(
        scheme: 'tel',
        path: phone,
      );
    } else {
      uri = Uri.parse(cleaned);
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = _text(
      jobData['name'],
      'Professionnel',
    );

    final String title = _text(
      jobData['title'],
      'Service professionnel',
    );

    final String description = _text(
      jobData['description'],
      'Aucune description disponible.',
    );

    final String location = _text(
      jobData['location'],
      'Europe',
    );

    final String rating = _text(
      jobData['rating'],
      '5.0 (New)',
    );

    final String phone = _text(jobData['phone']);
    final String email = _text(jobData['email']);
    final String website = _text(jobData['website']);
    final String whatsapp = _text(jobData['whatsapp']);

    final String serviceType =
        _text(jobData['serviceType'], 'service').toLowerCase();

    final String logoUrl = _text(jobData['logoUrl']);
    final String coverUrl = _text(jobData['coverUrl']);

    final IconData icon = _serviceIcon(serviceType);

    final List<dynamic> galleryImages = _list(jobData['gallery']);

    final List<dynamic> reviewsList = _list(jobData['reviews']);

    final List<dynamic> menuItems = _list(jobData['menuItems']);

    final bool isVerified = jobData['isVerified'] == true ||
        jobData['verificationStatus'] == 'approved';

    final String? subTier = jobData['subscriptionTier']?.toString();

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text(
          name,
          style: const TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        iconTheme: const IconThemeData(
          color: primaryGold,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBusinessHeader(
              name: name,
              title: title,
              location: location,
              logoUrl: logoUrl,
              coverUrl: coverUrl,
              icon: icon,
              isVerified: isVerified,
              subscriptionTier: subTier,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                24,
                16,
                30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactButtons(
                    phone: phone,
                    email: email,
                    website: website,
                  ),
                  const SizedBox(height: 22),
                  _buildAboutCard(
                    description: description,
                    location: location,
                    rating: rating,
                  ),
                  if (serviceType == 'translator') ...[
                    const SizedBox(height: 20),
                    _buildServiceInfoCard(
                      [
                        'Rate per hour: ${_text(jobData['ratePerHour'], 'À définir')}',
                        'Rate per document: ${_text(jobData['ratePerDocument'], 'À définir')}',
                        'Service type: In-person or Phone',
                      ],
                      cardGreen,
                      primaryGold,
                    ),
                  ],
                  if (serviceType == 'catering') ...[
                    const SizedBox(height: 22),
                    _buildMenuCard(
                      menuItems,
                      cardGreen,
                      primaryGold,
                    ),
                  ],
                  if (galleryImages.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildGallery(galleryImages),
                  ],
                  const SizedBox(height: 24),
                  _buildReviews(reviewsList),
                  const SizedBox(height: 24),
                  _buildCommunicationButtons(
                    name: name,
                    icon: icon,
                    whatsapp: whatsapp,
                  ),
                  if (serviceType == 'designer' ||
                      serviceType == 'catering') ...[
                    const SizedBox(height: 12),
                    _buildOrderButton(
                      serviceType: serviceType,
                      title: title,
                      sellerName: name,
                      sellerContact: phone,
                      menuItems: menuItems,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHeader({
    required String name,
    required String title,
    required String location,
    required String logoUrl,
    required String coverUrl,
    required IconData icon,
    required bool isVerified,
    required String? subscriptionTier,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00695C),
                    Color(0xFF003D33),
                  ],
                ),
                image: coverUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(coverUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: coverUrl.isEmpty
                  ? const Icon(
                      Icons.storefront,
                      color: Colors.white12,
                      size: 75,
                    )
                  : null,
            ),
            Positioned(
              bottom: -52,
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardGreen,
                  border: Border.all(
                    color: primaryGold,
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 14,
                    ),
                  ],
                  image: logoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(logoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: logoUrl.isEmpty
                    ? Icon(
                        icon,
                        color: primaryGold,
                        size: 48,
                      )
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 66),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: primaryGold,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 7),
                    const Icon(
                      Icons.verified,
                      color: primaryGold,
                      size: 21,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: primaryGold,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      location,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (subscriptionTier != null &&
                  subscriptionTier.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                StatusBadgeWidget(
                  isVerified: isVerified,
                  subscriptionTier: subscriptionTier,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactButtons({
    required String phone,
    required String email,
    required String website,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildContactActionButton(
            Icons.phone,
            'Appeler',
            primaryGold,
            cardGreen,
            () => _launchUrl(
              phone,
              isPhone: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildContactActionButton(
            Icons.email_outlined,
            'E-mail',
            primaryGold,
            cardGreen,
            () => _launchUrl(
              email,
              isEmail: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildContactActionButton(
            Icons.language,
            'Site',
            primaryGold,
            cardGreen,
            () => _launchUrl(website),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard({
    required String description,
    required String location,
    required String rating,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryGold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À propos',
            style: TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: primaryGold,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    color: primaryGold,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(List<dynamic> galleryImages) {
    final images =
        galleryImages.map((e) => _text(e)).where((e) => e.isNotEmpty).toList();

    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Galerie (${images.length})',
          style: const TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 125,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  images[index],
                  width: 155,
                  height: 125,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 155,
                      color: cardGreen,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white38,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviews(List<dynamic> reviewsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avis clients',
          style: TextStyle(
            color: primaryGold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (reviewsList.isEmpty)
          const Text(
            'Aucun avis pour le moment.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          )
        else
          ...reviewsList.map((rawReview) {
            final review = _map(rawReview);

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _text(
                            review['user'],
                            'Utilisateur',
                          ),
                          style: const TextStyle(
                            color: primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.star,
                        color: primaryGold,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _text(
                          review['rating'],
                          '5.0',
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _text(
                      review['comment'],
                      'Aucun commentaire.',
                    ),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCommunicationButtons({
    required String name,
    required IconData icon,
    required String whatsapp,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(
              Icons.phone_in_talk,
              size: 20,
            ),
            label: const Text(
              'WhatsApp',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            onPressed: () {
              _launchUrl(whatsapp);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
              foregroundColor: primaryDarkGreen,
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(
              Icons.chat_bubble_outline,
              size: 20,
            ),
            label: const Text(
              'Chat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            onPressed: () async {
              final ownerId = _text(jobData['submittedBy']).isNotEmpty
                  ? _text(jobData['submittedBy'])
                  : _text(jobData['ownerId']).isNotEmpty
                      ? _text(jobData['ownerId'])
                      : _text(jobData['creatorId']);

              await openDirectChat(
                context: context,
                otherUserId: ownerId,
                otherUserName: name,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderButton({
    required String serviceType,
    required String title,
    required String sellerName,
    required String sellerContact,
    required List<dynamic> menuItems,
  }) {
    final bool isCatering = serviceType == 'catering';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: primaryDarkGreen,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(
          isCatering ? Icons.delivery_dining : Icons.straighten,
        ),
        label: Text(
          isCatering ? 'Commander' : 'Envoyer une commande personnalisée',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        onPressed: () {
          final List<Map<String, dynamic>> selectedItems = [];

          double cartTotal = 0;

          if (isCatering) {
            for (int i = 0; i < menuItems.length; i++) {
              final quantity = _cartQuantities[i] ?? 0;

              if (quantity <= 0) {
                continue;
              }

              final item = _map(menuItems[i]);

              final unitPrice = _price(item['price']);

              final lineTotal = unitPrice * quantity;

              selectedItems.add({
                'name': _text(
                  item['name'],
                  'Article',
                ),
                'unitPrice': unitPrice,
                'quantity': quantity,
                'total': lineTotal,
                'imageUrl': _text(item['imageUrl']),
              });

              cartTotal += lineTotal;
            }

            if (selectedItems.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Veuillez choisir au moins un article.',
                  ),
                ),
              );
              return;
            }
          }

          final String sellerId = _text(jobData['submittedBy']).isNotEmpty
              ? _text(jobData['submittedBy'])
              : _text(jobData['ownerId']).isNotEmpty
                  ? _text(jobData['ownerId'])
                  : _text(jobData['creatorId']);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CashOnDeliveryOrderScreen(
                itemType: serviceType,
                itemTitle: title,
                sellerName: sellerName,
                sellerContact: sellerContact,
                sellerId: sellerId,
                price: isCatering
                    ? '€${cartTotal.toStringAsFixed(2)}'
                    : 'Custom quote',
                sourceData: jobData,
                depositPercentage:
                    (jobData['depositPercentage'] as num?)?.toDouble() ?? 0,
                cartItems: selectedItems,
                cartTotal: cartTotal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactActionButton(
    IconData icon,
    String label,
    Color goldColor,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: goldColor.withValues(
              alpha: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: goldColor,
              size: 16,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: goldColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfoCard(
    List<String> lines,
    Color bgColor,
    Color goldColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tarifs',
            style: TextStyle(
              color: goldColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 4,
              ),
              child: Text(
                line,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    List<dynamic> items,
    Color bgColor,
    Color goldColor,
  ) {
    int totalItems = 0;
    double totalPrice = 0;

    for (int i = 0; i < items.length; i++) {
      final item = _map(items[i]);

      final quantity = _cartQuantities[i] ?? 0;

      totalItems += quantity;

      totalPrice += _price(item['price']) * quantity;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Aucun produit disponible pour le moment.',
              style: TextStyle(
                color: Colors.white54,
              ),
            ),
          )
        else
          for (int i = 0; i < items.length; i++)
            _buildMenuItem(
              index: i,
              item: _map(items[i]),
              goldColor: goldColor,
            ),
        if (totalItems > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: goldColor.withValues(
                  alpha: 0.35,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: goldColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$totalItems article${totalItems > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '€${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: goldColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMenuItem({
    required int index,
    required Map<String, dynamic> item,
    required Color goldColor,
  }) {
    final String name = _text(item['name'], 'Article');

    final String description = _text(item['description']);

    final String imageUrl = _text(item['imageUrl']);

    final double price = _price(item['price']);

    final bool available = item['isAvailable'] != false;

    final int quantity = _cartQuantities[index] ?? 0;

    return Opacity(
      opacity: available ? 1 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardGreen,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: goldColor.withValues(
              alpha: 0.25,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 82,
                      height: 82,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return _menuPlaceholder();
                      },
                    )
                  : _menuPlaceholder(),
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
                      fontSize: 14,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '€${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: goldColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (!available)
                        const Text(
                          'Indisponible',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  if (available) ...[
                    const SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: quantity <= 0
                              ? null
                              : () {
                                  setState(() {
                                    if (quantity <= 1) {
                                      _cartQuantities.remove(index);
                                    } else {
                                      _cartQuantities[index] = quantity - 1;
                                    }
                                  });
                                },
                          icon: const Icon(
                            Icons.remove_circle_outline,
                          ),
                          color: goldColor,
                          disabledColor: Colors.white24,
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setState(() {
                              _cartQuantities[index] = quantity + 1;
                            });
                          },
                          icon: const Icon(
                            Icons.add_circle,
                          ),
                          color: goldColor,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuPlaceholder() {
    return Container(
      width: 82,
      height: 82,
      color: const Color(0xFF073C31),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_menu,
        color: primaryGold,
        size: 31,
      ),
    );
  }
}

// ── 💡 አዲሱ እና እውነተኛው የቻት መጻፊያ ገጽ (Direct Chat Screen) ──
class DirectChatScreen extends StatefulWidget {
  final String chatName;
  final IconData iconData;

  const DirectChatScreen(
      {super.key, required this.chatName, required this.iconData});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  final TextEditingController _messageController = TextEditingController();

  // የቻት ታሪኮች
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello! How can I help you today?',
      'isMe': false,
      'time': '10:00 AM',
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

    // (እንደ ምሳሌ፣ መልስ እየተጻፈ መሆኑን ለማሳየት)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text':
                'Thank you for reaching out! I will get back to you shortly.',
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
                  Text(widget.chatName,
                      style: TextStyle(
                          color: primaryGold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const Text('Online',
                      style:
                          TextStyle(color: Colors.greenAccent, fontSize: 12)),
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
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
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
                        Text(
                          msg['text'],
                          style: TextStyle(
                            color: isMe ? primaryDarkGreen : Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          msg['time'],
                          style: TextStyle(
                            color: isMe
                                ? primaryDarkGreen.withValues(alpha: 0.6)
                                : Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // ── የጽሁፍ መጻፊያ (Keyboard Input) ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardGreen,
              border: Border(
                  top: BorderSide(color: primaryGold.withValues(alpha: 0.2))),
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
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: primaryDarkGreen,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
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
