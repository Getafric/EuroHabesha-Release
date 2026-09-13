import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'business_screen.dart';
import 'status_badge_widget.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  double _selectedRadiusKm = 25.0;
  final List<double> _radiusOptions = [5.0, 10.0, 15.0, 25.0, 50.0];

  bool _isLocating = false;
  Position? _currentPosition;
  String _locationName = 'Detecting current GPS location...';

  final List<String> _popularCities = [
    'Use My GPS Location',
    'Lyon, France',
    'Paris, France',
    'Marseille, France',
    'Geneva, Switzerland',
    'Frankfurt, Germany',
    'Berlin, Germany',
    'Rome, Italy',
    'Brussels, Belgium',
    'Amsterdam, Netherlands',
    'Stockholm, Sweden',
    'London, UK',
  ];

  late String _selectedCityOption;

  final Map<String, _CityCoord> _cityCoordinates = {
    'Lyon, France': const _CityCoord(45.7640, 4.8357),
    'Paris, France': const _CityCoord(48.8566, 2.3522),
    'Marseille, France': const _CityCoord(43.2965, 5.3698),
    'Geneva, Switzerland': const _CityCoord(46.2044, 6.1432),
    'Frankfurt, Germany': const _CityCoord(50.1109, 8.6821),
    'Berlin, Germany': const _CityCoord(52.5200, 13.4050),
    'Rome, Italy': const _CityCoord(41.9028, 12.4964),
    'Brussels, Belgium': const _CityCoord(50.8503, 4.3517),
    'Amsterdam, Netherlands': const _CityCoord(52.3676, 4.9041),
    'Stockholm, Sweden': const _CityCoord(59.3293, 18.0686),
    'London, UK': const _CityCoord(51.5074, -0.1278),
  };

  // Sample database of businesses with known coordinates
  final List<Map<String, dynamic>> _allNearbyPlaces = [
    {
      'id': 'place_lucy',
      'title': 'Authentic Ethiopian Cuisine',
      'name': 'Lucy Habesha Restaurant',
      'location': 'Lyon, France',
      'address': '12 Rue de Marseille, 69007 Lyon, France',
      'lat': 45.7535,
      'lng': 4.8410,
      'rating': '4.9 (320 reviews)',
      'badge': 'Premium',
      'category': 'Restaurants / Food',
      'registration': 'SIRET: 123 456 789 00012',
      'phone': 'tel:+33400000000',
      'email': 'contact@lucyrestaurant.fr',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/33400000000',
      'openingHours': 'Tue - Sun: 12:00 - 23:00',
      'description': 'Experience the best authentic Ethiopian and Eritrean traditional food in Lyon. We offer Injera with various Wots, Tibs, and traditional coffee ceremonies.',
      'icon': Icons.restaurant,
      'gallery': [
        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&w=800&q=80',
      ],
      'reviews': [
        {'user': 'Miki C.', 'comment': 'Best Kitfo in town! Feels like home.', 'rating': '5.0'},
      ]
    },
    {
      'id': 'place_market_lyon',
      'title': 'Grocery & Traditional Spices',
      'name': 'Habesha Supermarket Lyon',
      'location': 'Lyon, France',
      'address': '8 Rue Paul Bert, 69003 Lyon, France',
      'lat': 45.7595,
      'lng': 4.8520,
      'rating': '4.8 (85 reviews)',
      'badge': 'Registered',
      'category': 'Grocery & Spices',
      'registration': 'SIRET: 456 789 123 00045',
      'phone': 'tel:+33411223344',
      'email': 'market@eurohabesha.eu',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/33411223344',
      'openingHours': 'Mon - Sat: 09:00 - 20:00',
      'description': 'Your one-stop shop for Teff, Berbere, Shiro, and imported traditional items. Fresh Injera available weekly.',
      'icon': Icons.storefront,
      'gallery': [
        'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',
      ],
      'reviews': [
        {'user': 'Getu A.', 'comment': 'They have everything I need.', 'rating': '4.9'},
      ]
    },
    {
      'id': 'place_eritrean_market',
      'title': 'Traditional Spices & Goods',
      'name': 'Red Sea Eritrean Market',
      'location': 'Lyon, France',
      'address': '22 Rue Garibaldi, 69007 Lyon, France',
      'lat': 45.7480,
      'lng': 4.8450,
      'rating': '4.7 (60 reviews)',
      'badge': 'Verified',
      'category': 'Grocery & Spices',
      'registration': 'SIRET: 789 123 456 00078',
      'phone': 'tel:+33478901234',
      'email': 'redsea@eurohabesha.eu',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/33478901234',
      'openingHours': 'Mon - Sat: 09:30 - 19:30',
      'description': 'Authentic Eritrean and Ethiopian grocery store, fresh coffee beans, spices and traditional household goods.',
      'icon': Icons.shopping_basket,
      'gallery': [],
      'reviews': []
    },
    {
      'id': 'place_getafric',
      'title': 'Photo & Video Production',
      'name': 'Getafric Production',
      'location': 'Lyon, France',
      'address': 'Lyon Center, 69002 Lyon, France',
      'lat': 45.7570,
      'lng': 4.8320,
      'rating': '4.9 (140 reviews)',
      'badge': 'VIP',
      'category': 'Services',
      'registration': 'SIREN: 890 123 456',
      'phone': 'tel:+33600000000',
      'email': 'getafric@eurohabesha.eu',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/33600000000',
      'openingHours': 'Mon - Sat: 09:00 - 19:00',
      'description': 'High-end photography and cinematography for Habesha weddings, community festivals and corporate events.',
      'icon': Icons.camera_alt,
      'gallery': [
        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=800&q=80',
      ],
      'reviews': []
    },
    {
      'id': 'place_konjo',
      'title': 'Unisex Hair Salon & Cosmetics',
      'name': 'Konjo Beauty Salon',
      'location': 'Paris, France',
      'address': '45 Boulevard de Sébastopol, 75001 Paris, France',
      'lat': 48.8610,
      'lng': 2.3500,
      'rating': '4.7 (150 reviews)',
      'badge': 'Premium',
      'category': 'Hair & Beauty',
      'registration': 'SIREN: 987 654 321',
      'phone': 'tel:+33122334455',
      'email': 'booking@konjosalon.fr',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/33122334455',
      'openingHours': 'Mon - Sat: 09:30 - 19:30',
      'description': 'Professional hair styling, braiding, coloring, and cosmetics store tailored for Habesha men and women.',
      'icon': Icons.spa,
      'gallery': [
        'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=800&q=80',
      ],
      'reviews': []
    },
    {
      'id': 'place_dr_selam',
      'title': 'General Practitioner & Pediatrician',
      'name': 'Dr. Selamawit T.',
      'location': 'Paris, France',
      'address': '18 Rue de Châteaudun, 75009 Paris, France',
      'lat': 48.8760,
      'lng': 2.3380,
      'rating': '5.0 (210 reviews)',
      'badge': 'VIP',
      'category': 'Services',
      'registration': 'RPPS: 10003456789',
      'phone': 'tel:+33100000000',
      'email': 'dr.selam@eurohabesha.eu',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/33100000000',
      'openingHours': 'Mon - Fri: 09:00 - 18:00',
      'description': 'Certified Medical Doctor specializing in general practice and pediatrics.',
      'icon': Icons.medical_services,
      'gallery': [],
      'reviews': []
    },
    {
      'id': 'place_dawit_law',
      'title': 'Immigration & Corporate Lawyer',
      'name': 'Dawit Legesse Legal Services',
      'location': 'Geneva, Switzerland',
      'address': 'Rue du Rhône 42, 1204 Genève, Switzerland',
      'lat': 46.2040,
      'lng': 6.1480,
      'rating': '4.9 (134 reviews)',
      'badge': 'Silver',
      'category': 'Services',
      'registration': 'CH-660.1.234.567-8',
      'phone': 'tel:+41221122334',
      'email': 'dawit.law@eurohabesha.eu',
      'website': 'https://www.eurohabesha.eu',
      'whatsapp': 'https://wa.me/41221122334',
      'openingHours': 'Mon - Fri: 08:30 - 17:30',
      'description': 'Licensed attorney helping the Habesha diaspora with residency permits, corporate law and asylum support.',
      'icon': Icons.gavel,
      'gallery': [],
      'reviews': []
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedCityOption = _popularCities.first;
    _initUserLocation();
  }

  Future<void> _initUserLocation() async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocating = false;
          _locationName = 'Location disabled (using Lyon default)';
          _currentPosition = Position(
            latitude: 45.7640,
            longitude: 4.8357,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        setState(() {
          _isLocating = false;
          _locationName = 'GPS not granted (using Lyon default)';
          _currentPosition = Position(
            latitude: 45.7640,
            longitude: 4.8357,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      setState(() {
        _isLocating = false;
        _currentPosition = pos;
        _locationName = 'GPS: ${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)}';
      });
    } catch (_) {
      setState(() {
        _isLocating = false;
        _locationName = 'Lyon, France (Default)';
        _currentPosition = Position(
          latitude: 45.7640,
          longitude: 4.8357,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      });
    }
  }

  double _getCenterLat() {
    if (_selectedCityOption == 'Use My GPS Location' && _currentPosition != null) {
      return _currentPosition!.latitude;
    }
    return _cityCoordinates[_selectedCityOption]?.lat ?? 45.7640;
  }

  double _getCenterLng() {
    if (_selectedCityOption == 'Use My GPS Location' && _currentPosition != null) {
      return _currentPosition!.longitude;
    }
    return _cityCoordinates[_selectedCityOption]?.lng ?? 4.8357;
  }

  List<Map<String, dynamic>> _computeNearby() {
    final centerLat = _getCenterLat();
    final centerLng = _getCenterLng();

    final List<Map<String, dynamic>> result = [];
    for (final item in _allNearbyPlaces) {
      final double lat = (item['lat'] as num?)?.toDouble() ?? 45.7640;
      final double lng = (item['lng'] as num?)?.toDouble() ?? 4.8357;

      final distanceMeters = Geolocator.distanceBetween(centerLat, centerLng, lat, lng);
      final distanceKm = distanceMeters / 1000.0;

      if (distanceKm <= _selectedRadiusKm) {
        final copy = Map<String, dynamic>.from(item);
        copy['distanceKm'] = distanceKm;
        result.add(copy);
      }
    }

    result.sort((a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final nearbyList = _computeNearby();

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('Nearby / À proximité', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: Column(
        children: [
          // ── Location Selector & Distance Range ──
          Container(
            padding: const EdgeInsets.all(16),
            color: cardGreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Picker
                Row(
                  children: [
                    const Icon(Icons.my_location, color: Color(0xFFFFD700), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCityOption,
                          isExpanded: true,
                          dropdownColor: cardGreen,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          items: _popularCities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCityOption = val);
                              if (val == 'Use My GPS Location') {
                                _initUserLocation();
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Radius Range Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Distance Range:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('${_selectedRadiusKm.toInt()} km', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _radiusOptions.map((r) {
                    final isSel = _selectedRadiusKm == r;
                    return ChoiceChip(
                      label: Text('${r.toInt()} km'),
                      selected: isSel,
                      selectedColor: primaryGold,
                      backgroundColor: primaryDarkGreen,
                      labelStyle: TextStyle(
                        color: isSel ? primaryDarkGreen : Colors.white70,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedRadiusKm = r);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Map View Card ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryGold.withOpacity(0.3)),
              ),
              child: Stack(
                children: [
                  // Simulated stylish dark map background with radar rings
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.9,
                            colors: [
                              primaryGold.withOpacity(0.15),
                              primaryDarkGreen,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(Icons.radar, color: primaryGold.withOpacity(0.2), size: 120),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 14,
                    child: Row(
                      children: [
                        const Icon(Icons.map_outlined, color: Color(0xFFFFD700), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Radar Map View • ${nearbyList.length} Places Found',
                          style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  // Render radar pins
                  Center(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: nearbyList.take(4).map((place) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryGold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFF061E12), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${place['name'].toString().split(' ').first} (${(place['distanceKm'] as double).toStringAsFixed(1)}km)',
                                style: const TextStyle(color: Color(0xFF061E12), fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Nearby Places List (Large, Clear, Tap-Friendly Cards) ──
          Expanded(
            child: nearbyList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_off, color: primaryGold.withOpacity(0.5), size: 50),
                          const SizedBox(height: 12),
                          const Text(
                            'No businesses found within this distance.',
                            style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text('Try increasing the radius to 25 km or 50 km.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: nearbyList.length,
                    itemBuilder: (context, index) {
                      final item = nearbyList[index];
                      final dist = (item['distanceKm'] as double).toStringAsFixed(1);
                      final List gallery = item['gallery'] is List ? item['gallery'] : [];
                      final String? firstPhoto = gallery.isNotEmpty ? gallery.first.toString() : null;

                      return Card(
                        color: cardGreen,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: primaryGold.withOpacity(0.3), width: 1.2),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BusinessDetailScreen(businessData: item),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Large 70x70 Photo or Icon
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        color: primaryGold.withOpacity(0.18),
                                        child: firstPhoto != null
                                            ? Image.network(
                                                firstPhoto,
                                                fit: BoxFit.cover,
                                                errorBuilder: (ctx, err, stack) => Icon(item['icon'] as IconData? ?? Icons.storefront, color: primaryGold, size: 36),
                                              )
                                            : Icon(item['icon'] as IconData? ?? Icons.storefront, color: primaryGold, size: 36),
                                      ),
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
                                                  item['name'] ?? '',
                                                  style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 17),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.greenAccent.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                                                ),
                                                child: Text(
                                                  '$dist km',
                                                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item['title'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                item['rating']?.toString() ?? '5.0',
                                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                              ),
                                              const SizedBox(width: 10),
                                              StatusBadgeWidget(
                                                isVerified: item['isVerified'] == true || item['badge'] == 'Verified' || item['badge'] == 'Premium',
                                                subscriptionTier: item['subscriptionTier']?.toString() ?? (item['badge'] == 'VIP' ? 'vip' : item['badge'] == 'Premium' ? 'pro' : null),
                                                compact: true,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Divider(color: Colors.white12, height: 1),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, color: Colors.white54, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item['address']?.toString() ?? item['location']?.toString() ?? '',
                                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Text('View Profile →', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
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

class _CityCoord {
  final double lat;
  final double lng;
  const _CityCoord(this.lat, this.lng);
}
