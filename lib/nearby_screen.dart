import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'business_screen.dart';
import 'habesha_connect_feed_screen.dart';
import 'events_screen.dart';
import 'jobs_screen.dart';
import 'marketplace_screen.dart';
import 'professionals_screen.dart';
import 'status_badge_widget.dart';
class NearbyScreen extends StatefulWidget {
  final String initialCategory;
  final bool useSavedCampaignCity;
  const NearbyScreen({super.key, this.initialCategory = 'Tous',
    this.useSavedCampaignCity = false});
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
    'Restaurants',
    'Connect',
  ];
  final List<String> _sortOptions = const [
    'Proximité',
    'Récent',
    'Populaire',
  ];
  final Map<String, _CityCoord> _cityCoordinates = const {
    'Lyon, France': _CityCoord(45.7640, 4.8357),
    'Vaulx-en-Velin, France': _CityCoord(45.7769, 4.9186),
    'Villeurbanne, France': _CityCoord(45.7719, 4.8902),
    'Bron, France': _CityCoord(45.7384, 4.9135),
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
    'New York, USA': _CityCoord(40.7128, -74.0060),
    'Washington, USA': _CityCoord(38.9072, -77.0369),
    'Los Angeles, USA': _CityCoord(34.0522, -118.2437),
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
    if (_categories.contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory;
    }
    if (widget.useSavedCampaignCity) {
      _restoreCampaignCity();
    } else {
      _initUserLocation();
    }
  }
  Future<void> _restoreCampaignCity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        final snapshot = await FirebaseFirestore.instance
            .collection('localCampaignSubscriptions').doc(user.uid).get();
        if (!mounted) return;
        final city = snapshot.data()?['city'];
        if (city is String && _cityCoordinates.containsKey(city)) {
          setState(() {
            _selectedLocation = city;
            _locationMessage = 'Ville choisie pour les suggestions';
          });
          return;
        }
      }
    } catch (_) {
      // GPS or manual city selection remains available.
    }
    if (mounted) await _initUserLocation();
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

  // Emplacement approximatif uniquement si la ville est connue.
  // Ne jamais inventer des coordonnées GPS exactes pour une entreprise.
  _CityCoord? _cityFallback(Map<String, dynamic> data) {
    final fields = _fields(data);
    final locationText = [
      data['city'], fields['city'], data['cityAddress'],
      fields['cityAddress'], data['location'], fields['location'],
      data['address'], fields['address'], data['venue'], fields['venue'],
    ].where((value) => value != null)
     .map((value) => value.toString().toLowerCase())
     .join(' ');
    if (locationText.isEmpty) return null;
    for (final entry in _cityCoordinates.entries) {
      final city = entry.key.split(',').first.toLowerCase();
      if (locationText.split(RegExp(r'[^a-zà-ÿ-]+')).contains(city)) {
        return entry.value;
      }
    }
    return null;
  }
  String _categoryFor(Map<String, dynamic> data) {
    // La collection d'origine prime sur les mots de la description.
    final source = (data['sourceCollection'] ?? '').toString().trim().toLowerCase();
    const byCollection = <String, String>{
      'events': 'Événements', 'eventsubmissions': 'Événements',
      'jobs': 'Emplois', 'jobsubmissions': 'Emplois',
      'marketplace': 'Marché', 'marketplacesubmissions': 'Marché', 'products': 'Marché',
      'professionals': 'Pros', 'professionalprofiles': 'Pros',
      'businesses': 'Commerces', 'businesssubmissions': 'Commerces',
      'posts': 'Connect', 'habeshaconnectrequests': 'Connect',
    };
    if (source == 'jobsubmissions') {
      final submissionType = (data['type'] ?? '').toString().toLowerCase();
      if (submissionType == 'professional') return 'Pros';
      return 'Emplois';
    }
    if (byCollection.containsKey(source)) return byCollection[source]!;
    final fields = _fields(data);
    final raw = [data['category'], fields['category'], data['type'],
      fields['type'], data['businessCategory'], fields['businessCategory']]
        .where((value) => value != null).join(' ').toLowerCase();
    if (raw.contains('event') || raw.contains('concert')) return 'Événements';
    if (raw.contains('job') || raw.contains('emploi') || raw.contains('recrut')) return 'Emplois';
    if (raw.contains('market') || raw.contains('product') || raw.contains('produit')) return 'Marché';
    if (raw.contains('community') || raw.contains('connect')) return 'Connect';
    if (raw.contains('professional') || raw.contains('professionnel') ||
        raw.contains('photograph') || raw.contains('videograph')) {
      return 'Pros';
    }
    return 'Commerces';
  }
  String _titleFor(
    Map<String, dynamic> data,
  ) {
    final fields = _fields(data);
    final candidates = [
      data['name'],
      _fields(data)['title'],
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
      data['logoUrl'],
      data['coverUrl'],
      data['image'],
      data['photoUrl'],
      data['coverImage'],
      fields['imageUrl'],
      fields['logoUrl'],
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
    List<Map<String, dynamic>> documents,
  ) {
    final center = _center;
    if (center == null) {
      return [];
    }
    final items = <Map<String, dynamic>>[];
    for (final original in documents) {
      final status = original['status']?.toString().toLowerCase();
      if (status != null &&
          status.isNotEmpty &&
          status != 'published' &&
          status != 'approved') {
        continue;
      }
      final exactCoordinates = _coordinates(original);
      final coordinates = exactCoordinates ?? _cityFallback(original);
      // Les fiches sans GPS et sans ville reconnue restent exclues.
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
        '_publicFeedId': original['_sourceId'] ?? '',
        '_category': _categoryFor(original),
        '_distanceKm': distanceKm,
        '_approximateDistance': exactCoordinates == null,
        '_priorityScore': _priorityScore(original),
      };
      if (_selectedCategory == 'Restaurants') {
        final fields = _fields(original);
        final category = _categoryFor(original);
        final kinds = [original['businessCategory'], fields['businessCategory'],
          original['jobCategory'], fields['jobCategory'],
          original['professionalCategory'], fields['professionalCategory'],
          original['category'], fields['category']]
            .whereType<String>().join(' ').toLowerCase();
        if (!['Commerces', 'Pros'].contains(category) ||
            !['restaurant', 'café', 'cafe', 'coffee', 'brasserie']
                .any(kinds.contains)) {
          continue;
        }
      } else if (_selectedCategory != 'Tous' &&
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
  // Adapte un événement Firestore au format attendu par EventDetailScreen.
  Map<String, dynamic> _eventDetailData(Map<String, dynamic> data) {
    final fields = _fields(data);
    String pick(List<dynamic> values, String fallback) {
      for (final value in values) {
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
      return fallback;
    }
    final eventMedia = data['eventMedia'];
    final media = data['media'];
    String image = pick([
      data['image'], data['imageUrl'], data['coverUrl'],
      if (eventMedia is Map) eventMedia['coverUrl'],
      if (eventMedia is Map && eventMedia['photoUrls'] is List &&
          (eventMedia['photoUrls'] as List).isNotEmpty)
        (eventMedia['photoUrls'] as List).first,
      if (media is Map && media['photoUrls'] is List &&
          (media['photoUrls'] as List).isNotEmpty)
        (media['photoUrls'] as List).first,
    ], '');
    final performer = pick([fields['performer'], data['performerDj']], 'Live Show');
    final rawPrice = pick([fields['ticketPrice'], data['price']], '');
    return {
      ...data,
      'id': pick([data['id'], data['sourceId']], ''),
      'title': pick([fields['title'], data['title'], data['eventName']], 'Event'),
      'type': pick([fields['eventType'], data['type']], 'Concert & Party'),
      'audience': pick([fields['audience'], data['audience']], 'General'),
      'date': pick([fields['eventDate'], data['date']], 'Upcoming'),
      'time': pick([fields['eventTime'], data['time']], ''),
      'endTime': pick([fields['endTime'], data['endTime']], ''),
      'location': pick([fields['cityAddress'], data['location'], data['city']], 'Europe'),
      'price': rawPrice,
      'description': pick([fields['description'], data['description']], ''),
      'performerDj': performer,
      'artists': data['artists'] is List ? data['artists'] : [performer],
      'image': image,
      'nonRefundable': data['nonRefundable'] == true ||
          (data['eventDetails'] is Map && data['eventDetails']['nonRefundable'] == true),
      'nonTransferable': data['nonTransferable'] == true ||
          (data['eventDetails'] is Map && data['eventDetails']['nonTransferable'] == true),
    };
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
          eventData: _eventDetailData(sourceData),
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
        final collection = (item['sourceCollection'] ?? '').toString();
        final postId = (item['sourceId'] ?? sourceData['id'] ?? '').toString();
        screen = HabeshaConnectFeedScreen(
          initialPostId: collection == 'posts' && postId.isNotEmpty
              ? postId
              : null,
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
      case 'Restaurants':
        return Icons.restaurant_outlined;
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
    final approximate = item['_approximateDistance'] == true;
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
                            approximate ? '≈ $distance km (ville)' : '$distance km',
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
               stream: FirebaseFirestore.instance.collection('professionals').limit(500).snapshots(),
               builder: (context, proSnapshot) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
               stream: FirebaseFirestore.instance.collection('professionalProfiles').limit(500).snapshots(),
               builder: (context, proProfileSnapshot) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
               stream: FirebaseFirestore.instance.collection('marketplaceSubmissions').limit(500).snapshots(),
               builder: (context, marketSubSnapshot) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
               stream: FirebaseFirestore.instance.collection('communitySubmissions').limit(500).snapshots(),
               builder: (context, communitySubSnapshot) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
               stream: FirebaseFirestore.instance.collection('communityPosts').limit(500).snapshots(),
               builder: (context, communityPostSnapshot) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('publicFeed').limit(500).snapshots(),
              builder: (context, feedSnapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('businesses').limit(500).snapshots(),
                  builder: (context, businessSnapshot) {
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('businessSubmissions').limit(500).snapshots(),
                      builder: (context, businessSubSnapshot) {
                        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance.collection('jobSubmissions').limit(500).snapshots(),
                          builder: (context, jobSnapshot) {
                            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance.collection('events').limit(500).snapshots(),
                              builder: (context, eventSnapshot) {
                                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                  stream: FirebaseFirestore.instance.collection('eventSubmissions').limit(500).snapshots(),
                                  builder: (context, eventSubSnapshot) {
                                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                      stream: FirebaseFirestore.instance.collection('jobs').limit(500).snapshots(),
                                      builder: (context, jobsSnapshot) {
                                        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                          stream: FirebaseFirestore.instance.collection('marketplace').limit(500).snapshots(),
                                          builder: (context, marketSnapshot) {
                                            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                              stream: FirebaseFirestore.instance.collection('posts').limit(500).snapshots(),
                                              builder: (context, communitySnapshot) {
                                                final sources = <String, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>>{
                                                  'professionals': proSnapshot,
                                                   'professionalProfiles': proProfileSnapshot,
                                                   'marketplaceSubmissions': marketSubSnapshot,
                                                   // Anciennes demandes communautaires exclues de À proximité.
                                                   // Anciennes publications communautaires exclues de À proximité.
                                                   'publicFeed': feedSnapshot,
                                                  'businesses': businessSnapshot,
                                                  'businessSubmissions': businessSubSnapshot,
                                                  'jobSubmissions': jobSnapshot,
                                                  'events': eventSnapshot,
                                                  'eventSubmissions': eventSubSnapshot,
                                                  'jobs': jobsSnapshot,
                                                  'marketplace': marketSnapshot,
                                                  'posts': communitySnapshot,
                                                };
                                                if (sources.values.every((s) => !s.hasData && !s.hasError)) {
                                                  return const Center(child: CircularProgressIndicator(color: primaryGold));
                                                }
                                                final documents = <Map<String, dynamic>>[];
                                                final seen = <String>{};
                                                // Priorité aux fiches publiques, puis aux sources approuvées.
                                                for (final entry in sources.entries) {
                                                  final collection = entry.key;
                                                  final snapshot = entry.value.data;
                                                  if (snapshot == null) continue;
                                                  for (final doc in snapshot.docs) {
                                                    final data = doc.data();
                                                    final status = (data['status'] ?? '').toString().trim().toLowerCase();
                                                    if (status != 'approved' && status != 'published') continue;
                                                    if (data['isActive'] == false || data['isArchived'] == true ||
                                                        data['isDeleted'] == true || data['deleted'] == true) {
                                                      continue;
                                                    }
                                                    final source = collection == 'publicFeed'
                                                        ? (data['sourceCollection'] ?? 'publicFeed').toString()
                                                        : collection;
                                                    final sourceId = collection == 'publicFeed'
                                                        ? (data['sourceId'] ?? doc.id).toString()
                                                        : doc.id;
                                                    if (!seen.add('$source/$sourceId')) continue;
                                                    documents.add({
                                                      ...data,
                                                      'sourceCollection': source,
                                                      'sourceId': sourceId,
                                                      '_sourceId': doc.id,
                                                    });
                                                  }
                                                }
                                                final errors = sources.entries
                                                    .where((entry) => entry.value.hasError)
                                                    .map((entry) => entry.key).toList();
                                                if (_center == null) {
                                                  return const Center(child: Padding(
                                                    padding: EdgeInsets.all(24),
                                                    child: Text('Choisissez une ville ci-dessus ou activez votre GPS.',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(color: Colors.white70)),
                                                  ));
                                                }
                                                final items = _prepareItems(documents);
                                                 // Diagnostic : différencier données chargées et fiches localisables.
                                                 final approvedCount = documents.length;
                                                 final geolocatedCount = documents.where((d) =>
                                                   _coordinates(d) != null || _cityFallback(d) != null).length;
                                                return Column(
                                                  children: [
                                                    _radarCard(items),
                                                     if (items.isEmpty && approvedCount > 0)
                                                       Padding(
                                                         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                                         child: Text('$approvedCount publication(s) approuvée(s) chargée(s), '
                                                           '$geolocatedCount localisable(s). Vérifiez la ville, les coordonnées et le rayon.',
                                                           style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                                                       ),
                                                    if (errors.isNotEmpty)
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                                        child: Text('Certaines sources sont inaccessibles : ${errors.join(', ')}',
                                                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                                                      ),
                                                    Expanded(
                                                      child: items.isEmpty
                                                          ? const Center(child: Padding(
                                                              padding: EdgeInsets.all(24),
                                                              child: Text('Aucune publication approuvée et localisable dans cette zone.\nEssayez une autre ville ou un rayon plus grand.',
                                                                textAlign: TextAlign.center,
                                                                style: TextStyle(color: Colors.white70, height: 1.5)),
                                                            ))
                                                          : ListView.builder(
                                                              padding: const EdgeInsets.fromLTRB(14, 6, 14, 28),
                                                              itemCount: items.length,
                                                              itemBuilder: (context, index) => _resultCard(items[index]),
                                                            ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
            ),
            ),
            ),
            ),
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
