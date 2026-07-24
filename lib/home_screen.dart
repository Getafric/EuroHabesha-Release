// EuroHabesha - Complete Flutter Home/Feed Screen
// Copy this file directly to your Flutter project's `lib/home_screen.dart` directory.

// ignore_for_file: unused_element

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admob_config.dart';
import 'models.dart';
import 'access_control.dart';
import 'offer_detail_screen.dart';
import 'admin_post_page.dart';
import 'community_groups_screen.dart';
import 'gallery_screen.dart';
import 'business_directory_screen.dart';
import 'jobs_screen.dart';
import 'market_screen.dart';
import 'events_screen.dart';
import 'service_profile_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.initialTabIndex = 0,
    this.onOpenSearch,
    this.onOpenEvents,
    this.onOpenMarket,
    this.onOpenAlerts,
  });

  final int initialTabIndex;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenEvents;
  final VoidCallback? onOpenMarket;
  final VoidCallback? onOpenAlerts;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final Stream<bool> _adminAccessStream;
  final PageController _promoPageController = PageController(viewportFraction: 0.95);
  final PageController _verifiedProsController = PageController(viewportFraction: 0.86);
  final PageController _newsTickerController = PageController(viewportFraction: 0.96);
  Timer? _promoTimer;
  Timer? _verifiedProsTimer;
  Timer? _newsTickerTimer;
  int _promoIndex = 0;
  int _verifiedProsIndex = 0;
  int _newsTickerIndex = 0;
  int _promoItemCount = 0;
  String _selectedFeedCategory = 'All';
  StreamSubscription<bool>? _adminAccessSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _professionalsSubscription;
  bool _hasShownAdminGrantNotice = false;
  BannerAd? _bannerAd;
  bool _isBannerReady = false;
  Position? _userPosition;
  bool _isLoadingLocation = false;
  final List<String> _homeJobCategories = const [
    'Cleaning Services',
    'Mechanics',
    'Business Services',
    'Car Wash',
    'Photography & Videography',
    'DJ Services',
    'Electrician',
    'Painting',
    'Furniture Assembly / Carpentry',
    'Gardening',
    'Catering Services',
    'Decor Services',
    'Medical Professionals (Doctors / Pharmacists)',
    'Legal Counsel',
    'Translators',
    'Taxi / Truck Drivers',
    'Airport Pickup / Logistics',
    'Miscellaneous / Other',
  ];

  final List<Map<String, String>> _newsOffers = const [
    {
      'title': 'ROME 2026 Festival Update',
      'details': 'Event: 21st ESCFE Annual Festival\nCity: Rome, Italy\nVenue: Salaria Sport Village\nDates: 27 July - 1 August 2026\nHow to go: Fly to Rome Fiumicino (FCO), then take Leonardo Express to Termini and metro/bus to the venue. Airport shuttles and taxi routes are available from Termini.\nWhat to expect: Family programs, music, sports, cultural performances, food area, and diaspora networking.\nTip: Tap registration early and secure accommodation near metro lines for easier daily access.',
      'code': 'ROME2026',
    },
    {
      'title': 'German Family Beach Weekend',
      'details': 'Event: Habesha Family Beach Festival\nCity: Wachtendonk, Germany\nVenue: Blaue Lagune\nDates: 22-23 August 2026\nHow to go: Nearest airport is Dusseldorf (DUS). Use regional train to Krefeld then local connection/taxi to Wachtendonk. Driving from Cologne or Dusseldorf is also convenient via A57 routes.\nWhat to expect: Family beach games, children activities, live DJs, Habesha food market, and evening cultural show.\nTip: Arrive early morning for parking and family seating near activity zones.',
      'code': 'BEACHDE',
    },
    {
      'title': 'Paris Community Networking Night',
      'details': 'Event: Paris Habesha Networking Night\nCity: Paris, France\nVenue: Central Paris community hall (final hall details shown after reservation)\nDate: September 2026 (evening session)\nHow to go: Metro access from major lines; nearest station details are sent in confirmation.\nWhat to expect: Founder talks, professional introductions, startup tables, and mentorship corner.\nTip: Bring your business profile/portfolio for quick networking matches.',
      'code': 'PARISLIVE',
    },
  ];

  final List<Professional> _professionals = [
    Professional(
      id: 'prof1',
      userId: 'u10',
      name: 'Dr. Selamawit Alene',
      category: 'Doctor (Internal Medicine)',
      country: 'Germany',
      city: 'Frankfurt',
      phone: '+49 176 1234567',
      whatsapp: '+49 176 1234567',
      bio: 'Providing culturally sensitive medical consultations in Amharic, Tigrinya, and German. Over 12 years of clinical practice in Frankfurt Hospital.',
      imageUrl: 'https://i.postimg.cc/CxgBvwGK/1782001804761.png',
      verificationStage: 'vip',
      rating: 4.9,
      reviewCount: 38,
      status: 'approved',
      createdAt: '2026-01-01',
    ),
    Professional(
      id: 'prof2',
      userId: 'u11',
      name: 'Michael Kassa, Esq.',
      category: 'Lawyer (Immigration & Tax)',
      country: 'United Kingdom',
      city: 'London',
      phone: '+44 7911 887766',
      bio: 'Dedicated immigration specialist advising Habesha diaspora on EU asylum laws, skilled worker visas, and corporate compliance.',
      imageUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150',
      verificationStage: 'professional',
      rating: 4.8,
      reviewCount: 22,
      status: 'approved',
      createdAt: '2026-01-10',
    ),
  ];
  List<Professional> _liveProfessionals = const [];

  List<Professional> get _displayProfessionals => _liveProfessionals.isEmpty ? _professionals : _liveProfessionals;

  final List<EventItem> _events = [
    EventItem(
      id: 'e1',
      userId: 'u20',
      authorName: 'London Habesha Committee',
      title: 'Grand Cultural Festival in London',
      description: 'Join us for a spectacular evening of traditional food, live Eskesta, guest speakers, and outstanding Ethiopian live bands.',
      category: 'Cultural Events',
      country: 'United Kingdom',
      city: 'London',
      date: 'Dec 12, 2026',
      time: '18:00 - 23:30',
      imageUrl: 'https://images.unsplash.com/photo-1511578314322-379afb476865?w=500',
      status: 'approved',
      createdAt: '2026-02-01',
      ticketPrice: 25.0,
    ),
  ];

  final List<Job> _jobs = [
    Job(
      id: 'j1',
      userId: 'u30',
      authorName: 'Lalibela Restaurant Paris',
      authorPhone: '+33 6 11223344',
      title: 'Head Chef (Habesha Traditional Cuisine)',
      category: 'Culinary / Catering',
      country: 'France',
      city: 'Paris',
      price: 18.5,
      phone: '+33 6 11223344',
      description: 'Looking for a highly skilled traditional Chef to manage our evening kitchen. Must have verified background in authentic Ethiopian stews (Wot) and baking Enjera.',
      verified: true,
      status: 'approved',
      createdAt: '2026-02-15',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 4),
    );
    _adminAccessStream = AccessControl.watchCurrentUserAdminAccess();
    _listenVerifiedProfessionals();
    _startPromoAutoSlide();
    _startVerifiedProfessionalsAutoSlide();
    _startNewsTickerAutoSlide();
    _loadCurrentLocation();
    _loadBannerAd();
    _adminAccessSubscription = _adminAccessStream.listen((hasAccess) {
      if (!mounted || !hasAccess || _hasShownAdminGrantNotice) return;
      _hasShownAdminGrantNotice = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin access granted. Admin panel is now available.')),
      );
    });
  }

  @override
  void dispose() {
    _adminAccessSubscription?.cancel();
    _professionalsSubscription?.cancel();
    _promoTimer?.cancel();
    _verifiedProsTimer?.cancel();
    _newsTickerTimer?.cancel();
    _promoPageController.dispose();
    _verifiedProsController.dispose();
    _newsTickerController.dispose();
    _bannerAd?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _listenVerifiedProfessionals() {
    _professionalsSubscription?.cancel();
    _professionalsSubscription = FirebaseFirestore.instance
        .collection('verified_professionals')
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final mapped = snapshot.docs.map((doc) {
        final data = doc.data();
        final createdAtValue = data['createdAt'];
        final createdAt = createdAtValue is Timestamp
            ? createdAtValue.toDate().toIso8601String()
            : (data['createdAt'] ?? '').toString();
        return Professional(
          id: doc.id,
          userId: (data['userId'] ?? '').toString(),
          name: (data['name'] ?? '').toString(),
          category: (data['category'] ?? '').toString(),
          country: (data['country'] ?? '').toString(),
          city: (data['city'] ?? '').toString(),
          phone: (data['phone'] ?? '').toString(),
          whatsapp: (data['whatsapp'] ?? '').toString().trim().isEmpty
              ? null
              : (data['whatsapp'] ?? '').toString(),
          email: (data['email'] ?? '').toString().trim().isEmpty
              ? null
              : (data['email'] ?? '').toString(),
          website: (data['website'] ?? '').toString().trim().isEmpty
              ? null
              : (data['website'] ?? '').toString(),
          bio: (data['bio'] ?? '').toString(),
          imageUrl: (data['imageUrl'] ?? '').toString().trim().isEmpty
              ? null
              : (data['imageUrl'] ?? '').toString(),
          verificationStage: (data['verificationStage'] ?? 'professional').toString(),
          isVerified: data['isVerified'] == true,
          rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0,
          reviewCount: (data['reviewCount'] is num) ? (data['reviewCount'] as num).toInt() : 0,
          status: (data['status'] ?? 'approved').toString(),
          createdAt: createdAt,
        );
      }).where((professional) => professional.name.trim().isNotEmpty).toList();

      if (!mounted) return;
      setState(() {
        _liveProfessionals = mapped;
      });
    });
  }

  void _startPromoAutoSlide() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_promoPageController.hasClients || _promoItemCount <= 1) return;
      final nextPage = (_promoIndex + 1) % _promoItemCount;
      _promoPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
      _promoIndex = nextPage;
    });
  }

  void _startVerifiedProfessionalsAutoSlide() {
    _verifiedProsTimer?.cancel();
    _verifiedProsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final source = _displayProfessionals;
      final total = source.length > 6 ? 6 : source.length;
      if (!mounted || !_verifiedProsController.hasClients || total <= 1) return;

      final nextPage = (_verifiedProsIndex + 1) % total;
      _verifiedProsController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
      _verifiedProsIndex = nextPage;
    });
  }

  void _startNewsTickerAutoSlide() {
    _newsTickerTimer?.cancel();
    _newsTickerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final total = _newsOffers.length;
      if (!mounted || !_newsTickerController.hasClients || total <= 1) return;

      final nextPage = (_newsTickerIndex + 1) % total;
      _newsTickerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
      );
      _newsTickerIndex = nextPage;
    });
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerReady = false;

    final bannerAd = BannerAd(
      adUnitId: AdMobConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isBannerReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isBannerReady = false;
          });
        },
      ),
    );

    bannerAd.load();
  }

  final Map<String, (double lat, double lng)> _cityCoordinates = {
    'Frankfurt': (50.1109, 8.6821),
    'London': (51.5072, -0.1276),
    'Paris': (48.8566, 2.3522),
    'Berlin': (52.5200, 13.4050),
    'Brussels': (50.8503, 4.3517),
    'Rome': (41.9028, 12.4964),
    'Stockholm': (59.3293, 18.0686),
  };

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      setState(() {
        _userPosition = position;
        _isLoadingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  double? _distanceKmFor(Professional p) {
    final cityPoint = _cityCoordinates[p.city];
    if (cityPoint == null || _userPosition == null) return null;

    final meters = Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      cityPoint.$1,
      cityPoint.$2,
    );
    return meters / 1000;
  }

  String _reviewTargetKey({required String targetType, required String targetId}) {
    return '$targetType:$targetId';
  }

  Future<void> _submitReview({
    required String targetType,
    required String targetId,
    required double rating,
    required String comment,
  }) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      throw Exception('You must be signed in to submit a review.');
    }

    final targetKey = _reviewTargetKey(targetType: targetType, targetId: targetId);
    final reviewsRef = FirebaseFirestore.instance.collection('Reviews');
    final summariesRef = FirebaseFirestore.instance.collection('ReviewSummaries');
    final reviewDoc = reviewsRef.doc();
    final summaryDoc = summariesRef.doc(targetKey);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final summarySnap = await tx.get(summaryDoc);
      final data = summarySnap.data();
      final oldCount = (data?['reviewCount'] ?? 0) is num ? (data?['reviewCount'] ?? 0) as num : 0;
      final oldTotal = (data?['ratingTotal'] ?? 0) is num ? (data?['ratingTotal'] ?? 0) as num : 0;

      final newCount = oldCount.toInt() + 1;
      final newTotal = oldTotal.toDouble() + rating;
      final newAverage = newTotal / newCount;

      tx.set(reviewDoc, {
        'targetType': targetType,
        'targetId': targetId,
        'targetKey': targetKey,
        'reviewerUid': authUser.uid,
        'reviewerName': (authUser.displayName ?? authUser.email ?? 'Member').trim(),
        'reviewerContact': (authUser.email ?? '').trim(),
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(summaryDoc, {
        'targetType': targetType,
        'targetId': targetId,
        'targetKey': targetKey,
        'reviewCount': newCount,
        'ratingTotal': newTotal,
        'averageRating': newAverage,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> _shareProfileLink(Professional p) async {
    final link = 'https://eurohabesha.app/profile/${p.id}';
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${tr('profile_link_copied')}: $link')),
    );
  }

  void _showReviewDialog({
    required String targetType,
    required String targetId,
    required String subjectLabel,
  }) {
    if (!AccessControl.ensureVerified(context, actionLabel: tr('rate_review'))) {
      return;
    }

    double selectedRating = 5;
    final commentController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF061E12),
              title: Text(tr('leave_review'), style: const TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        onPressed: () => setDialogState(() => selectedRating = value.toDouble()),
                        icon: Icon(
                          selectedRating >= value ? Icons.star : Icons.star_border,
                          color: const Color(0xFFF59E0B),
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: tr('comment'),
                      labelStyle: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(tr('cancel'), style: const TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF061E12),
                  ),
                  onPressed: () async {
                    final trimmed = commentController.text.trim();
                    if (trimmed.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Please add a review comment before submitting.')),
                      );
                      return;
                    }

                    try {
                      await _submitReview(
                        targetType: targetType,
                        targetId: targetId,
                        rating: selectedRating,
                        comment: trimmed,
                      );
                      if (!mounted) return;
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Thanks. Your review for $subjectLabel was submitted.')),
                      );
                    } catch (error) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Could not submit review: $error')),
                      );
                    }
                  },
                  child: Text(tr('submit')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDynamicReviewSection({
    required String targetType,
    required String targetId,
  }) {
    final targetKey = _reviewTargetKey(targetType: targetType, targetId: targetId);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('ReviewSummaries')
          .where('targetKey', isEqualTo: targetKey)
          .where('reviewCount', isGreaterThan: 0)
          .limit(1)
          .snapshots(),
      builder: (context, summarySnapshot) {
        final summaryDocs = summarySnapshot.data?.docs ?? [];
        if (summaryDocs.isEmpty) return const SizedBox.shrink();

        final summary = summaryDocs.first.data();
        final average = (summary['averageRating'] is num) ? (summary['averageRating'] as num).toDouble() : 0.0;
        final count = (summary['reviewCount'] is num) ? (summary['reviewCount'] as num).toInt() : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 4),
                Text(
                  average.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 6),
                Text(
                  '($count reviews)',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Reviews')
                  .where('targetKey', isEqualTo: targetKey)
                  .limit(3)
                  .snapshots(),
              builder: (context, reviewsSnapshot) {
                final docs = reviewsSnapshot.data?.docs ?? [];
                final visible = docs.where((doc) {
                  final data = doc.data();
                  final rating = (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0;
                  return rating > 0;
                }).toList();

                if (visible.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: visible.map((doc) {
                    final data = doc.data();
                    final reviewer = (data['reviewerName'] ?? 'Anonymous').toString();
                    final comment = (data['comment'] ?? '').toString().trim();
                    if (comment.isEmpty) return const SizedBox.shrink();

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF123425),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewer,
                            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment,
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _openCityExplorer(String city) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CityExplorerScreen(
          city: city,
          professionals: _displayProfessionals,
          events: _events,
          jobs: _jobs,
        ),
      ),
    );
  }

  Widget _buildAutoPromoCarousel() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final promoItems = _buildPromoItems(docs);
        _promoItemCount = promoItems.length;

        if (promoItems.isEmpty) {
          return _buildAddNewFeaturedEventCard();
        }

        return SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _promoPageController,
            itemCount: promoItems.length,
            onPageChanged: (index) {
              _promoIndex = index;
            },
            itemBuilder: (context, index) {
              final item = promoItems[index];

              return GestureDetector(
                onTap: () async {
                  if (item.externalLink.isNotEmpty) {
                    final uri = Uri.tryParse(item.externalLink);
                    if (uri == null) return;
                    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
                    if (!opened && mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Could not open link right now.')),
                      );
                    }
                    return;
                  }
                  _showPromoDetails(item);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB91C1C), Color(0xFF7C2D12), Color(0xFF854D0E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFFFBBF24), width: 1.4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(251, 191, 36, 0.18),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (item.imageUrl.isNotEmpty)
                          Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color.fromRGBO(127, 16, 24, 0.75), Color.fromRGBO(77, 10, 15, 0.82)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.category.toUpperCase(),
                                style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w900, fontSize: 10),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.25),
                              ),
                              const Spacer(),
                              if (item.actionLabel.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBBF24),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    item.actionLabel,
                                    style: const TextStyle(color: Color(0xFF4A0D12), fontSize: 11, fontWeight: FontWeight.w900),
                                  ),
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
          ),
        );
      },
    );
  }

  List<_PromoBannerItem> _buildPromoItems(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs
        .map((doc) {
          final data = doc.data();
          if (!_isAnnouncementActive(data)) return null;

          final title = (data['title'] ?? '').toString().trim();
          final subtitle = (data['subtitle'] ?? data['category'] ?? '').toString().trim();
          final description = (data['body'] ?? data['description'] ?? '').toString().trim();
          final category = (data['category'] ?? 'General').toString().trim();
          final imageUrl = (data['imageUrl'] ?? data['image'] ?? '').toString().trim();
          final externalLink = (data['link'] ?? '').toString().trim();

          if (title.isEmpty && description.isEmpty) return null;

          return _PromoBannerItem(
            title: title.isEmpty ? 'Community Update' : title,
            subtitle: subtitle,
            description: description.isEmpty ? 'Tap to explore details.' : description,
            category: category,
            actionLabel: externalLink.isEmpty ? 'Read' : 'Open',
            imageUrl: imageUrl,
            externalLink: externalLink,
          );
        })
        .whereType<_PromoBannerItem>()
        .toList();
  }

  void _showPromoDetails(_PromoBannerItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E2E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  item.category,
                  style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  item.description,
                  style: const TextStyle(color: Colors.white70, height: 1.45),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF061E12),
                      ),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => JobsScreen(initialCategory: item.category),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Related Jobs'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommunityStatsCard() {
    final professionals = _displayProfessionals;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _StatsItem(label: 'Professionals', value: '${professionals.length}'),
          _StatsItem(label: 'Events', value: '${_events.length}'),
          _StatsItem(label: 'Jobs', value: '${_jobs.length}'),
        ],
      ),
    );
  }

  Widget _buildVerifiedProfessionalsStrip() {
    final professionals = _displayProfessionals;
    if (professionals.isEmpty) return const SizedBox.shrink();

    final featured = professionals.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verified Professionals',
          style: TextStyle(
            color: Color(0xFFF5C542),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 132,
          child: PageView.builder(
            controller: _verifiedProsController,
            itemCount: featured.length,
            onPageChanged: (index) {
              _verifiedProsIndex = index;
            },
            itemBuilder: (context, index) {
              final p = featured[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ServiceProfileDetailScreen(
                          title: p.name,
                          category: p.category,
                          description: p.bio,
                          providerName: p.name,
                          city: '${p.city}, ${p.country}',
                          phone: p.phone,
                          email: p.email ?? '',
                          website: p.website ?? '',
                          userId: p.userId,
                          imageUrl: p.imageUrl ?? '',
                          postId: p.id,
                          postType: 'verified_professionals',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E2E1E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFF5C542), fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFFFD978), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFFF5C542)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${p.city}, ${p.country}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFFEFD38A), fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (featured.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(featured.length, (index) {
              final isActive = index == _verifiedProsIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 14 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isActive ? const Color(0xFFF5C542) : const Color(0x66F5C542),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  bool _isAnnouncementActive(Map<String, dynamic> data) {
    final active = data['active'];
    if (active is bool && !active) return false;

    final expiresAt = data['expiresAt'];
    if (expiresAt is Timestamp) {
      return DateTime.now().isBefore(expiresAt.toDate());
    }
    return true;
  }

  bool _announcementMatchesCategory(Map<String, dynamic> data, String selected) {
    if (selected == 'All') return true;
    final category = (data['category'] ?? '').toString().toLowerCase();
    return category.contains(selected.toLowerCase());
  }

  bool _isServiceListingAnnouncement(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().toLowerCase();
    if (type == 'listing') return true;

    final category = (data['category'] ?? '').toString().toLowerCase();
    return category.contains('service')
        || category.contains('translator')
        || category.contains('photograph')
        || category.contains('catering')
        || category.contains('job')
        || category.contains('professional')
        || category.contains('business');
  }

  void _openServiceListingFromAnnouncement(Map<String, dynamic> data, {String announcementId = ''}) {
    String firstNonEmpty(List<dynamic> values) {
      for (final value in values) {
        final text = value == null ? '' : value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    final title = (data['title'] ?? '').toString().trim();
    final category = (data['category'] ?? 'Service').toString().trim();
    final description = (data['body'] ?? data['description'] ?? '').toString().trim();
    final providerName = (data['providerName'] ?? data['authorName'] ?? data['submittedBy'] ?? '').toString().trim();
    final city = (data['city'] ?? '').toString().trim();
    final phone = (data['phone'] ?? data['authorPhone'] ?? '').toString().trim();
    final email = (data['email'] ?? '').toString().trim();
    final website = (data['website'] ?? data['externalLink'] ?? '').toString().trim();
    final userId = firstNonEmpty([
      data['userId'],
      data['user_id'],
      data['providerUid'],
      data['ownerUid'],
      data['authorUid'],
      data['postedByUid'],
      data['postedBy'],
      data['createdByUid'],
      data['createdBy'],
      data['submittedByUid'],
      data['uid'],
    ]);
    final imageUrl = (data['imageUrl'] ?? '').toString().trim();
    final sourceId = (data['sourceId'] ?? '').toString().trim();
    final sourceCollection = (data['sourceCollection'] ?? 'announcements').toString().trim();
    final fallbackPostId = (data['id'] ?? '').toString().trim();
    final finalPostId = sourceId.isNotEmpty
      ? sourceId
      : (fallbackPostId.isNotEmpty ? fallbackPostId : announcementId.trim());

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceProfileDetailScreen(
          title: title.isEmpty ? 'Service Listing' : title,
          category: category,
          description: description,
          providerName: providerName,
          city: city,
          phone: phone,
          email: email,
          website: website,
          userId: userId,
          imageUrl: imageUrl,
          postId: finalPostId,
          postType: sourceCollection,
        ),
      ),
    );
  }

  List<String> _buildFeedCategories(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final categories = <String>{
      'All',
      'Events',
      'Jobs',
      'Business',
      'Promotions',
      'Professionals',
      'Marketplace',
      'Community',
      'Services',
      'Gallery',
    };

    for (final doc in docs) {
      final raw = (doc.data()['category'] ?? '').toString().trim();
      if (raw.isNotEmpty) categories.add(raw);
    }

    final list = categories.where((c) => c != 'All').toList()..sort();
    return ['All', ...list];
  }

  IconData _iconForCategory(String category) {
    final key = category.toLowerCase();
    if (key.contains('event')) return Icons.event_outlined;
    if (key.contains('job')) return Icons.work_outline;
    if (key.contains('search')) return Icons.search_outlined;
    if (key.contains('alert')) return Icons.notifications_none;
    if (key.contains('promotion') || key.contains('offer')) return Icons.local_offer_outlined;
    if (key.contains('professional')) return Icons.verified_user_outlined;
    if (key.contains('business')) return Icons.business_center_outlined;
    if (key.contains('market')) return Icons.storefront_outlined;
    if (key.contains('community')) return Icons.groups_outlined;
    if (key.contains('service')) return Icons.miscellaneous_services_outlined;
    if (key.contains('gallery') || key.contains('photo')) return Icons.photo_library_outlined;
    return Icons.grid_view_rounded;
  }

  IconData _iconForJobCategory(String category) {
    final key = category.toLowerCase();
    if (key.contains('miscellaneous') || key.contains('other')) return Icons.category_outlined;
    if (key.contains('clean')) return Icons.cleaning_services_outlined;
    if (key.contains('mechanic')) return Icons.build_circle_outlined;
    if (key.contains('car wash')) return Icons.local_car_wash_outlined;
    if (key.contains('photo') || key.contains('video')) return Icons.perm_media_outlined;
    if (key.contains('dj')) return Icons.music_note_outlined;
    if (key.contains('electric')) return Icons.electrical_services_outlined;
    if (key.contains('paint')) return Icons.format_paint_outlined;
    if (key.contains('furniture') || key.contains('carpentry')) return Icons.chair_outlined;
    if (key.contains('garden')) return Icons.yard_outlined;
    if (key.contains('catering')) return Icons.restaurant_outlined;
    if (key.contains('decor')) return Icons.celebration_outlined;
    if (key.contains('medical') || key.contains('doctor') || key.contains('pharmacist')) return Icons.medical_services_outlined;
    if (key.contains('legal')) return Icons.balance_outlined;
    if (key.contains('translator')) return Icons.translate_outlined;
    if (key.contains('airport') || key.contains('pickup') || key.contains('logistics')) return Icons.airport_shuttle_outlined;
    if (key.contains('taxi') || key.contains('truck')) return Icons.local_shipping_outlined;
    return Icons.miscellaneous_services_outlined;
  }

  void _handleCategoryTap(String category) {
    final key = category.toLowerCase();

    final hasDirectServiceCategory = _homeJobCategories
        .map((value) => value.toLowerCase())
        .contains(key);
    if (hasDirectServiceCategory) {
      if (widget.onOpenSearch != null) {
        widget.onOpenSearch!.call();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JobsScreen(
            initialCategory: category,
            showSubmissionOnly: true,
          ),
        ),
      );
      return;
    }

    if (key == 'all' || key.contains('promotion') || key.contains('offer')) {
      setState(() {
        _selectedFeedCategory = category;
      });
      _tabController.animateTo(0);
      return;
    }

    if (key.contains('professional')) {
      if (widget.onOpenSearch != null) {
        widget.onOpenSearch!.call();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HomeScreen(initialTabIndex: 1)),
      );
      return;
    }

    if (key.contains('event')) {
      if (widget.onOpenEvents != null) {
        widget.onOpenEvents!.call();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HomeScreen(initialTabIndex: 2)),
      );
      return;
    }

    if (key.contains('job') || key.contains('service')) {
      if (widget.onOpenSearch != null) {
        widget.onOpenSearch!.call();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JobsScreen()),
      );
      return;
    }

    if (key.contains('business')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BusinessDirectoryScreen()),
      );
      return;
    }

    if (key.contains('market')) {
      if (widget.onOpenMarket != null) {
        widget.onOpenMarket!.call();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MarketScreen()),
      );
      return;
    }

    if (key.contains('community')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CommunityGroupsScreen()),
      );
      return;
    }

    if (key.contains('gallery') || key.contains('photo')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GalleryScreen()),
      );
      return;
    }

    setState(() {
      _selectedFeedCategory = category;
    });
    _tabController.animateTo(0);
  }

  Widget _buildDynamicCategoryFilters(List<String> categories) {
    final visibleCategories = categories.where((item) => item != 'All').toList();
    if (visibleCategories.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleCategories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final item = visibleCategories[index];
        final selected = _selectedFeedCategory == item;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _handleCategoryTap(item),
            child: Ink(
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF59E0B) : const Color(0xFF0E2E1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? const Color(0xFFF5C542) : const Color(0x66F5C542),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _iconForCategory(item),
                      size: 32,
                      color: selected ? const Color(0xFF061E12) : const Color(0xFFF5C542),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? const Color(0xFF061E12) : const Color(0xFFF5C542),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeJobCategoryGrid() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse Job Categories',
            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap any category to open its service submission form directly.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _homeJobCategories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.24,
            ),
            itemBuilder: (context, index) {
              final category = _homeJobCategories[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => JobsScreen(
                          initialCategory: category,
                          showSubmissionOnly: true,
                        ),
                      ),
                    );
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color(0xFF123222),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x44F59E0B)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(_iconForJobCategory(category), color: const Color(0xFFF59E0B)),
                          Text(
                            category,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainCategoryHubs() {
    Widget categoryCard({
      required String title,
      required VoidCallback onTap,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFF0E2E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x44F59E0B)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(_iconForCategory(title), color: const Color(0xFFF59E0B), size: 34),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Main Categories',
          style: TextStyle(color: Color(0xFFF59E0B), fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [
            categoryCard(
              title: 'Jobs & Services',
              onTap: () {
                if (widget.onOpenSearch != null) {
                  widget.onOpenSearch!.call();
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JobsScreen()),
                );
              },
            ),
            categoryCard(
              title: 'Market',
              onTap: () {
                if (widget.onOpenMarket != null) {
                  widget.onOpenMarket!.call();
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MarketScreen()),
                );
              },
            ),
            categoryCard(
              title: 'Events',
              onTap: () {
                if (widget.onOpenEvents != null) {
                  widget.onOpenEvents!.call();
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EventsScreen()),
                );
              },
            ),
            categoryCard(
              title: 'Business',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BusinessDirectoryScreen()),
                );
              },
            ),
            categoryCard(
              title: 'Community',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CommunityGroupsScreen()),
                );
              },
            ),
            categoryCard(
              title: 'Professionals',
              onTap: () {
                if (widget.onOpenSearch != null) {
                  widget.onOpenSearch!.call();
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HomeScreen(initialTabIndex: 1)),
                );
              },
            ),
            categoryCard(
              title: 'Gallery',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GalleryScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _refreshAllHomeTabs() async {
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildHomeFeedTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildNewsOffersMarquee(),
        const SizedBox(height: 12),
        _buildVerifiedProfessionalsStrip(),
        const SizedBox(height: 10),
        _buildMainCategoryHubs(),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0E2E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            tr('home_menu_info'),
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final activeDocs = docs.where((doc) {
              final data = doc.data();
              return _isAnnouncementActive(data) &&
                  _announcementMatchesCategory(data, _selectedFeedCategory);
            }).toList();

            if (activeDocs.isEmpty) {
              return _buildEmptyState(tr('feed_empty'));
            }

            return Column(
              children: activeDocs.map((doc) {
                final data = doc.data();
                final title = (data['title'] ?? '').toString();
                final body = (data['body'] ?? '').toString();
                final category = (data['category'] ?? 'General').toString();
                final isServiceListing = _isServiceListingAnnouncement(data);

                return Card(
                  color: const Color(0xFF0E2E1E),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isServiceListing ? () => _openServiceListingFromAnnouncement(data, announcementId: doc.id) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xFF061E12),
                                child: Icon(Icons.campaign_outlined, color: Color(0xFFF59E0B), size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title.isEmpty ? 'Announcement' : title,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'from Admin • $category',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              if (isServiceListing)
                                const Icon(Icons.chevron_right, color: Color(0xFFF59E0B), size: 18),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            body,
                            style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, height: 1.4),
                          ),
                          if (isServiceListing) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to open full profile and contact options',
                              style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFF59E0B)),
                                  foregroundColor: const Color(0xFFF59E0B),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => _openServiceListingFromAnnouncement(data, announcementId: doc.id),
                                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                label: const Text('Message'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildConnectHabeshaSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF0C2618),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'connect HABESHA',
            style: TextStyle(
              color: Color(0xFFF5C542),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CityChip(label: 'London', color: const Color(0xFF2F6BFF), onTap: () => _openCityExplorer('London')),
              _CityChip(label: 'Paris', color: const Color(0xFFF4C430), onTap: () => _openCityExplorer('Paris')),
              _CityChip(label: 'Frankfurt', color: const Color(0xFFE53935), onTap: () => _openCityExplorer('Frankfurt')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewFeaturedEventCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_busy, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Featured Event Ended',
                  style: TextStyle(color: Color(0xFFF59E0B), fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'The ESCFE 2026 featured banner has ended automatically. Add the next event to keep this section updated by default.',
            style: TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                ),
                onPressed: () {
                  _tabController.animateTo(2);
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add New Event'),
              ),
              StreamBuilder<bool>(
                stream: _adminAccessStream,
                initialData: false,
                builder: (context, snapshot) {
                  final canSee = snapshot.data == true;
                  if (!canSee) return const SizedBox.shrink();

                  return OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                    ),
                    onPressed: () {
                      () async {
                        final navigator = Navigator.of(context);
                        final canOpen = await AccessControl.ensureAdminAccess(
                          context,
                          actionLabel: 'Open Admin Panel',
                        );
                        if (!canOpen || !mounted) return;
                        navigator.push(
                          MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                        );
                      }();
                    },
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Open Admin Panel'),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewsOffersMarquee() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF163B2A), Color(0xFF0F2E21), Color(0xFF153326)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5C542).withValues(alpha: 0.85)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(Icons.campaign_outlined, color: Color(0xFFF5C542), size: 14),
                SizedBox(width: 6),
                Text(
                  'SPONSORED NEWS',
                  style: TextStyle(
                    color: Color(0xFFF5C542),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 62,
            child: PageView.builder(
              controller: _newsTickerController,
              itemCount: _newsOffers.length,
              onPageChanged: (index) {
                _newsTickerIndex = index;
              },
              itemBuilder: (context, index) {
                final item = _newsOffers[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OfferDetailScreen(
                          title: item['title']!,
                          details: item['details']!,
                          promoCode: item['code']!,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF102C1F),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0x99F5C542)),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5C542),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'SPONSORED',
                              style: TextStyle(
                                color: Color(0xFF102C1F),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFFFD978),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Tap to open details • ${item['code']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFEFD38A),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFF5C542)),
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

  Widget _buildProfessionalsTab() {
    final professionals = _displayProfessionals;
    final sorted = [...professionals]
      ..sort((a, b) {
        final aDist = _distanceKmFor(a);
        final bDist = _distanceKmFor(b);
        if (aDist == null && bDist == null) return 0;
        if (aDist == null) return 1;
        if (bDist == null) return -1;
        return aDist.compareTo(bDist);
      });

    final nearby = _userPosition == null
        ? sorted
        : sorted.where((p) {
            final km = _distanceKmFor(p);
            return km != null && km <= 80;
          }).toList();

    final filtered = nearby.isNotEmpty ? nearby : sorted;

    if (filtered.isEmpty) {
      return _buildEmptyState('No registered professionals match your criteria.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length + (_isLoadingLocation ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoadingLocation && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0E2E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                tr('finding_nearby_providers'),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          );
        }

        final adjustedIndex = index - (_isLoadingLocation ? 1 : 0);
        final p = filtered[adjustedIndex];
        return Card(
          color: const Color(0xFF0E2E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: p.verificationStage == 'vip'
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                  : Colors.white10,
              width: p.verificationStage == 'vip' ? 1.5 : 1,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF061E12),
                      backgroundImage: NetworkImage(p.imageUrl ?? 'https://via.placeholder.com/150'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildVerificationBadge(p.verificationStage),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.category,
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white54, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${p.city}, ${p.country}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              if (_distanceKmFor(p) != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${_distanceKmFor(p)!.toStringAsFixed(1)} km',
                                  style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  p.bio,
                  style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, height: 1.4),
                ),
                _buildDynamicReviewSection(targetType: 'provider', targetId: p.id),
                const Divider(color: Colors.white10, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Spacer(),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Colors.white70, size: 18),
                          onPressed: () => _shareProfileLink(p),
                        ),
                        TextButton(
                          onPressed: () => _showReviewDialog(
                            targetType: 'provider',
                            targetId: p.id,
                            subjectLabel: p.name,
                          ),
                          child: Text(tr('rate_review'), style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12)),
                        ),
                        if (p.whatsapp != null)
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFF59E0B), size: 18),
                            onPressed: () {
                              if (!AccessControl.ensureVerified(context, actionLabel: tr('contact'))) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Starting high-trust discussion with ${p.name}')),
                              );
                            },
                          ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF061E12),
                            foregroundColor: const Color(0xFFF59E0B),
                            side: const BorderSide(color: Color(0xFFF59E0B), width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: () {
                            if (!AccessControl.ensureVerified(context, actionLabel: tr('contact'))) {
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ServiceProfileDetailScreen(
                                  title: p.name,
                                  category: p.category,
                                  description: p.bio,
                                  providerName: p.name,
                                  city: '${p.city}, ${p.country}',
                                  phone: p.phone,
                                  email: p.email ?? '',
                                  website: p.website ?? '',
                                  userId: p.userId,
                                  imageUrl: p.imageUrl ?? '',
                                  postId: p.id,
                                  postType: 'verified_professionals',
                                ),
                              ),
                            );
                          },
                          child: const Text('Open Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventsTab() {
    final filtered = _events;

    if (filtered.isEmpty) {
      return _buildEmptyState('No upcoming diaspora community events scheduled.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final e = filtered[index];
        return Card(
          color: const Color(0xFF0E2E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (e.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    e.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            e.category,
                            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                            const SizedBox(width: 4),
                            const Text('Verified Host', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Color(0xFFF59E0B), size: 14),
                                const SizedBox(width: 6),
                                Text(e.date, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, color: Colors.white54, size: 14),
                                const SizedBox(width: 6),
                                Text(e.time, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: const Color(0xFF061E12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onPressed: () {
                            if (!AccessControl.ensureVerified(context, actionLabel: tr('rsvp'))) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('RSVP Submitted for ${e.title}')),
                            );
                          },
                          child: Text(
                            e.ticketPrice == 0 ? 'RSVP Free' : 'Get Ticket (€${e.ticketPrice})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobsTab() {
    final filtered = _jobs;

    if (filtered.isEmpty) {
      return _buildEmptyState('No open job roles listed in this region.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final j = filtered[index];
        return Card(
          color: const Color(0xFF0E2E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        j.title,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (j.verified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                        ),
                        child: const Text('Verified', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  j.authorName,
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  j.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                _buildDynamicReviewSection(targetType: 'job', targetId: j.id),
                const Divider(color: Colors.white10, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '€${j.price}/hr',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _showReviewDialog(
                            targetType: 'job',
                            targetId: j.id,
                            subjectLabel: j.authorName,
                          ),
                          child: Text(
                            tr('rate_review'),
                            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF061E12),
                            foregroundColor: const Color(0xFFF59E0B),
                            side: const BorderSide(color: Color(0xFFF59E0B)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            if (!AccessControl.ensureVerified(context, actionLabel: tr('apply_now'))) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Contacting ${j.authorName} regarding Chef position.')),
                            );
                          },
                          child: const Text('Apply Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarketplacePlaceholder() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 24),
      children: [
        _buildEmptyState(tr('marketplace_placeholder')),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(String stage) {
    Color badgeColor = Colors.white24;
    String label = tr('verified');
    if (stage == 'vip') {
      badgeColor = const Color(0xFFF59E0B);
      label = tr('vip_gold');
    } else if (stage == 'professional') {
      badgeColor = Colors.cyan;
      label = tr('platinum');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        border: Border.all(color: badgeColor, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showContactSheet(BuildContext context, Professional p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E2E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${tr('contact')} ${p.name}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(p.category, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white12, height: 24),
              ListTile(
                leading: const Icon(Icons.phone, color: Color(0xFFF59E0B)),
                title: Text(p.phone, style: const TextStyle(color: Colors.white)),
                subtitle: Text(tr('direct_phone_number'), style: const TextStyle(color: Colors.white38)),
                onTap: () {},
              ),
              if (p.whatsapp != null)
                ListTile(
                  leading: const Icon(Icons.message, color: Color(0xFF10B981)),
                  title: Text(p.whatsapp!, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(tr('send_whatsapp_message'), style: const TextStyle(color: Colors.white38)),
                  onTap: () {},
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFF59E0B)),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF0A2418),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF123222), Color(0xFF0A2418)]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF081B12),
                      border: Border.all(color: const Color(0xFFF5C542), width: 1.2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/branding/euro_habesha_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.brightness_5_outlined,
                          color: Color(0xFFF5C542),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'EURO ',
                          style: GoogleFonts.cinzel(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        TextSpan(
                          text: 'HABESHA',
                          style: GoogleFonts.cinzel(
                            color: const Color(0xFFF5C542),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(Icons.work_outline, 'Jobs & Services', () => _tabController.animateTo(3)),
            _drawerItem(Icons.storefront_outlined, 'Marketplace', () => _tabController.animateTo(4)),
            _drawerItem(Icons.event_outlined, 'Events', () => _tabController.animateTo(2)),
            _drawerItem(
              Icons.business_center_outlined,
              'Business',
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BusinessDirectoryScreen()),
              ),
            ),
            _drawerItem(Icons.verified_user_outlined, 'Professionals', () => _tabController.animateTo(1)),
            _drawerItem(Icons.groups_outlined, 'Community', () => _tabController.animateTo(0)),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2418),
        toolbarHeight: 132,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFFF5C542)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Row(
            children: [
              Container(
              width: 92,
              height: 92,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF081B12),
                border: Border.all(color: const Color(0xFFF5C542), width: 1.4),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/branding/euro_habesha_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.brightness_5_outlined,
                    color: Color(0xFFF5C542),
                  ),
                ),
              ),
            ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EURO',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'HABESHA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cinzel(
                          color: const Color(0xFFF5C542),
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StreamBuilder<bool>(
                      stream: _adminAccessStream,
                      initialData: false,
                      builder: (context, snapshot) {
                        if (snapshot.data != true) return const SizedBox.shrink();

                        return IconButton(
                          onPressed: () {
                            () async {
                              final navigator = Navigator.of(context);
                              final canOpen = await AccessControl.ensureAdminAccess(
                                context,
                                actionLabel: 'Open Admin Panel',
                              );
                              if (!canOpen || !mounted) return;
                              navigator.push(
                                MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                              );
                            }();
                          },
                          icon: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFFF5C542), size: 16),
                          padding: const EdgeInsets.all(2),
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 22),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          RefreshIndicator(onRefresh: _refreshAllHomeTabs, child: _buildHomeFeedTab()),
          RefreshIndicator(onRefresh: _refreshAllHomeTabs, child: _buildProfessionalsTab()),
          RefreshIndicator(onRefresh: _refreshAllHomeTabs, child: _buildEventsTab()),
          RefreshIndicator(onRefresh: _refreshAllHomeTabs, child: _buildJobsTab()),
          RefreshIndicator(onRefresh: _refreshAllHomeTabs, child: _buildMarketplacePlaceholder()),
        ],
      ),
      bottomNavigationBar: _isBannerReady && _bannerAd != null
          ? SafeArea(
              top: false,
              maintainBottomViewPadding: true,
              child: Container(
                color: const Color(0xFF061E12),
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  height: _bannerAd!.size.height.toDouble(),
                  width: _bannerAd!.size.width.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            )
          : null,
    );
  }
}

class _StatsItem extends StatelessWidget {
  const _StatsItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _PromoBannerItem {
  const _PromoBannerItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.actionLabel,
    this.imageUrl = '',
    this.externalLink = '',
  });

  final String title;
  final String subtitle;
  final String description;
  final String category;
  final String actionLabel;
  final String imageUrl;
  final String externalLink;
}

class CommunityMapScreen extends StatelessWidget {
  const CommunityMapScreen({
    super.key,
    required this.cityCoordinates,
    required this.professionals,
    required this.events,
    required this.jobs,
    required this.onCitySelected,
  });

  final Map<String, (double lat, double lng)> cityCoordinates;
  final List<Professional> professionals;
  final List<EventItem> events;
  final List<Job> jobs;
  final void Function(String city) onCitySelected;

  @override
  Widget build(BuildContext context) {
    final cityStats = <String, int>{};
    for (final p in professionals) {
      cityStats[p.city] = (cityStats[p.city] ?? 0) + 1;
    }
    for (final e in events) {
      cityStats[e.city] = (cityStats[e.city] ?? 0) + 1;
    }
    for (final j in jobs) {
      cityStats[j.city] = (cityStats[j.city] ?? 0) + 1;
    }

    final cityNames = cityCoordinates.keys.toList()..sort();
    final circles = cityNames.map((city) {
      final point = cityCoordinates[city]!;
      final count = cityStats[city] ?? 0;
      final radius = (22 + (count * 8)).toDouble();
      return CircleMarker(
        point: LatLng(point.$1, point.$2),
        radius: radius,
        color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
        borderColor: const Color(0xFFD4AF37),
        borderStrokeWidth: 1.2,
      );
    }).toList();

    final markers = cityNames.map((city) {
      final point = cityCoordinates[city]!;
      final count = cityStats[city] ?? 0;
      return Marker(
        point: LatLng(point.$1, point.$2),
        width: 110,
        height: 68,
        child: GestureDetector(
          onTap: () => onCitySelected(city),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E2E1E),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.75)),
                ),
                child: Text(
                  '$city ($count)',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 3),
              const Icon(Icons.location_on, size: 18, color: Color(0xFFF59E0B)),
            ],
          ),
        ),
      );
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        title: const Text('Community Map'),
        backgroundColor: const Color(0xFF0E2E1E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF123222), Color(0xFF0A2418), Color(0xFF1F3F2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.35)),
            ),
            child: const Text(
              'Community density across Europe. Tap a city to view all members, events, and services for that location.',
              style: TextStyle(color: Color(0xFFE8D79B), height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 420,
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(51.0, 10.0),
                  initialZoom: 4.2,
                  minZoom: 3.0,
                  maxZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.euro.habesha',
                  ),
                  CircleLayer(circles: circles),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'City Intensity (Community Density)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cityNames.map((city) {
              final count = cityStats[city] ?? 0;
              return ActionChip(
                backgroundColor: const Color(0xFF0E2E1E),
                side: const BorderSide(color: Colors.white12),
                label: Text(
                  '$city ($count)',
                  style: const TextStyle(color: Color(0xFFE8D79B), fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: () => onCitySelected(city),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class CityExplorerScreen extends StatelessWidget {
  const CityExplorerScreen({
    super.key,
    required this.city,
    required this.professionals,
    required this.events,
    required this.jobs,
  });

  final String city;
  final List<Professional> professionals;
  final List<EventItem> events;
  final List<Job> jobs;

  @override
  Widget build(BuildContext context) {
    final cityProfessionals = professionals.where((p) => p.city.toLowerCase() == city.toLowerCase()).toList();
    final cityEvents = events.where((e) => e.city.toLowerCase() == city.toLowerCase()).toList();
    final cityJobs = jobs.where((j) => j.city.toLowerCase() == city.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        title: Text('$city Community Hub'),
        backgroundColor: const Color(0xFF0E2E1E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              'Location-specific content for $city: members, events, and services.',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 12),
          _CitySectionTitle(title: 'Community Members (${cityProfessionals.length})'),
          ...cityProfessionals.map(
            (p) => Card(
              child: ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                subtitle: Text(p.category, style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.verified_outlined, color: Color(0xFFF59E0B)),
              ),
            ),
          ),
          if (cityProfessionals.isEmpty) const _CityEmpty(text: 'No community members listed yet for this city.'),
          const SizedBox(height: 10),
          _CitySectionTitle(title: 'Events (${cityEvents.length})'),
          ...cityEvents.map(
            (e) => Card(
              child: ListTile(
                title: Text(e.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                subtitle: Text('${e.date} • ${e.time}', style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.event_outlined, color: Color(0xFFF59E0B)),
              ),
            ),
          ),
          if (cityEvents.isEmpty) const _CityEmpty(text: 'No events listed yet for this city.'),
          const SizedBox(height: 10),
          _CitySectionTitle(title: 'Services & Jobs (${cityJobs.length})'),
          ...cityJobs.map(
            (j) => Card(
              child: ListTile(
                title: Text(j.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                subtitle: Text(j.category, style: const TextStyle(color: Colors.white70)),
                trailing: Text(
                  j.price > 0 ? 'EUR ${j.price.toStringAsFixed(0)}' : 'Open',
                  style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          if (cityJobs.isEmpty) const _CityEmpty(text: 'No services listed yet for this city.'),
        ],
      ),
    );
  }
}

class _CitySectionTitle extends StatelessWidget {
  const _CitySectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _CityEmpty extends StatelessWidget {
  const _CityEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white54)),
    );
  }
}

