import 'package:flutter/material.dart';
import 'dart:async'; 
import 'package:geolocator/geolocator.dart';
import 'business_screen.dart';
import 'events_screen.dart';
import 'community_screen.dart';
import 'jobs_screen.dart';
import 'marketplace_screen.dart';
import 'professionals_screen.dart';
import 'admin_panel_screen.dart';
import 'app_session.dart';
import 'admin_updates_feed.dart';
import 'dynamic_submission_screen.dart';
import 'public_feed_section.dart';
import 'sponsored_banner_section.dart';
import 'community_posts_section.dart';
import 'nearby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12); 
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40); 

  String currentLang = 'English';
  String userLocation = 'Requesting GPS Location...';

  final String adminEmail = "getafricshow1@gmail.com"; 

  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _sliderTimer;

  late final PageController _spiritualPageController;
  int _currentSpiritualPage = 0;
  Timer? _spiritualSliderTimer;

  int _tickerIndex = 0;
  Timer? _tickerTimer;
  
  final List<Map<String, dynamic>> tickerMessages = [
    {'id': 'legal', 'title': '⚖️ Trusted Legal Services', 'desc': 'Connect with Habesha immigration lawyers in Paris & Rome.'},
    {'id': 'transport', 'title': '🚚 Fast Cargo & Transport', 'desc': 'Reliable heavy vehicle logistics across France and Germany.'},
    {'id': 'verify', 'title': '⭐ Get Verified Today', 'desc': 'Upgrade to Silver or VIP Gold badge for your business profile.'},
    {'id': 'events', 'title': '🎉 Habesha Community Events', 'desc': 'Join upcoming traditional celebrations and cultural meetings.'},
  ];

  final List<Map<String, dynamic>> recentUpdates = [
    {
      'title': 'Habesha Market',
      'subtitle': 'Lyon, France',
      'time': '2h ago',
      'image': 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',
      'type': 'market'
    },
    {
      'title': 'Getafric Production',
      'subtitle': 'Lyon (Photo & Video)',
      'time': '5h ago',
      'image': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=800&q=80',
      'type': 'pro'
    },
    {
      'title': 'Ethiopian New Year',
      'subtitle': 'Paris Celebration',
      'time': '1d ago',
      'image': 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&w=800&q=80',
      'type': 'event'
    },
  ];

  final List<Map<String, dynamic>> spiritualCommunities = [
    {
      'category': 'COMMUNITY',
      'title': 'Ethiopian Orthodox Tewahedo',
      'subtitle': 'Sunday Service • Lyon',
      'image': 'https://images.unsplash.com/photo-1518005020951-eccb494ad742?auto=format&fit=crop&w=800&q=80',
      'badgeColor': Colors.redAccent,
      'type': 'community'
    },
    {
      'category': 'COMMUNITY',
      'title': 'Habesha Muslim Jama\'ah',
      'subtitle': 'Jumu\'ah Prayer • Paris',
      'image': 'https://images.unsplash.com/photo-1564769625905-50e93615e769?auto=format&fit=crop&w=800&q=80',
      'badgeColor': Colors.greenAccent,
      'type': 'community'
    },
    {
      'category': 'COMMUNITY',
      'title': 'Ethiopian Protestant Fellowship',
      'subtitle': 'Worship & Praise • Lyon',
      'image': 'https://images.unsplash.com/photo-1490122417551-6ee9691429d0?auto=format&fit=crop&w=800&q=80',
      'badgeColor': Colors.lightBlueAccent,
      'type': 'community'
    },
  ];

  final List<Map<String, dynamic>> verticalFeed = [
    {
      'category': 'EVENT',
      'title': 'Ethiopian New Year Concert',
      'subtitle': 'Le Zénith Paris • Sept 11',
      'image': 'https://images.unsplash.com/photo-1540039155732-d6749b132338?auto=format&fit=crop&w=800&q=80',
      'badgeColor': Colors.orangeAccent,
      'type': 'event',
    },
    {
      'category': 'BUSINESS',
      'title': 'Lucy Habesha Restaurant',
      'subtitle': 'Authentic Cuisine • Lyon',
      'image': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=800&q=80',
      'badgeColor': const Color(0xFFFFD700),
      'type': 'business',
    },
    {
      'category': 'PROFESSIONAL',
      'title': 'Dr. Selamawit T.',
      'subtitle': 'Verified Pediatrician • Paris',
      'image': 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=800&q=80',
      'badgeColor': Colors.blueAccent,
      'type': 'pro',
    },
    {
      'category': 'JOB / SERVICE',
      'title': 'Habesha Modern Hair Salon',
      'subtitle': 'Barber & Hairdresser • Lyon',
      'image': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=800&q=80',
      'badgeColor': Colors.greenAccent,
      'type': 'job',
    },
    {
      'category': 'MARKET',
      'title': 'Teff & Traditional Spices',
      'subtitle': 'Habesha Supermarket • Lyon',
      'image': 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=800&q=80',
      'badgeColor': Colors.purpleAccent,
      'type': 'market',
    },
  ];

  final Map<String, Map<String, String>> texts = {
    'Categories': {'English': 'Categories', 'Amharic': 'ምድቦች', 'French': 'Catégories', 'Dutch': 'Categorieën'},
    'Recent Updates': {'English': 'Featured Updates', 'Amharic': 'ዋና ዋና መረጃዎች', 'French': 'Mises à jour à proximité', 'Dutch': 'Aanbevolen updates'},
    'Jobs': {'English': 'Jobs', 'Amharic': 'ስራ', 'French': 'Emplois', 'Dutch': 'Banen'},
    'Businesses': {'English': 'Businesses', 'Amharic': 'ንግድ', 'French': 'Commerces', 'Dutch': 'Bedrijven'},
    'Market': {'English': 'Market', 'Amharic': 'ገበያ', 'French': 'Marché', 'Dutch': 'Markt'},
    'Pros': {'English': 'Professionals', 'Amharic': 'ባለሙያዎች', 'French': 'Professionnels', 'Dutch': 'Professionals'},
    'Events': {'English': 'Events', 'Amharic': 'ክስተት', 'French': 'Événements', 'Dutch': 'Evenementen'},
    'Community': {'English': 'Community', 'Amharic': 'ማህበረሰብ', 'French': 'Communauté', 'Dutch': 'Gemeenschap'},
    'Nearby': {'English': 'Nearby', 'Amharic': 'በአቅራቢያ', 'French': 'À proximité', 'Dutch': 'In de buurt'},
  };

  String getTxt(String key) => texts[key]![currentLang]!;

  @override
  void initState() {
    super.initState();
    final languageCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    currentLang = switch (languageCode) {
      'fr' => 'French',
      'nl' => 'Dutch',
      'am' => 'Amharic',
      _ => 'English',
    };
    _pageController = PageController(initialPage: 0, viewportFraction: 0.75);
    _spiritualPageController = PageController(initialPage: 0, viewportFraction: 0.85);

    _sliderTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < recentUpdates.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    });

    _spiritualSliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentSpiritualPage < spiritualCommunities.length - 1) {
        _currentSpiritualPage++;
      } else {
        _currentSpiritualPage = 0;
      }
      if (_spiritualPageController.hasClients) {
        _spiritualPageController.animateToPage(_currentSpiritualPage, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });

    _tickerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _tickerIndex = (_tickerIndex + 1) % tickerMessages.length;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _spiritualSliderTimer?.cancel();
    _tickerTimer?.cancel();
    _pageController.dispose();
    _spiritualPageController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => userLocation = 'Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => userLocation = 'Location permission denied.');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() => userLocation = 'Location permissions permanently denied.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        userLocation = 'Lyon, France (${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}) - GPS Active';
      });
    } catch (e) {
      setState(() => userLocation = 'Lyon, France (GPS Active)');
    }
  }

  void _showAuthDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: cardGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/euro_habesha_logo.png', height: 60, errorBuilder: (c, e, s) => Icon(Icons.public, color: primaryGold, size: 50)),
              const SizedBox(height: 15),
              Text('Join Euro Habesha', style: TextStyle(color: primaryGold, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Create an account to post, message, and connect with the community.', style: TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 25),
              _buildAuthButton(Icons.g_mobiledata, 'Continue with Google', Colors.white, Colors.black, () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              }),
              const SizedBox(height: 12),
              _buildAuthButton(Icons.apple, 'Continue with Apple', Colors.black, Colors.white, () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Apple sign-in will be enabled for iOS/TestFlight builds.')),
                );
              }),
              const SizedBox(height: 12),
              _buildAuthButton(Icons.email, 'Sign Up with Email', primaryGold, primaryDarkGreen, () {
                Navigator.pop(context);
                _showEmailAuthSheet();
              }),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Maybe Later', style: TextStyle(color: Colors.white54)),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _simulateAuthAction(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: cardGreen));
  }

  void _showEmailAuthSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: primaryDarkGreen,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign Up with Email', style: TextStyle(color: primaryGold, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: 'Email address', hintStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: cardGreen, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: 'Password', hintStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: cardGreen, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGold, minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                Navigator.pop(context);
                _simulateAuthAction('Account created successfully!');
              },
              child: Text('Register', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthButton(IconData icon, String label, Color bgColor, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: bgColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        icon: Icon(icon, color: textColor, size: 24),
        label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {});
  }

  void _handleTickerTap(String actionId) {
    if (actionId == 'verify') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const DynamicSubmissionScreen(type: SubmissionType.verification)));
    } else if (actionId == 'transport' || actionId == 'legal') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const JobsScreen()));
    } else if (actionId == 'events') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const EventsScreen()));
    }
  }

  void _handleUpdateTap(String type) {
    if (type == 'market') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => MarketplaceScreen()));
    } else if (type == 'pro') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfessionalsScreen()));
    } else if (type == 'event') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const EventsScreen()));
    } else if (type == 'business') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const BusinessDirectoryScreen()));
    } else if (type == 'job') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const JobsScreen()));
    } else if (type == 'community') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityScreen()));
    }
  }

  Widget _buildImageFallback() {
    return Container(
      width: 75,
      height: 75,
      color: Colors.white.withOpacity(0.1),
      child: const Icon(Icons.image_not_supported, color: Colors.white38, size: 24),
    );
  }

  Widget _buildFeedCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _handleUpdateTap(item['type']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardGreen,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['image'],
                width: 75,
                height: 75,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildImageFallback(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item['badgeColor'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: item['badgeColor'].withOpacity(0.5)),
                    ),
                    child: Text(
                      item['category'],
                      style: TextStyle(color: item['badgeColor'], fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item['title'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['subtitle'],
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSpiritualSlideCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _handleUpdateTap(item['type']),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardGreen,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: primaryGold.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item['image'],
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildImageFallback(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item['badgeColor'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: item['badgeColor'].withOpacity(0.5)),
                    ),
                    child: Text(
                      item['category'],
                      style: TextStyle(color: item['badgeColor'], fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title'],
                    style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['subtitle'],
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: primaryGold, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTicker = tickerMessages[_tickerIndex];

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      drawer: _buildSideDrawer(context, primaryDarkGreen, primaryGold),
      appBar: AppBar(
        toolbarHeight: 90, 
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/euro_habesha_logo.png', height: 70, errorBuilder: (c, e, s) => Icon(Icons.public, color: primaryGold, size: 50)),
            const SizedBox(width: 12),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                children: [
                  TextSpan(text: 'EURO ', style: TextStyle(color: primaryGold)),
                  const TextSpan(text: 'HABESHA', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: primaryDarkGreen,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryGold),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryDarkGreen,
          backgroundColor: primaryGold,
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NearbyScreen()));
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: cardGreen,
                    child: Row(
                      children: [
                        const Icon(Icons.near_me, color: Color(0xFFFFD700), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nearby / À proximité • $userLocation', 
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryGold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Radar 📍', style: TextStyle(color: Color(0xFF061E12), fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                GestureDetector(
                  onTap: () => _handleTickerTap(currentTicker['id']!),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00332C),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.2), 
                            shape: BoxShape.circle
                          ),
                          child: const Icon(Icons.notifications_active, color: Color(0xFFFFD700), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: Column(
                              key: ValueKey<int>(_tickerIndex),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentTicker['title'] ?? currentTicker['subtitle'] ?? 'Announcement', 
                                  style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 14)
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentTicker['desc'] ?? '', 
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Color(0xFFFFD700), size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(getTxt('Categories'), style: TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildGridCategory(getTxt('Jobs'), Icon(Icons.work, size: 26, color: primaryGold), context, const JobsScreen()),
                          _buildGridCategory(getTxt('Businesses'), Icon(Icons.storefront, size: 26, color: primaryGold), context, const BusinessDirectoryScreen()),
                          _buildGridCategory(getTxt('Market'), Icon(Icons.shopping_cart, size: 26, color: primaryGold), context, MarketplaceScreen()),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildGridCategory(getTxt('Pros'), Icon(Icons.verified_user, size: 26, color: primaryGold), context, const ProfessionalsScreen()),
                          _buildGridCategory(getTxt('Events'), Icon(Icons.event, size: 26, color: primaryGold), context, const EventsScreen()),
                          _buildGridCategory(getTxt('Community'), Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.church, size: 20, color: primaryGold), const SizedBox(width: 2), Icon(Icons.mosque, size: 20, color: primaryGold)]), context, const CommunityScreen()),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(getTxt('Recent Updates'), style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                
                SizedBox(
                  height: 210,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: recentUpdates.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final update = recentUpdates[index];
                      return GestureDetector(
                        onTap: () => _handleUpdateTap(update['type']),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: cardGreen,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: primaryGold.withOpacity(0.2), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                child: Image.network(
                                  update['image']!, 
                                  height: 110, 
                                  width: double.infinity, 
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 110, width: double.infinity, color: Colors.white.withOpacity(0.1),
                                    child: const Icon(Icons.image_not_supported, color: Colors.white38),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(update['title']!, style: TextStyle(color: primaryGold, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text(update['subtitle']!, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(update['time']!, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 30),

                const AdminUpdatesFeed(),
                const SponsoredBannerSection(),
                const CommunityPostsSection(),
                const PublicFeedSection(),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Live Community Feed', style: TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('All Categories', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.supervised_user_circle, color: primaryGold, size: 18),
                      const SizedBox(width: 8),
                      const Text('Spiritual Communities', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 115,
                  child: PageView.builder(
                    controller: _spiritualPageController,
                    itemCount: spiritualCommunities.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentSpiritualPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = spiritualCommunities[index];
                      return _buildSpiritualSlideCard(item);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: verticalFeed.length,
                    itemBuilder: (context, index) {
                      final item = verticalFeed[index];
                      return _buildFeedCard(item);
                    },
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideDrawer(BuildContext context, Color bgColor, Color goldColor) {
    return Drawer(
      backgroundColor: bgColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF004D40)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset('assets/images/euro_habesha_logo.png', height: 60, errorBuilder: (c, e, s) => Icon(Icons.public, size: 60, color: goldColor)),
                const SizedBox(height: 10),
                Text('Euro Habesha', style: TextStyle(color: goldColor, fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('Connect. Discover. Grow.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          
          _buildDrawerItem(const Icon(Icons.near_me, color: Color(0xFFFFD700)), 'Nearby / À proximité', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const NearbyScreen()));
          }, goldColor),
          _buildDrawerItem(const Icon(Icons.work, color: Color(0xFFFFD700)), 'Jobs & Services', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const JobsScreen()));
          }, goldColor),
          _buildDrawerItem(const Icon(Icons.storefront, color: Color(0xFFFFD700)), 'Businesses', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const BusinessDirectoryScreen()));
          }, goldColor),
          _buildDrawerItem(const Icon(Icons.shopping_cart, color: Color(0xFFFFD700)), 'Marketplace', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => MarketplaceScreen()));
          }, goldColor),
          _buildDrawerItem(const Icon(Icons.verified_user, color: Color(0xFFFFD700)), 'Professionals', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfessionalsScreen()));
          }, goldColor),
          _buildDrawerItem(const Icon(Icons.event, color: Color(0xFFFFD700)), 'Events', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const EventsScreen()));
          }, goldColor),
          _buildDrawerItem(const Icon(Icons.group, color: Color(0xFFFFD700)), 'Community', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityScreen()));
          }, goldColor),

          const Divider(color: Colors.white24),

          if (AppSession.isSuperAdmin)
            _buildDrawerItem(
              Icon(Icons.admin_panel_settings, color: goldColor), 
              'Admin Control Panel', 
              () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPanelScreen()));
              }, 
              goldColor
            ),

          _buildDrawerItem(const Icon(Icons.info_outline, color: Color(0xFFFFD700)), 'About Euro Habesha', () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: cardGreen,
                title: Text('Euro Habesha', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
                content: const Text(
                  'The ultimate Diaspora Trust Gateway connecting Ethiopians and Eritreans across Europe.\nVersion 1.0.2',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: goldColor)))
                ],
              ),
            );
          }, goldColor),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(Widget iconWidget, String title, VoidCallback onTap, Color goldColor) {
    return ListTile(
      leading: iconWidget, 
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)), 
      onTap: onTap,
    );
  }

  Widget _buildGridCategory(String title, Widget customIcon, BuildContext context, Widget destinationPage) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destinationPage)),
      child: Container(
        width: 110,
        height: 85,
        decoration: BoxDecoration(
          color: cardGreen,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: primaryGold.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customIcon,
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
