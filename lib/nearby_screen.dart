import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'business_screen.dart';
import 'community_screen.dart';
import 'events_screen.dart';
import 'jobs_screen.dart';
import 'marketplace_screen.dart';
import 'professionals_screen.dart';
import 'status_badge_widget.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final List<double> _radiusOptions = [5, 10, 15, 25, 50];

  final List<String> _categories = const [
    'Tous',
    'Événements',
    'Emplois',
    'Marché',
    'Pros',
    'Commerces',
    'Connect',
  ];

  final List<String> _sortOptions = const [
    'Proximité',
    'Récent',
    'Populaire',
  ];

  final Map<String, _CityCoord> _cityCoordinates = const {
    'Lyon, France': _CityCoord(45.7640, 4.8357),
    'Paris, France': _CityCoord(48.8566, 2.3522),
    'Marseille, France': _CityCoord(43.2965, 5.3698),
    'Geneva, Switzerland': _CityCoord(46.2044, 6.1432),
    'Frankfurt, Germany': _CityCoord(50.1109, 8.6821),
    'Berlin, Germany': _CityCoord(52.5200, 13.4050),
    'Rome, Italy': _CityCoord(41.9028, 12.4964),
    'Brussels, Belgium': _CityCoord(50.8503, 4.3517),
    'Amsterdam, Netherlands': _CityCoord(52.3676, 4.9041),
    'Stockholm, Sweden': _CityCoord(59.3293, 18.0686),
    'London, UK': _CityCoord(51.5074, -0.1278),
  };

  double _selectedRadiusKm = 25;
  String _selectedCategory = 'Tous';
  String _selectedSort = 'Proximité';
  String _selectedLocation = 'GPS';

  Position? _currentPosition;
  bool _isLocating = false;
  String _locationMessage = 'Recherche de votre position...';

  @override
  void initState() {
    super.initState();
    _initUserLocation();
  }

  Future<void> _initUserLocation() async {
    if (_isLocating) return;

    setState(() {
      _isLocating = true;
      _locationMessage = 'Recherche de votre position...';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _isLocating = false;
          _currentPosition = null;
          _locationMessage = 'GPS désactivé — choisissez une ville';
        });

        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _isLocating = false;
          _currentPosition = null;
          _locationMessage = 'GPS non autorisé — choisissez une ville';
        });

        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _selectedLocation = 'GPS';
        _isLocating = false;
        _locationMessage = 'Position GPS active';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLocating = false;
        _currentPosition = null;
        _locationMessage = 'Position indisponible — choisissez une ville';
      });
    }
  }

  _CityCoord? get _center {
    if (_selectedLocation == 'GPS') {
      final position = _currentPosition;

      if (position == null) return null;

      return _CityCoord(
        position.latitude,
        position.longitude,
      );
    }

    return _cityCoordinates[_selectedLocation];
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(
        value.trim().replaceAll(',', '.'),
      );
    }

    return null;
  }

  Map<String, dynamic> _fields(
    Map<String, dynamic> data,
  ) {
    final raw = data['fields'];

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return <String, dynamic>{};
  }

  _CityCoord? _coordinates(
    Map<String, dynamic> data,
  ) {
    final fields = _fields(data);

    final geo = data['geoPoint'] ?? fields['geoPoint'];

    if (geo is GeoPoint) {
      return _CityCoord(
        geo.latitude,
        geo.longitude,
      );
    }

    final latitude = _toDouble(
      data['latitude'] ?? fields['latitude'] ?? data['lat'] ?? fields['lat'],
    );

    final longitude = _toDouble(
      data['longitude'] ?? fields['longitude'] ?? data['lng'] ?? fields['lng'],
    );

    if (latitude == null || longitude == null) {
      return null;
    }

    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    return _CityCoord(latitude, longitude);
  }

  String _categoryFor(
    Map<String, dynamic> data,
  ) {
    final raw = [
      data['category'],
      data['type'],
      data['sourceCollection'],
    ].whereType<Object>().join(' ').toLowerCase();

    if (raw.contains('event')) {
      return 'Événements';
    }

    if (raw.contains('job') ||
        raw.contains('employer') ||
        raw.contains('service')) {
      return 'Emplois';
    }

    if (raw.contains('marketplace') || raw.contains('market')) {
      return 'Marché';
    }

    if (raw.contains('professional') || raw.contains('professionnel')) {
      return 'Pros';
    }

    if (raw.contains('habesha') ||
        raw.contains('community') ||
        raw.contains('connect')) {
      return 'Connect';
    }

    if (raw.contains('business') ||
        raw.contains('restaurant') ||
        raw.contains('commerce')) {
      return 'Commerces';
    }

    return 'Commerces';
  }

  String _titleFor(
    Map<String, dynamic> data,
  ) {
    final fields = _fields(data);

    final candidates = [
      data['name'],
      data['title'],
      data['businessName'],
      data['eventName'],
      fields['businessName'],
      fields['eventName'],
      fields['title'],
      fields['name'],
      fields['professionalName'],
      fields['jobTitle'],
      fields['productName'],
    ];

    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty) return text;
    }

    return 'Euro Habesha';
  }

  String _descriptionFor(
    Map<String, dynamic> data,
  ) {
    final fields = _fields(data);

    final candidates = [
      data['description'],
      data['subtitle'],
      fields['description'],
      fields['shortDescription'],
      fields['jobDescription'],
    ];

    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty) return text;
    }

    return _categoryFor(data);
  }

  String _locationFor(
    Map<String, dynamic> data,
  ) {
    final fields = _fields(data);

    final exactAddressVisible =
        fields['showExactAddress'] == true || data['showExactAddress'] == true;

    if (exactAddressVisible) {
      final exact = [
        fields['address'],
        data['address'],
      ];

      for (final value in exact) {
        final text = value?.toString().trim() ?? '';

        if (text.isNotEmpty) return text;
      }
    }

    final candidates = [
      fields['cityAddress'],
      data['cityAddress'],
      data['location'],
      fields['city'],
      data['city'],
      fields['country'],
      data['country'],
    ];

    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty) return text;
    }

    return 'Localisation disponible';
  }

  String? _imageFor(
    Map<String, dynamic> data,
  ) {
    final fields = _fields(data);

    final direct = [
      data['imageUrl'],
      data['image'],
      data['photoUrl'],
      data['coverImage'],
      fields['imageUrl'],
      fields['photoUrl'],
    ];

    for (final value in direct) {
      final url = value?.toString().trim() ?? '';

      if (url.startsWith('http')) return url;
    }

    final media = data['media'];

    if (media is Map) {
      final photos = media['photoUrls'];

      if (photos is List && photos.isNotEmpty) {
        final url = photos.first.toString();

        if (url.startsWith('http')) return url;
      }
    }

    return null;
  }

  double _ratingFor(
    Map<String, dynamic> data,
  ) {
    final fields = _fields(data);

    final value = data['rating'] ?? fields['rating'];

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final match = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(value);

      if (match != null) {
        return double.tryParse(
              match.group(0)!.replaceAll(',', '.'),
            ) ??
            0;
      }
    }

    return 0;
  }

  int _reviewCountFor(
    Map<String, dynamic> data,
  ) {
    final fields = _fields(data);

    final value = data['reviewCount'] ?? fields['reviewCount'];

    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _isVerified(
    Map<String, dynamic> data,
  ) {
    final fields = _fields(data);

    return data['isVerified'] == true || fields['isVerified'] == true;
  }

  String? _subscriptionTier(
    Map<String, dynamic> data,
  ) {
    final fields = _fields(data);

    final value =
        data['subscriptionTier'] ?? fields['subscriptionTier'] ?? data['tier'];

    final tier = value?.toString().trim().toLowerCase();

    if (tier == null || tier.isEmpty) return null;

    return tier;
  }

  int _priorityScore(
    Map<String, dynamic> data,
  ) {
    var score = 0;

    final tier = _subscriptionTier(data);

    if (tier == 'vip') {
      score += 300;
    } else if (tier == 'pro' || tier == 'premium') {
      score += 200;
    } else if (tier == 'silver') {
      score += 100;
    }

    if (_isVerified(data)) {
      score += 80;
    }

    score += (_ratingFor(data) * 10).round();
    score += _reviewCountFor(data).clamp(0, 100);

    return score;
  }

  DateTime _dateFor(
    Map<String, dynamic> data,
  ) {
    final value = data['publishedAt'] ?? data['updatedAt'] ?? data['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<Map<String, dynamic>> _prepareItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final center = _center;

    if (center == null) {
      return [];
    }

    final items = <Map<String, dynamic>>[];

    for (final doc in docs) {
      final original = doc.data();

      final status = original['status']?.toString().toLowerCase();

      if (status != null &&
          status.isNotEmpty &&
          status != 'published' &&
          status != 'approved') {
        continue;
      }

      final coordinates = _coordinates(original);

      // Aucun faux emplacement :
      // un contenu sans coordonnées n'est pas classé "à proximité".
      if (coordinates == null) continue;

      final distanceMeters = Geolocator.distanceBetween(
        center.lat,
        center.lng,
        coordinates.lat,
        coordinates.lng,
      );

      final distanceKm = distanceMeters / 1000;

      if (distanceKm > _selectedRadiusKm) {
        continue;
      }

      final item = <String, dynamic>{
        ...original,
        '_publicFeedId': doc.id,
        '_category': _categoryFor(original),
        '_distanceKm': distanceKm,
        '_priorityScore': _priorityScore(original),
      };

      if (_selectedCategory != 'Tous' &&
          item['_category'] != _selectedCategory) {
        continue;
      }

      items.add(item);
    }

    if (_selectedSort == 'Récent') {
      items.sort(
        (a, b) => _dateFor(b).compareTo(_dateFor(a)),
      );
    } else if (_selectedSort == 'Populaire') {
      items.sort((a, b) {
        final scoreCompare = (b['_priorityScore'] as int).compareTo(
          a['_priorityScore'] as int,
        );

        if (scoreCompare != 0) return scoreCompare;

        return (a['_distanceKm'] as double).compareTo(
          b['_distanceKm'] as double,
        );
      });
    } else {
      items.sort((a, b) {
        final distanceCompare = (a['_distanceKm'] as double).compareTo(
          b['_distanceKm'] as double,
        );

        if (distanceCompare.abs() > 2) {
          return distanceCompare;
        }

        final priorityCompare = (b['_priorityScore'] as int).compareTo(
          a['_priorityScore'] as int,
        );

        if (priorityCompare != 0) {
          return priorityCompare;
        }

        return distanceCompare;
      });
    }

    return items;
  }

  Future<Map<String, dynamic>?> _loadSource(
    Map<String, dynamic> item,
  ) async {
    final sourceCollection = item['sourceCollection']?.toString().trim();

    final sourceId = item['sourceId']?.toString().trim();

    if (sourceCollection == null ||
        sourceCollection.isEmpty ||
        sourceId == null ||
        sourceId.isEmpty) {
      return null;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(sourceCollection)
          .doc(sourceId)
          .get();

      if (!snapshot.exists) return null;

      return {
        ...?snapshot.data(),
        'id': snapshot.id,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> _openItem(
    Map<String, dynamic> item,
  ) async {
    final category = item['_category']?.toString() ?? _categoryFor(item);

    final sourceData = await _loadSource(item) ?? item;

    if (!mounted) return;

    Widget screen;

    switch (category) {
      case 'Événements':
        screen = EventDetailScreen(
          eventData: sourceData,
        );
        break;

      case 'Emplois':
        screen = JobDetailScreen(
          jobData: sourceData,
        );
        break;

      case 'Marché':
        screen = ProductDetailScreen(
          product: sourceData,
        );
        break;

      case 'Pros':
        screen = ProDetailScreen(
          proData: sourceData,
        );
        break;

      case 'Connect':
        screen = CommunityDetailScreen(
          community: sourceData,
        );
        break;

      case 'Commerces':
      default:
        screen = BusinessDetailScreen(
          businessData: sourceData,
        );
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Événements':
        return Icons.event;
      case 'Emplois':
        return Icons.work_outline;
      case 'Marché':
        return Icons.shopping_bag_outlined;
      case 'Pros':
        return Icons.badge_outlined;
      case 'Connect':
        return Icons.groups_outlined;
      case 'Commerces':
        return Icons.storefront;
      default:
        return Icons.explore_outlined;
    }
  }

  Widget _locationSelector() {
    final options = <String>[
      'GPS',
      ..._cityCoordinates.keys,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      color: cardGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.my_location,
                color: primaryGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLocation,
                    isExpanded: true,
                    dropdownColor: cardGreen,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    items: options.map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(
                          value == 'GPS' ? 'Utiliser ma position GPS' : value,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedLocation = value;
                      });

                      if (value == 'GPS') {
                        _initUserLocation();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _selectedLocation == 'GPS'
                ? _locationMessage
                : 'Recherche autour de $_selectedLocation',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Rayon',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedRadiusKm.toInt()} km',
                style: const TextStyle(
                  color: primaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _radiusOptions.map((radius) {
                final selected = radius == _selectedRadiusKm;

                return Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text('${radius.toInt()} km'),
                    selected: selected,
                    selectedColor: primaryGold,
                    backgroundColor: primaryDarkGreen,
                    labelStyle: TextStyle(
                      color: selected ? primaryDarkGreen : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedRadiusKm = radius;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Column(
      children: [
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final selected = category == _selectedCategory;

              return ChoiceChip(
                avatar: Icon(
                  _categoryIcon(category),
                  size: 17,
                  color: selected ? primaryDarkGreen : primaryGold,
                ),
                label: Text(category),
                selected: selected,
                selectedColor: primaryGold,
                backgroundColor: cardGreen,
                labelStyle: TextStyle(
                  color: selected ? primaryDarkGreen : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            itemCount: _sortOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final option = _sortOptions[index];
              final selected = option == _selectedSort;

              return ChoiceChip(
                label: Text(option),
                selected: selected,
                selectedColor: primaryGold.withValues(alpha: 0.9),
                backgroundColor: primaryDarkGreen,
                side: BorderSide(
                  color: selected ? primaryGold : Colors.white24,
                ),
                labelStyle: TextStyle(
                  color: selected ? primaryDarkGreen : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedSort = option;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _radarCard(
    List<Map<String, dynamic>> items,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      height: 105,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryGold.withValues(alpha: 0.35),
        ),
        gradient: RadialGradient(
          colors: [
            primaryGold.withValues(alpha: 0.15),
            cardGreen,
            primaryDarkGreen,
          ],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.radar,
              size: 90,
              color: primaryGold.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            left: 14,
            top: 13,
            child: Row(
              children: [
                const Icon(
                  Icons.explore,
                  color: primaryGold,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Text(
                  '${items.length} résultat${items.length > 1 ? 's' : ''} '
                  'dans ${_selectedRadiusKm.toInt()} km',
                  style: const TextStyle(
                    color: primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            bottom: 13,
            child: Text(
              _selectedLocation == 'GPS'
                  ? 'Autour de votre position'
                  : 'Autour de $_selectedLocation',
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

  Widget _resultCard(
    Map<String, dynamic> item,
  ) {
    final title = _titleFor(item);
    final description = _descriptionFor(item);
    final location = _locationFor(item);
    final imageUrl = _imageFor(item);
    final category = item['_category'].toString();
    final distance = (item['_distanceKm'] as double).toStringAsFixed(1);
    final rating = _ratingFor(item);
    final tier = _subscriptionTier(item);

    return Card(
      color: cardGreen,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: primaryGold.withValues(alpha: 0.25),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openItem(item),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 76,
                  height: 76,
                  color: primaryGold.withValues(alpha: 0.12),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            _categoryIcon(category),
                            color: primaryGold,
                            size: 34,
                          ),
                        )
                      : Icon(
                          _categoryIcon(category),
                          color: primaryGold,
                          size: 34,
                        ),
                ),
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
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: primaryGold,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryDarkGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$distance km',
                            style: const TextStyle(
                              color: primaryGold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (rating > 0) ...[
                          const Icon(
                            Icons.star,
                            color: primaryGold,
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        StatusBadgeWidget(
                          isVerified: _isVerified(item),
                          subscriptionTier: tier,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: primaryGold,
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: primaryGold),
        title: const Text(
          'À proximité',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser ma position',
            onPressed: _initUserLocation,
            icon: const Icon(
              Icons.gps_fixed,
              color: primaryGold,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _locationSelector(),
          _filters(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('publicFeed')
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Impossible de charger les contenus à proximité.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: primaryGold,
                    ),
                  );
                }

                if (_center == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_searching,
                            color: primaryGold,
                            size: 48,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _isLocating
                                ? 'Recherche de votre position...'
                                : 'Choisissez une ville ci-dessus ou activez votre GPS.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final items = _prepareItems(snapshot.data!.docs);

                return Column(
                  children: [
                    _radarCard(items),
                    Expanded(
                      child: items.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Aucun contenu avec une localisation vérifiée dans cette zone.\n\n'
                                  'Essayez un rayon plus grand ou une autre ville.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                6,
                                14,
                                28,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                return _resultCard(
                                  items[index],
                                );
                              },
                            ),
                    ),
                  ],
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

  const _CityCoord(
    this.lat,
    this.lng,
  );
}
