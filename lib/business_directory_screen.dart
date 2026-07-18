import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class BusinessDirectoryScreen extends StatefulWidget {
  const BusinessDirectoryScreen({super.key});

  @override
  State<BusinessDirectoryScreen> createState() => _BusinessDirectoryScreenState();
}

class _BusinessDirectoryScreenState extends State<BusinessDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _detectedCity = '';
  String _detectedCountry = '';
  String _searchText = '';
  bool _isLocating = false;
  String _locationStatus = '';

  @override
  void initState() {
    super.initState();
    _detectCurrentCity();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentCity() async {
    setState(() {
      _isLocating = true;
      _locationStatus = '';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocating = false;
          _locationStatus = 'Location service is disabled. Turn it on to see nearby businesses.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocating = false;
          _locationStatus = 'Location permission denied. Showing all businesses.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final first = placemarks.isNotEmpty ? placemarks.first : null;

      setState(() {
        _detectedCity = (first?.locality ?? first?.subAdministrativeArea ?? '').trim();
        _detectedCountry = (first?.country ?? '').trim();
        _isLocating = false;
        _locationStatus = _detectedCity.isEmpty
            ? 'Could not identify your city. Showing all businesses.'
            : 'Showing Ethiopian businesses near $_detectedCity.';
      });
    } catch (_) {
      setState(() {
        _isLocating = false;
        _locationStatus = 'Could not read your location right now. Showing all businesses.';
      });
    }
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchText.trim().isEmpty) return true;
    final q = _searchText.toLowerCase().trim();
    final bucket = [
      (data['name'] ?? '').toString(),
      (data['category'] ?? '').toString(),
      (data['businessType'] ?? '').toString(),
      (data['city'] ?? '').toString(),
      (data['country'] ?? '').toString(),
      (data['description'] ?? '').toString(),
      (data['address'] ?? '').toString(),
    ].join(' ').toLowerCase();
    return bucket.contains(q);
  }

  bool _isNearbyCity(Map<String, dynamic> data) {
    if (_detectedCity.isEmpty) return true;
    final city = (data['city'] ?? '').toString().toLowerCase().trim();
    return city == _detectedCity.toLowerCase().trim();
  }

  List<String> _photoUrls(Map<String, dynamic> data) {
    final direct = data['photoUrls'];
    if (direct is List) {
      return direct.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }

    final photos = data['photos'];
    if (photos is List) {
      return photos
          .map((e) => e is Map ? (e['url'] ?? '').toString() : '')
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2E1E),
        centerTitle: true,
        title: const Text('Business Directory', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('business_profiles')
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
          }

          final docs = snapshot.data?.docs ?? [];
          final mapped = docs.map((doc) => doc.data()).toList();

          final cityMatches = mapped.where((data) => _isNearbyCity(data) && _matchesSearch(data)).toList();
          final globalMatches = mapped.where(_matchesSearch).toList();
          final listings = cityMatches.isNotEmpty ? cityMatches : globalMatches;

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E2E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Color(0xFFF5C542)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isLocating
                                ? 'Detecting your location...'
                                : _locationStatus.isEmpty
                                    ? 'Showing Ethiopian businesses.'
                                    : _locationStatus,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                        IconButton(
                          onPressed: _isLocating ? null : _detectCurrentCity,
                          icon: const Icon(Icons.refresh, color: Color(0xFFF5C542), size: 18),
                        ),
                      ],
                    ),
                    if (_detectedCity.isNotEmpty)
                      Text(
                        'Current city: $_detectedCity${_detectedCountry.isEmpty ? '' : ', $_detectedCountry'}',
                        style: const TextStyle(color: Color(0xFFE8D79B), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search Ethiopian restaurants, shops, services...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0E2E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFF59E0B)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${listings.length} businesses found',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (listings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E2E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Text(
                    'No Ethiopian businesses found for the selected location/search yet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                ...listings.map((data) {
                  final name = (data['name'] ?? 'Business').toString();
                  final category = (data['category'] ?? 'General').toString();
                  final businessType = (data['businessType'] ?? '').toString();
                  final city = (data['city'] ?? '').toString();
                  final country = (data['country'] ?? '').toString();
                  final description = (data['description'] ?? '').toString();
                  final photos = _photoUrls(data);

                  return Card(
                    color: const Color(0xFF0E2E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Colors.white10),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BusinessDetailsScreen(data: data),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF123222),
                        backgroundImage: photos.isNotEmpty ? NetworkImage(photos.first) : null,
                        child: photos.isEmpty
                            ? const Icon(Icons.storefront_outlined, color: Color(0xFFF5C542))
                            : null,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 3),
                          Text(
                            '$category${businessType.isEmpty ? '' : ' • $businessType'}',
                            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$city${city.isNotEmpty && country.isNotEmpty ? ', ' : ''}$country',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                          if (description.isNotEmpty)
                            Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFFF5C542), size: 14),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class BusinessDetailsScreen extends StatelessWidget {
  const BusinessDetailsScreen({super.key, required this.data});

  final Map<String, dynamic> data;

  List<String> _photoUrls() {
    final direct = data['photoUrls'];
    if (direct is List) {
      return direct.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }

    final photos = data['photos'];
    if (photos is List) {
      return photos
          .map((e) => e is Map ? (e['url'] ?? '').toString() : '')
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    return const [];
  }

  Widget _line(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: const Color(0xFFF5C542)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(color: Colors.white54)),
                  TextSpan(text: value.trim().isEmpty ? 'Not provided' : value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _serviceRateLabel() {
    final direct = (data['serviceRateText'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;

    final min = (data['serviceRateMin'] is num)
        ? (data['serviceRateMin'] as num).toDouble()
        : (data['serviceRate'] is num)
            ? (data['serviceRate'] as num).toDouble()
            : 0.0;
    final max = (data['serviceRateMax'] is num) ? (data['serviceRateMax'] as num).toDouble() : min;

    if (min <= 0 && max <= 0) return '';
    if (max > min) return 'EUR ${min.toStringAsFixed(0)}-${max.toStringAsFixed(0)}';
    return 'EUR ${min.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photoUrls();
    final name = (data['name'] ?? 'Business').toString();
    final category = (data['category'] ?? 'General').toString();
    final businessType = (data['businessType'] ?? '').toString();
    final owner = (data['ownerName'] ?? '').toString();
    final phone = (data['phone'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final website = (data['website'] ?? '').toString();
    final address = (data['address'] ?? '').toString();
    final city = (data['city'] ?? '').toString();
    final country = (data['country'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final rateLabel = _serviceRateLabel();

    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2E1E),
        centerTitle: true,
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (photos.isNotEmpty)
            SizedBox(
              height: 190,
              child: PageView.builder(
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        photos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFF0E2E1E),
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined, color: Colors.white38),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF0E2E1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: const Center(
                child: Icon(Icons.storefront_outlined, size: 36, color: Color(0xFFF5C542)),
              ),
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$category${businessType.isEmpty ? '' : ' • $businessType'}',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _line(Icons.person_outline, 'Owner/Contact', owner),
                _line(Icons.phone_outlined, 'Phone', phone),
                _line(Icons.mail_outline, 'Email', email),
                _line(Icons.public_outlined, 'Website', website),
                _line(Icons.location_on_outlined, 'Address', address),
                _line(Icons.location_city_outlined, 'City/Country', '$city${city.isNotEmpty && country.isNotEmpty ? ', ' : ''}$country'),
                if (rateLabel.isNotEmpty) _line(Icons.euro_outlined, 'Service Rate', rateLabel),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Details',
                    style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
