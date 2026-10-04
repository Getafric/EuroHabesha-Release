import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notifications_screen.dart';
import 'business_screen.dart';
import 'events_screen.dart';
import 'jobs_screen.dart';
import 'marketplace_screen.dart';
import 'professionals_screen.dart';
import 'admin_panel_screen.dart';
import 'app_session.dart';
import 'admin_updates_feed.dart';
import 'nearby_screen.dart';
import 'habesha_connect/habesha_connect_screen.dart';
import 'sponsored_banner_section.dart';
import 'sponsored_interstitial_ad.dart';
import 'package:geocoding/geocoding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  String userLocation = 'Localisation GPS en cours...';

  late final PageController _pageController;
  Timer? _sliderTimer;
  Timer? _interstitialTimer;

  final Map<String, Map<String, String>> texts = const {
    'Categories': {
      'English': 'Categories',
      'French': 'Catégories',
      'Amharic': 'ምድቦች',
      'Tigrinya': 'ምድባት',
    },
    'Recent Updates': {
      'English': 'Featured Updates',
      'French': 'Mises à jour à proximité',
      'Amharic': 'ዋና ዋና መረጃዎች',
      'Tigrinya': 'ፍሉያት ሓበሬታታት',
    },
    'Jobs': {
      'English': 'Jobs',
      'French': 'Emplois',
      'Amharic': 'ስራ',
      'Tigrinya': 'ስራሕ',
    },
    'Businesses': {
      'English': 'Businesses',
      'French': 'Commerces',
      'Amharic': 'ንግድ',
      'Tigrinya': 'ንግዲ',
    },
    'Market': {
      'English': 'Market',
      'French': 'Marché',
      'Amharic': 'ገበያ',
      'Tigrinya': 'ዕዳጋ',
    },
    'Pros': {
      'English': 'Professionals',
      'French': 'Professionnels',
      'Amharic': 'ባለሙያዎች',
      'Tigrinya': 'ሰብ ሞያ',
    },
    'Events': {
      'English': 'Events',
      'French': 'Événements',
      'Amharic': 'ክስተት',
      'Tigrinya': 'ፍጻመታት',
    },
    'Habesha Connect': {
      'English': 'Habesha Connect',
      'French': 'Habesha Connect',
      'Amharic': 'Habesha Connect',
      'Tigrinya': 'Habesha Connect',
    },
    'Nearby': {
      'English': 'Nearby',
      'French': 'À proximité',
      'Amharic': 'በአቅራቢያ',
      'Tigrinya': 'ኣብ ቀረባ',
    },
  };

  String getTxt(String key) {
    final language = switch (context.locale.languageCode) {
      'fr' => 'French',
      'am' => 'Amharic',
      'ti' => 'Tigrinya',
      _ => 'English',
    };

    return texts[key]?[language] ?? texts[key]?['English'] ?? key;
  }

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 0.75,
    );

    // _tickerTimer = Timer.periodic(
    //   const Duration(seconds: 4),
    //   (timer) {
    //     if (mounted) {
    //       setState(() {
    //         _tickerIndex = (_tickerIndex + 1) % tickerMessages.length;
    //       });
    //     }
    //   },
    // );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();

      _interstitialTimer = Timer(
        const Duration(seconds: 12),
        () {
          if (!mounted) return;

          SponsoredInterstitialAd.showIfAvailable(context);
        },
      );
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _interstitialTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          userLocation = 'Les services de localisation sont désactivés.';
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            userLocation = 'Autorisation de localisation refusée.';
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          userLocation = 'Autorisation de localisation refusée définitivement.';
        });
      }
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      String locationName = 'GPS actif';

      try {
        final geocoding = Geocoding();

        final placemarks = await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          final locality = place.locality?.trim() ?? '';
          final subLocality = place.subLocality?.trim() ?? '';
          final administrativeArea = place.administrativeArea?.trim() ?? '';

          if (subLocality.isNotEmpty &&
              subLocality.toLowerCase() != locality.toLowerCase()) {
            locationName = subLocality;
          } else if (locality.isNotEmpty) {
            locationName = locality;
          } else if (administrativeArea.isNotEmpty) {
            locationName = administrativeArea;
          }
        }
      } catch (_) {
        locationName = 'GPS actif';
      }

      if (mounted) {
        setState(() {
          userLocation = locationName;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userLocation = 'GPS actif';
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _checkLocationPermission();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleUpdateTap(Map<String, dynamic> data) async {
    final sourceCollection = (data['sourceCollection'] ?? '').toString().trim();

    final sourceId = (data['sourceId'] ?? '').toString().trim();

    final category =
        (data['category'] ?? data['type'] ?? '').toString().toLowerCase();

    Map<String, dynamic>? sourceData;

    if (sourceCollection.isNotEmpty && sourceId.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection(sourceCollection)
            .doc(sourceId)
            .get();

        if (snapshot.exists) {
          sourceData = snapshot.data();

          if (sourceData != null) {
            sourceData = {
              ...sourceData,
              'id': snapshot.id,
            };
          }
        }
      } catch (_) {
        sourceData = null;
      }
    }

    if (!mounted) return;

    // -------------------------------------------------
    // EVENT
    // -------------------------------------------------
    if (category.contains('event') ||
        sourceCollection.toLowerCase().contains('event')) {
      if (sourceData != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(
              eventData: sourceData!,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EventsScreen(),
          ),
        );
      }

      return;
    }

    // -------------------------------------------------
    // MARKETPLACE
    // -------------------------------------------------
    if (category.contains('market') ||
        sourceCollection.toLowerCase().contains('marketplace')) {
      if (sourceData != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: sourceData!,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MarketplaceScreen(),
          ),
        );
      }

      return;
    }

    // -------------------------------------------------
    // BUSINESS / RESTAURANT
    // -------------------------------------------------
    if (category.contains('business') ||
        category.contains('restaurant') ||
        sourceCollection.toLowerCase() == 'businesses') {
      if (sourceData != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusinessDetailScreen(
              businessData: sourceData!,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BusinessDirectoryScreen(),
          ),
        );
      }

      return;
    }

    // -------------------------------------------------
    // PROFESSIONAL
    // -------------------------------------------------
    if (category.contains('professional') ||
        category == 'pro' ||
        sourceCollection.toLowerCase().contains('professional')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfessionalsScreen(),
        ),
      );

      return;
    }

    // -------------------------------------------------
    // JOB / SERVICE
    // -------------------------------------------------
    if (category.contains('job') ||
        category.contains('service') ||
        sourceCollection.toLowerCase().contains('job')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const JobsScreen(),
        ),
      );

      return;
    }

    // -------------------------------------------------
    // HABESHA CONNECT / COMMUNITY
    // -------------------------------------------------
    if (category.contains('community') ||
        category.contains('habesha') ||
        sourceCollection.toLowerCase().contains('habeshaconnect')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HabeshaConnectScreen(),
        ),
      );

      return;
    }

    // Catégorie inconnue : ne fait pas planter l'application.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cette publication ne peut pas encore être ouverte.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      drawer: _buildSideDrawer(
        context,
        primaryDarkGreen,
        primaryGold,
      ),
      appBar: AppBar(
        toolbarHeight: 90,
        title: SizedBox(
          height: 70,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/euro_habesha_logo.png',
                  height: 64,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.public,
                    color: primaryGold,
                    size: 48,
                  ),
                ),
                const SizedBox(width: 8),
                RichText(
                  maxLines: 1,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    children: [
                      TextSpan(
                        text: 'EURO ',
                        style: TextStyle(
                          color: primaryGold,
                        ),
                      ),
                      TextSpan(
                        text: 'HABESHA',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: primaryDarkGreen,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: primaryGold,
        ),
        actions: [
          Builder(
            builder: (context) {
              final user = FirebaseAuth.instance.currentUser;

              if (user == null) {
                return const SizedBox(width: 48);
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where(
                      'recipientId',
                      isEqualTo: user.uid,
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.hasData
                      ? snapshot.data!.docs.where((document) {
                          final data = document.data();

                          final isUnread = data['read'] != true;
                          final type = data['type']?.toString() ?? '';

                          return isUnread && type != 'message';
                        }).length
                      : 0;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          tooltip: 'Notifications',
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: primaryGold,
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationScreen(),
                              ),
                            );
                          },
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 2,
                            top: 6,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Content below the banner
            Expanded(
              child: RefreshIndicator(
                color: primaryDarkGreen,
                backgroundColor: primaryGold,
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------------------------------------------------
                      // NEARBY / RADAR
                      // -------------------------------------------------
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NearbyScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          color: cardGreen,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.near_me,
                                color: primaryGold,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${getTxt('Nearby')} • $userLocation',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryGold,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Radar 📍',
                                  style: TextStyle(
                                    color: primaryDarkGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

// -------------------------------------------------
// SPONSORED BANNER
// -------------------------------------------------
                      const TopSponsoredBanner(),

                      const SizedBox(height: 10),
                      // -------------------------------------------------
// OFFICIAL UPDATES
// -------------------------------------------------
                      const AdminUpdatesFeed(),

                      const SizedBox(height: 15),
                      // -------------------------------------------------
                      // CATEGORIES
                      // -------------------------------------------------
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Text(
                          getTxt('Categories'),
                          style: const TextStyle(
                            color: primaryGold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildGridCategory(
                                  getTxt('Jobs'),
                                  const Icon(
                                    Icons.work,
                                    size: 23,
                                    color: primaryGold,
                                  ),
                                  context,
                                  const JobsScreen(),
                                ),
                                _buildGridCategory(
                                  getTxt('Businesses'),
                                  const Icon(
                                    Icons.storefront,
                                    size: 23,
                                    color: primaryGold,
                                  ),
                                  context,
                                  const BusinessDirectoryScreen(),
                                ),
                                _buildGridCategory(
                                  getTxt('Market'),
                                  const Icon(
                                    Icons.shopping_cart,
                                    size: 23,
                                    color: primaryGold,
                                  ),
                                  context,
                                  MarketplaceScreen(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildGridCategory(
                                  getTxt('Pros'),
                                  const Icon(
                                    Icons.verified_user,
                                    size: 23,
                                    color: primaryGold,
                                  ),
                                  context,
                                  const ProfessionalsScreen(),
                                ),
                                _buildGridCategory(
                                  getTxt('Events'),
                                  const Icon(
                                    Icons.event,
                                    size: 23,
                                    color: primaryGold,
                                  ),
                                  context,
                                  const EventsScreen(),
                                ),
                                _buildGridCategory(
                                  getTxt('Habesha Connect'),
                                  const Icon(
                                    Icons.groups,
                                    size: 23,
                                    color: primaryGold,
                                  ),
                                  context,
                                  const HabeshaConnectScreen(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // -------------------------------------------------
                      // RECENT / FEATURED UPDATES
                      // -------------------------------------------------
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Text(
                          getTxt('Recent Updates'),
                          style: const TextStyle(
                            color: primaryGold,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('publicFeed')
                            .limit(30)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 210,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: primaryGold,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return const SizedBox(
                              height: 80,
                              child: Center(
                                child: Text(
                                  'Unable to load updates.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            );
                          }

                          final updates =
                              (snapshot.data?.docs ?? []).where((doc) {
                            final data = doc.data();

                            return (data['status'] ?? '')
                                    .toString()
                                    .toLowerCase() ==
                                'published';
                          }).toList();

                          updates.sort((a, b) {
                            int score(Map<String, dynamic> data) {
                              final badgeData = data['verificationBadge'];

                              final badge = badgeData is Map
                                  ? Map<String, dynamic>.from(badgeData)
                                  : <String, dynamic>{};

                              final badgeTitle = (badge['title'] ?? '')
                                  .toString()
                                  .toLowerCase();

                              final tier = (data['subscriptionTier'] ?? '')
                                  .toString()
                                  .toLowerCase();

                              final publishedAt =
                                  data['publishedAt'] ?? data['createdAt'];

                              final timestamp = publishedAt is Timestamp
                                  ? publishedAt.millisecondsSinceEpoch ~/ 100000
                                  : 0;

                              final rating =
                                  (data['rating'] as num?)?.toDouble() ?? 0;

                              final reviewCount =
                                  (data['reviewCount'] as num?)?.toInt() ?? 0;

                              final isVip = badgeTitle.contains('vip') ||
                                  tier.contains('vip');

                              final isPro = badgeTitle.contains('pro') ||
                                  tier.contains('pro');

                              final isSilver = badgeTitle.contains('silver') ||
                                  tier.contains('silver');

                              final isVerified = data['isVerified'] == true ||
                                  data['verificationStatus'] == 'approved' ||
                                  badgeTitle.isNotEmpty;

                              return (data['isDemo'] == true ? -20000000 : 0) +
                                  (isVip ? 12000000 : 0) +
                                  (isPro ? 8000000 : 0) +
                                  (isSilver ? 6000000 : 0) +
                                  (isVerified ? 5000000 : 0) +
                                  (rating * 1000).round() +
                                  reviewCount +
                                  timestamp;
                            }

                            return score(b.data()).compareTo(score(a.data()));
                          });

                          if (updates.isEmpty) {
                            return const SizedBox(
                              height: 90,
                              child: Center(
                                child: Text(
                                  'Aucune mise à jour disponible.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            );
                          }

                          return SizedBox(
                            height: 210,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: updates.length,
                              itemBuilder: (context, index) {
                                final data = updates[index].data();

                                final title = (data['title'] ?? 'Euro Habesha')
                                    .toString();

                                final subtitle = (data['subtitle'] ??
                                        data['location'] ??
                                        data['city'] ??
                                        '')
                                    .toString();

                                final description =
                                    (data['description'] ?? '').toString();

                                String firstImageFrom(dynamic value) {
                                  if (value is List) {
                                    for (final item in value) {
                                      final url = item?.toString().trim() ?? '';
                                      if (url.isNotEmpty) return url;
                                    }
                                  }
                                  return '';
                                }

                                final imageUrl = [
                                  (data['imageUrl'] ?? '').toString().trim(),
                                  (data['image'] ?? '').toString().trim(),
                                  (data['photoUrl'] ?? '').toString().trim(),
                                  (data['logoUrl'] ?? '').toString().trim(),
                                  (data['coverImageUrl'] ?? '')
                                      .toString()
                                      .trim(),
                                  firstImageFrom(data['imageUrls']),
                                  firstImageFrom(data['photoUrls']),
                                  firstImageFrom(data['photos']),
                                  firstImageFrom(data['mediaUrls']),
                                ].firstWhere(
                                  (url) => url.isNotEmpty,
                                  orElse: () => '',
                                );

                                final category =
                                    (data['category'] ?? 'COMMUNITY')
                                        .toString()
                                        .toUpperCase();

                                final tier = (data['subscriptionTier'] ?? '')
                                    .toString()
                                    .toUpperCase();

                                return GestureDetector(
                                  onTap: () => _handleUpdateTap(data),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cardGreen,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color:
                                            primaryGold.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 110,
                                          width: double.infinity,
                                          child: imageUrl.isNotEmpty
                                              ? Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Container(
                                                      color: Colors.white
                                                          .withValues(
                                                        alpha: 0.08,
                                                      ),
                                                      child: const Icon(
                                                        Icons.image_outlined,
                                                        color: Colors.white38,
                                                        size: 34,
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  color:
                                                      Colors.white.withValues(
                                                    alpha: 0.08,
                                                  ),
                                                  child: const Icon(
                                                    Icons.public,
                                                    color: primaryGold,
                                                    size: 34,
                                                  ),
                                                ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: primaryGold,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    if (tier == 'VIP' ||
                                                        tier == 'PRO') ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: primaryGold,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          tier,
                                                          style:
                                                              const TextStyle(
                                                            color:
                                                                primaryDarkGreen,
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  subtitle.isNotEmpty
                                                      ? '$category • $subtitle'
                                                      : category,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                if (description.isNotEmpty) ...[
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    description,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white38,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 50),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideDrawer(
    BuildContext context,
    Color bgColor,
    Color goldColor,
  ) {
    return Drawer(
      backgroundColor: bgColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF004D40),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/images/euro_habesha_logo.png',
                  height: 60,
                  errorBuilder: (c, e, s) => Icon(
                    Icons.public,
                    size: 60,
                    color: goldColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Euro Habesha',
                  style: TextStyle(
                    color: goldColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Connect. Discover. Grow.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            const Icon(
              Icons.near_me,
              color: primaryGold,
            ),
            getTxt('Nearby'),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NearbyScreen(),
                ),
              );
            },
            goldColor,
          ),
          _buildDrawerItem(
            const Icon(
              Icons.work,
              color: primaryGold,
            ),
            getTxt('Jobs'),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JobsScreen(),
                ),
              );
            },
            goldColor,
          ),
          _buildDrawerItem(
            const Icon(
              Icons.storefront,
              color: primaryGold,
            ),
            getTxt('Businesses'),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusinessDirectoryScreen(),
                ),
              );
            },
            goldColor,
          ),
          _buildDrawerItem(
            const Icon(
              Icons.shopping_cart,
              color: primaryGold,
            ),
            getTxt('Market'),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MarketplaceScreen(),
                ),
              );
            },
            goldColor,
          ),
          _buildDrawerItem(
            const Icon(
              Icons.verified_user,
              color: primaryGold,
            ),
            getTxt('Pros'),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfessionalsScreen(),
                ),
              );
            },
            goldColor,
          ),
          _buildDrawerItem(
            const Icon(
              Icons.event,
              color: primaryGold,
            ),
            getTxt('Events'),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EventsScreen(),
                ),
              );
            },
            goldColor,
          ),
          _buildDrawerItem(
            const Icon(
              Icons.groups,
              color: primaryGold,
            ),
            getTxt('Habesha Connect'),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HabeshaConnectScreen(),
                ),
              );
            },
            goldColor,
          ),
          const Divider(color: Colors.white24),
          if (AppSession.isSuperAdmin || AppSession.roles.isNotEmpty)
            _buildDrawerItem(
              Icon(
                Icons.admin_panel_settings,
                color: goldColor,
              ),
              AppSession.isSuperAdmin
                  ? getTxt('Admin Control Panel')
                  : getTxt('My Admin Panel'),
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
              goldColor,
            ),
          _buildDrawerItem(
            const Icon(
              Icons.info_outline,
              color: primaryGold,
            ),
            getTxt('About Euro Habesha'),
            () {
              Navigator.pop(context);

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: cardGreen,
                  title: Text(
                    getTxt('Euro Habesha'),
                    style: TextStyle(
                      color: goldColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    getTxt(
                        'The ultimate Diaspora Trust Gateway connecting Ethiopians and Eritreans across Europe.\nVersion 1.0.2'),
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        getTxt('Close'),
                        style: TextStyle(
                          color: goldColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            goldColor,
          ),
        ],
      ),
    );
  }

  // =============================================================
  // DRAWER ITEM
  // =============================================================

  Widget _buildDrawerItem(
    Widget iconWidget,
    String title,
    VoidCallback onTap,
    Color goldColor,
  ) {
    return ListTile(
      leading: iconWidget,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  // =============================================================
  // HOME CATEGORY CARD
  // =============================================================

  Widget _buildGridCategory(
    String title,
    Widget customIcon,
    BuildContext context,
    Widget destinationPage,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => destinationPage,
        ),
      ),
      child: Container(
        width: 100,
        height: 72,
        decoration: BoxDecoration(
          color: cardGreen,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customIcon,
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
