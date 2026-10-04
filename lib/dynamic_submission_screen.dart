import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import 'app_session.dart';

class DynamicSubmissionScreen extends StatefulWidget {
  final SubmissionType type;
  final String? editDocumentId;

  const DynamicSubmissionScreen({
    super.key,
    required this.type,
    this.editDocumentId,
  });

  bool get isEditing =>
      editDocumentId != null && editDocumentId!.trim().isNotEmpty;

  @override
  State<DynamicSubmissionScreen> createState() =>
      _DynamicSubmissionScreenState();
}

enum SubmissionType {
  business,
  professional,
  employer,
  event,
  community,
  job,
  verification,
  marketplace,
}

class _DynamicSubmissionScreenState extends State<DynamicSubmissionScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  bool _isLoadingExisting = false;

  final List<String> _existingEventPhotoUrls = [];
  bool _shishaAvailable = false;
  bool _kidsAllowed = false;
  bool _whatsappEnabled = true;
  bool _showExactAddress = false;
  bool _nonRefundable = false;
  bool _nonTransferable = false;
  // Event
  bool _age18Only = false;
  bool _alcoholAvailable = false;
  bool _foodAvailable = false;

  final List<XFile> _eventPhotos = [];
  final List<_EventArtistInput> _eventArtists = [
    _EventArtistInput(),
  ];
  final List<_EventTicketInput> _eventTicketTypes = [
    _EventTicketInput(
      id: 'general',
      name: 'Standard',
      price: 0,
      capacity: 100,
      sold: 0,
    ),
  ];
  String _selectedCountry = 'France';
  String _selectedJobCategory = 'Cleaning';
  String _translatorServiceType = 'In-person';

  // Marketplace
  String _marketplaceType = 'For sale';
  String _marketplaceCondition = 'Like new';
  String _marketplaceDelivery = 'Both';
  final List<XFile> _marketplacePhotos = [];

  final List<XFile> _portfolioPhotos = [];
  final List<XFile> _workPhotos = [];
  final List<XFile> _cateringPhotos = [];
  final List<_MenuItemInput> _menuItems = [];

  final Map<String, String> _countryDialCodes = const {
    'France': '+33',
    'Belgium': '+32',
    'UK': '+44',
    'Netherlands': '+31',
    'Portugal': '+351',
    'Spain': '+34',
    'Italy': '+39',
    'Switzerland': '+41',
    'Finland': '+358',
    'Norway': '+47',
    'Sweden': '+46',
    'Denmark': '+45',
    'Germany': '+49',
    'Greece': '+30',
    'Poland': '+48',
    'Hungary': '+36',
    'Austria': '+43',
    'Bulgaria': '+359',
    'Romania': '+40',
    'Luxembourg': '+352',
    'Turkey': '+90',
  };

  final List<String> _jobCategories = const [
    'Cleaning',
    'Translator',
    'Fashion/Clothes Designer',
    'Catering / Food Seller (Injera & Wot)',
    'Taxi Driver',
    'Mechanic',
    'Electrician',
    'Furniture Assembly',
    'Plumber',
    'Photographer/Videographer',
    'Babysitting/Nanny',
    'Painter',
    'Moving/Transport (Truck)',
    'Airport Luggage Delivery',
    'Hairdresser/Barber',
    'Eyebrow/Beauty Services',
    'Makeup Artist',
    'Nail Technician',
    'Gardener',
    'Car Wash',
    'Tutoring/Language Teacher (e.g., Amharic, Tigrinya)',
  ];

  @override
  void initState() {
    super.initState();

    _controller('phoneNumber').text = '${_countryDialCodes[_selectedCountry]} ';

    if (widget.isEditing && widget.type == SubmissionType.event) {
      _loadExistingEvent();
    }
  }

  Future<void> _loadExistingEvent() async {
    final documentId = widget.editDocumentId;

    if (documentId == null || documentId.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingExisting = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('eventSubmissions')
          .doc(documentId)
          .get();

      if (!snapshot.exists) {
        throw Exception('Event submission not found.');
      }

      final data = snapshot.data() ?? <String, dynamic>{};
      final publicEventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(documentId)
          .get();

      final publicEventData = publicEventSnapshot.data() ?? <String, dynamic>{};

      final publicTicketTypes = publicEventData['ticketTypes'] is List
          ? publicEventData['ticketTypes'] as List
          : const [];
      final rawFields = data['fields'];
      final fields = rawFields is Map
          ? Map<String, dynamic>.from(rawFields)
          : <String, dynamic>{};

      for (final entry in fields.entries) {
        if (entry.key == 'country' || entry.key == 'showExactAddress') {
          continue;
        }

        _controller(entry.key).text = entry.value?.toString() ?? '';
      }

      final country = fields['country']?.toString().trim();

      if (country != null && _countryDialCodes.containsKey(country)) {
        _selectedCountry = country;
      }

      _showExactAddress = fields['showExactAddress'] == true;

      final rawDetails = data['eventDetails'];
      final details = rawDetails is Map
          ? Map<String, dynamic>.from(rawDetails)
          : <String, dynamic>{};

      _age18Only = details['age18Only'] == true;

      _kidsAllowed = details['kidsAllowed'] == true;

      _shishaAvailable = details['shishaAvailable'] == true;

      _alcoholAvailable = details['alcoholAvailable'] == true;

      _foodAvailable = details['foodAvailable'] == true;

      _nonRefundable = details['nonRefundable'] == true;

      _nonTransferable = details['nonTransferable'] == true;

      final rawTicketTypes = publicTicketTypes.isNotEmpty
          ? publicTicketTypes
          : data['ticketTypes'];

      if (rawTicketTypes is List) {
        for (final ticket in _eventTicketTypes) {
          ticket.dispose();
        }

        _eventTicketTypes.clear();

        for (final rawTicket in rawTicketTypes) {
          if (rawTicket is! Map) {
            continue;
          }

          final ticket = Map<String, dynamic>.from(rawTicket);

          _eventTicketTypes.add(
            _EventTicketInput(
              id: ticket['id']?.toString() ?? '',
              name: ticket['name']?.toString() ?? '',
              price: (ticket['price'] as num?)?.toDouble() ?? 0,
              capacity: (ticket['capacity'] as num?)?.toInt() ?? 0,
              sold: (ticket['sold'] as num?)?.toInt() ?? 0,
              active: ticket['active'] != false,
            ),
          );
        }
      }

      if (_eventTicketTypes.isEmpty) {
        _eventTicketTypes.add(
          _EventTicketInput(
            id: 'general',
            name: 'Standard',
            price: 0,
            capacity: 100,
            sold: 0,
          ),
        );
      }
      final rawMedia = data['eventMedia'] ?? data['media'];

      if (rawMedia is Map) {
        final media = Map<String, dynamic>.from(rawMedia);

        final rawPhotoUrls = media['photoUrls'];

        if (rawPhotoUrls is List) {
          _existingEventPhotoUrls
            ..clear()
            ..addAll(
              rawPhotoUrls
                  .map((url) => url.toString())
                  .where((url) => url.isNotEmpty),
            );
        }
      }

      final rawArtists = data['artists'];

      if (rawArtists is List) {
        for (final artist in _eventArtists) {
          artist.dispose();
        }

        _eventArtists.clear();

        for (final rawArtist in rawArtists) {
          if (rawArtist is! Map) continue;

          final artist = Map<String, dynamic>.from(rawArtist);

          final input = _EventArtistInput();

          input.nameController.text = artist['name']?.toString() ?? '';

          final existingPhotoUrl = artist['photoUrl']?.toString().trim();

          if (existingPhotoUrl != null && existingPhotoUrl.isNotEmpty) {
            input.existingPhotoUrl = existingPhotoUrl;
          }

          _eventArtists.add(input);
        }

        if (_eventArtists.isEmpty) {
          _eventArtists.add(
            _EventArtistInput(),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isLoadingExisting = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingExisting = false;
      });

      _showMessage(
        'Unable to load event: $error',
        isError: true,
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    for (final item in _menuItems) {
      item.dispose();
    }
    for (final artist in _eventArtists) {
      artist.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String key) {
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(),
    );
  }

  String get _title {
    return switch (widget.type) {
      SubmissionType.business => 'Register a Business / Restaurant',
      SubmissionType.professional => 'Register as a Professional',
      SubmissionType.event =>
        widget.isEditing ? 'Edit Event' : 'Submit an Event',
      SubmissionType.community => 'Register a Community',
      SubmissionType.job => 'Submit a Job or Service',
      SubmissionType.verification => 'Request Verification',
      SubmissionType.marketplace => 'Post Marketplace Item',
      SubmissionType.employer => 'Créer un profil Employeur',
    };
  }

  String get _collectionName {
    return switch (widget.type) {
      SubmissionType.business => 'businessSubmissions',
      SubmissionType.professional => 'jobSubmissions',
      SubmissionType.event => 'eventSubmissions',
      SubmissionType.community => 'communitySubmissions',
      SubmissionType.job => 'jobSubmissions',
      SubmissionType.verification => 'verificationRequests',
      SubmissionType.marketplace => 'marketplaceSubmissions',
      SubmissionType.employer => 'employerSubmissions',
    };
  }

  Future<Map<String, dynamic>?> _geocodeSubmissionLocation() async {
    try {
      final cityAddress = _controllers['cityAddress']?.text.trim() ?? '';
      final address = _controllers['address']?.text.trim() ?? '';
      final country = _selectedCountry.trim();

      final parts = <String>[
        if (address.isNotEmpty) address,
        if (cityAddress.isNotEmpty) cityAddress,
        if (country.isNotEmpty) country,
      ];

      if (parts.isEmpty) {
        return null;
      }

      final searchAddress = parts.join(', ');

      final geocoder = geocoding.Geocoding();

      final locations = await geocoder.locationFromAddress(
        searchAddress,
      );

      if (locations.isEmpty) {
        return null;
      }

      final location = locations.first;

      return {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'geoPoint': GeoPoint(
          location.latitude,
          location.longitude,
        ),
        'geocodedAddress': searchAddress,
      };
    } catch (_) {
      // Une erreur de géocodage ne doit jamais empêcher la publication.
      return null;
    }
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSignInRequired(
        'Please sign in before submitting for admin approval.',
      );
      return;
    }

    if (AppSession.isGuest) {
      AppSession.signIn(
        name: user.displayName ?? user.email ?? 'Euro Habesha Member',
        emailAddress: user.email ?? '',
        verified: user.emailVerified,
      );
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (widget.type == SubmissionType.marketplace &&
        _marketplacePhotos.isEmpty) {
      _showMessage(
        'Please add at least one photo.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final geoLocation = await _geocodeSubmissionLocation();

      List<String> marketplacePhotoUrls = [];

      if (widget.type == SubmissionType.marketplace) {
        marketplacePhotoUrls = await _uploadMarketplacePhotos(user.uid);
      }

      List<String> eventPhotoUrls = [
        ..._existingEventPhotoUrls,
      ];

      if (widget.type == SubmissionType.event && _eventPhotos.isNotEmpty) {
        final newPhotoUrls = await _uploadEventPhotos(user.uid);

        eventPhotoUrls.addAll(newPhotoUrls);
      }

      List<Map<String, dynamic>> eventArtists = [];

      if (widget.type == SubmissionType.event) {
        eventArtists = await _uploadEventArtists(user.uid);
      }

      final eventTicketTypes = <Map<String, dynamic>>[];

      if (widget.type == SubmissionType.event) {
        for (var index = 0; index < _eventTicketTypes.length; index++) {
          final ticket = _eventTicketTypes[index];

          final name = ticket.nameController.text.trim();

          final price = double.tryParse(
            ticket.priceController.text.trim().replaceAll(',', '.'),
          );

          final capacity = int.tryParse(
            ticket.capacityController.text.trim(),
          );

          if (name.isEmpty) {
            throw Exception(
              'Ticket ${index + 1}: please enter a ticket name.',
            );
          }

          if (price == null || price < 0) {
            throw Exception(
              'Ticket ${index + 1}: please enter a valid price.',
            );
          }

          if (capacity == null || capacity <= 0) {
            throw Exception(
              'Ticket ${index + 1}: please enter a valid number of tickets.',
            );
          }

          if (capacity < ticket.sold) {
            throw Exception(
              '"$name" already has ${ticket.sold} sold tickets. '
              'Capacity cannot be lower than tickets already sold.',
            );
          }

          var ticketId = ticket.id.trim();

          if (ticketId.isEmpty) {
            final normalizedName = name
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                .replaceAll(RegExp(r'^-+|-+$'), '');

            ticketId =
                normalizedName.isEmpty ? 'ticket-${index + 1}' : normalizedName;
          }

          eventTicketTypes.add({
            'id': ticketId,
            'name': name,
            'price': price,
            'capacity': capacity,
            'sold': ticket.sold,
            'active': ticket.active,
          });
        }
      }

      final data = <String, dynamic>{
        'type': widget.type.name,
        'status': 'pendingApproval',
        'isVerified': false,
        'submittedBy': user.uid,
        'ownerId': user.uid,
        'creatorId': user.uid,
        'submitterEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'fields': {
          ..._controllers.map(
            (key, controller) => MapEntry(
              key,
              controller.text.trim(),
            ),
          ),
          'country': _selectedCountry,
          'showExactAddress': _showExactAddress,
          if (geoLocation != null) ...{
            'latitude': geoLocation['latitude'],
            'longitude': geoLocation['longitude'],
            'geoPoint': geoLocation['geoPoint'],
            'geocodedAddress': geoLocation['geocodedAddress'],
          },
          if (widget.type == SubmissionType.job) ...{
            'jobCategory': _selectedJobCategory,
            'translatorServiceType': _translatorServiceType,
          },
        },
        if (geoLocation != null) ...{
          'latitude': geoLocation['latitude'],
          'longitude': geoLocation['longitude'],
          'geoPoint': geoLocation['geoPoint'],
          'geocodedAddress': geoLocation['geocodedAddress'],
          'geocodedAt': FieldValue.serverTimestamp(),
        },
      };
      if (widget.type == SubmissionType.marketplace) {
        data['media'] = {
          'photoUrls': marketplacePhotoUrls,
        };
      }

      if (widget.type == SubmissionType.event) {
        data['media'] = {
          'photoUrls': eventPhotoUrls,
        };
      }

      if (widget.type == SubmissionType.business) {
        data['contactModel'] = {
          'inAppMessagingEnabled': false,
          'primaryAction': 'callForReservation',
          'reservePlusReady': true,
          'liveZoneReady': true,
        };
      }

      if (widget.type == SubmissionType.job) {
        data['contactModel'] = {
          'inAppMessagingEnabled': true,
          'whatsappEnabled': _whatsappEnabled,
        };

        data['media'] = {
          'portfolioPhotoPaths':
              _portfolioPhotos.map((file) => file.path).toList(),
          'workPhotoPaths': _workPhotos.map((file) => file.path).toList(),
          'cateringPhotoPaths':
              _cateringPhotos.map((file) => file.path).toList(),
        };

        data['menuItems'] = _menuItems.map((item) => item.toMap()).toList();

        data['orderingModel'] = {
          'cashOnDeliveryOnly':
              _selectedJobCategory == 'Fashion/Clothes Designer',
          'depositPercentage': double.tryParse(
                _controller('depositPercentage').text.trim(),
              ) ??
              0,
          'paymentMethods': [
            'cashOnDelivery',
            'appDeposit',
          ],
        };
      }

      data['ticketTypes'] = eventTicketTypes;
      data['ticketingEnabled'] = eventTicketTypes.isNotEmpty;
      data['nonRefundable'] = _nonRefundable;
      data['nonTransferable'] = _nonTransferable;

      if (widget.type == SubmissionType.event) {
        data['eventDetails'] = {
          'age18Only': _age18Only,
          'kidsAllowed': _kidsAllowed,
          'shishaAvailable': _shishaAvailable,
          'alcoholAvailable': _alcoholAvailable,
          'foodAvailable': _foodAvailable,
          'nonRefundable': _nonRefundable,
          'nonTransferable': _nonTransferable,
          'visualBadges': [
            'performer',
            'endTime',
            if (_age18Only) '18plus',
            if (_kidsAllowed) 'kidsAllowed',
            if (_shishaAvailable) 'shisha',
            if (_alcoholAvailable) 'alcohol',
            if (_foodAvailable) 'food',
          ],
        };

        data['eventMedia'] = {
          'photoUrls': eventPhotoUrls,
          'photoCount': eventPhotoUrls.length,
          'coverUrl': eventPhotoUrls.isNotEmpty ? eventPhotoUrls.first : null,
        };

        data['artists'] = eventArtists;

        final artistNames = eventArtists
            .map(
              (artist) => artist['name']?.toString().trim() ?? '',
            )
            .where((name) => name.isNotEmpty)
            .toList();

        final fields = data['fields'] as Map<String, dynamic>;

        fields['performerDj'] = artistNames.join(', ');

        data['imageUrl'] =
            eventPhotoUrls.isNotEmpty ? eventPhotoUrls.first : null;
        data['image'] = eventPhotoUrls.isNotEmpty ? eventPhotoUrls.first : null;
      }

      if (widget.type == SubmissionType.marketplace) {
        data['marketplaceDetails'] = {
          'listingType': _marketplaceType,
          'condition': _marketplaceCondition,
          'deliveryOption': _marketplaceDelivery,
          'photoUrls': marketplacePhotoUrls,
          'photoCount': marketplacePhotoUrls.length,
          'mainPhotoUrl': marketplacePhotoUrls.isNotEmpty
              ? marketplacePhotoUrls.first
              : null,
        };
      }

      if (widget.isEditing && widget.type == SubmissionType.event) {
        final documentId = widget.editDocumentId!;

        final submissionRef = FirebaseFirestore.instance
            .collection('eventSubmissions')
            .doc(documentId);

        final existingSubmission = await submissionRef.get();

        if (!existingSubmission.exists) {
          throw Exception(
            'Event submission not found.',
          );
        }

        final existingData = existingSubmission.data() ?? <String, dynamic>{};
        data['ownerId'] = existingData['ownerId'] ?? user.uid;

        final publicEventRef =
            FirebaseFirestore.instance.collection('events').doc(documentId);

        final latestPublicEvent = await publicEventRef.get();

        if (latestPublicEvent.exists) {
          final latestPublicData =
              latestPublicEvent.data() ?? <String, dynamic>{};

          final latestTicketTypes = latestPublicData['ticketTypes'];

          if (latestTicketTypes is List && data['ticketTypes'] is List) {
            final latestSoldById = <String, int>{};

            for (final rawTicket in latestTicketTypes) {
              if (rawTicket is! Map) continue;

              final ticket = Map<String, dynamic>.from(rawTicket);
              final ticketId = ticket['id']?.toString() ?? '';

              if (ticketId.isEmpty) continue;

              latestSoldById[ticketId] = (ticket['sold'] as num?)?.toInt() ?? 0;
            }

            final editedTickets = data['ticketTypes'] as List;

            data['ticketTypes'] = editedTickets.map((rawTicket) {
              final ticket = Map<String, dynamic>.from(rawTicket as Map);

              final ticketId = ticket['id']?.toString() ?? '';

              if (latestSoldById.containsKey(ticketId)) {
                ticket['sold'] = latestSoldById[ticketId];
              }

              return ticket;
            }).toList();
          }
        }

        data['ownerId'] = existingData['ownerId'] ?? user.uid;
        data['creatorId'] = existingData['creatorId'] ?? user.uid;
        data['submittedBy'] = existingData['submittedBy'] ?? user.uid;
        data['submitterEmail'] = existingData['submitterEmail'] ?? user.email;
        // Pendant une modification, on conserve le statut
        // actuel de l'événement.
        data['status'] = existingData['status'] ?? 'pendingApproval';

        data['isVerified'] = existingData['isVerified'] ?? false;

        data['createdAt'] =
            existingData['createdAt'] ?? FieldValue.serverTimestamp();

        data['updatedAt'] = FieldValue.serverTimestamp();

        data['updatedBy'] = user.uid;

        await submissionRef.set(
          data,
          SetOptions(merge: true),
        );

        // Si l'événement est déjà publié, on synchronise
        // également sa version publique.
        final publicEvent = await publicEventRef.get();
        if (publicEvent.exists) {
          await publicEventRef.set(
            {
              ...data,
              'status': 'published',
              'updatedAt': FieldValue.serverTimestamp(),
              'updatedBy': user.uid,
            },
            SetOptions(merge: true),
          );
        }
      } else {
        await FirebaseFirestore.instance.collection(_collectionName).add(data);
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Event updated successfully.'
                : 'Your submission has been sent for admin approval.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Submission failed: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<List<String>> _uploadMarketplacePhotos(String uid) async {
    final urls = <String>[];

    for (var index = 0; index < _marketplacePhotos.length; index++) {
      final file = _marketplacePhotos[index];

      final extension = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';

      final storagePath =
          'marketplace/$uid/${DateTime.now().millisecondsSinceEpoch}_$index.$extension';

      final reference = FirebaseStorage.instance.ref().child(storagePath);

      final metadata = SettableMetadata(
        contentType: _contentTypeForExtension(extension),
      );

      await reference.putFile(
        File(file.path),
        metadata,
      );

      final downloadUrl = await reference.getDownloadURL();
      urls.add(downloadUrl);
    }

    return urls;
  }

  Future<List<String>> _uploadEventPhotos(String uid) async {
    final urls = <String>[];

    for (var index = 0; index < _eventPhotos.length; index++) {
      final file = _eventPhotos[index];

      final extension = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final storagePath = 'events/$uid/${timestamp}_$index.$extension';

      final reference = FirebaseStorage.instance.ref().child(storagePath);

      final metadata = SettableMetadata(
        contentType: _contentTypeForExtension(extension),
      );

      await reference.putFile(
        File(file.path),
        metadata,
      );

      final downloadUrl = await reference.getDownloadURL();
      urls.add(downloadUrl);
    }

    return urls;
  }

  Future<List<Map<String, dynamic>>> _uploadEventArtists(
    String uid,
  ) async {
    final artists = <Map<String, dynamic>>[];

    for (var index = 0; index < _eventArtists.length; index++) {
      final artist = _eventArtists[index];
      final name = artist.nameController.text.trim();

      if (name.isEmpty &&
          artist.photo == null &&
          (artist.existingPhotoUrl == null ||
              artist.existingPhotoUrl!.isEmpty)) {
        continue;
      }

      String? photoUrl = artist.existingPhotoUrl;

      if (artist.photo != null) {
        final file = artist.photo!;

        final extension = file.name.contains('.')
            ? file.name.split('.').last.toLowerCase()
            : 'jpg';

        final timestamp = DateTime.now().millisecondsSinceEpoch;

        final storagePath =
            'events/$uid/artists/${timestamp}_$index.$extension';

        final reference = FirebaseStorage.instance.ref().child(storagePath);

        final metadata = SettableMetadata(
          contentType: _contentTypeForExtension(extension),
        );

        await reference.putFile(
          File(file.path),
          metadata,
        );

        photoUrl = await reference.getDownloadURL();
      }

      artists.add({
        'name': name,
        'photoUrl': photoUrl,
      });
    }

    return artists;
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  void _showSignInRequired(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGreen,
        title: const Text(
          'Account Required',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text(
              'Sign In / Register',
              style: TextStyle(
                color: primaryDarkGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.redAccent : primaryGold,
        content: Text(
          message,
          style: TextStyle(
            color: isError ? Colors.white : primaryDarkGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingExisting) {
      return const Scaffold(
        backgroundColor: primaryDarkGreen,
        body: Center(
          child: CircularProgressIndicator(
            color: primaryGold,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text(
          _title,
          style: const TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(
          color: primaryGold,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).padding.bottom + 32,
          ),
          children: [
            if (widget.type == SubmissionType.marketplace)
              _buildMarketplaceHeader(),
            _buildCommonFields(),
            const SizedBox(height: 12),
            ..._buildTypeFields(),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isSubmitting
                  ? null
                  : widget.type == SubmissionType.event
                      ? _openEventPreview
                      : _submit,
              child: Text(
                _isSubmitting
                    ? (widget.isEditing ? 'Saving...' : 'Submitting...')
                    : widget.type == SubmissionType.event
                        ? (widget.isEditing
                            ? 'Preview Changes'
                            : 'Preview Event')
                        : 'Submit for Admin Approval',
                style: const TextStyle(
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

  Widget _buildMarketplaceHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF004D40),
            Color(0xFF00695C),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.storefront_rounded,
            color: primaryGold,
            size: 34,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marketplace',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Create a clear and professional listing. '
                  'Your photos and information will be reviewed by an admin before publication.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEventPreview() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final title = _controller('title').text.trim();
    final category = _controller('eventCategory').text.trim();
    final date = _controller('eventDate').text.trim();
    final startTime = _controller('startTime').text.trim();
    final endTime = _controller('endTime').text.trim();
    final location = _controller('cityAddress').text.trim();
    final description = _controller('description').text.trim();

    final organizerName = _controller('organizerName').text.trim();
    final organizerEmail = _controller('organizerEmail').text.trim();
    final phone = _controller('phoneNumber').text.trim();
    final siren = _controller('sirenNumber').text.trim();

    final artists = _eventArtists
        .where(
          (artist) =>
              artist.nameController.text.trim().isNotEmpty ||
              artist.photo != null,
        )
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: primaryDarkGreen,
      builder: (previewContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(previewContext).size.height * 0.94,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    8,
                    8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(previewContext),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Event Preview',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      24,
                    ),
                    children: [
                      if (_eventPhotos.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(_eventPhotos.first.path),
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: cardGreen,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.event,
                              color: primaryGold,
                              size: 64,
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (category.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          category,
                          style: const TextStyle(
                            color: primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _buildEventPreviewInfo(
                        Icons.calendar_month,
                        'Date',
                        date,
                      ),
                      _buildEventPreviewInfo(
                        Icons.schedule,
                        'Time',
                        endTime.isEmpty ? startTime : '$startTime - $endTime',
                      ),
                      _buildEventPreviewInfo(
                        Icons.location_on_outlined,
                        'Location',
                        location,
                      ),
                      const SizedBox(height: 18),
                      _buildEventPreviewTitle('About'),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                      if (artists.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildEventPreviewTitle(
                          'Artists & Performers',
                        ),
                        const SizedBox(height: 10),
                        for (final artist in artists)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cardGreen,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: artist.photo != null
                                      ? Image.file(
                                          File(
                                            artist.photo!.path,
                                          ),
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 64,
                                          height: 64,
                                          color: primaryDarkGreen,
                                          child: const Icon(
                                            Icons.mic,
                                            color: primaryGold,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    artist.nameController.text.trim().isEmpty
                                        ? 'Artist / Performer'
                                        : artist.nameController.text.trim(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: 24),
                      _buildEventPreviewTitle(
                        'Event Information',
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_age18Only)
                            _buildEventPreviewBadge(
                              Icons.eighteen_up_rating,
                              '18+',
                            ),
                          if (_kidsAllowed)
                            _buildEventPreviewBadge(
                              Icons.family_restroom,
                              'Kids allowed',
                            ),
                          if (_shishaAvailable)
                            _buildEventPreviewBadge(
                              Icons.check_circle_outline,
                              'Shisha / Hookah',
                            ),
                          if (_alcoholAvailable)
                            _buildEventPreviewBadge(
                              Icons.local_bar_outlined,
                              'Alcohol',
                            ),
                          if (_foodAvailable)
                            _buildEventPreviewBadge(
                              Icons.restaurant_outlined,
                              'Food / Buffet',
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildEventPreviewTitle('Organizer'),
                      _buildEventPreviewInfo(
                        Icons.business_outlined,
                        'Organizer',
                        organizerName,
                      ),
                      _buildEventPreviewInfo(
                        Icons.phone_outlined,
                        'Phone',
                        phone,
                      ),
                      _buildEventPreviewInfo(
                        Icons.email_outlined,
                        'Email',
                        organizerEmail,
                      ),
                      if (siren.isNotEmpty)
                        _buildEventPreviewInfo(
                          Icons.badge_outlined,
                          'SIREN',
                          siren,
                        ),
                      const SizedBox(height: 20),
                      if (_nonRefundable)
                        const Text(
                          '• Tickets are non-refundable.',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      if (_nonTransferable)
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            '• Tickets are non-transferable.',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    16,
                  ),
                  decoration: const BoxDecoration(
                    color: primaryDarkGreen,
                    border: Border(
                      top: BorderSide(
                        color: Colors.white12,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(previewContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white38,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          child: const Text('Back to Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(previewContext);
                            _submit();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGold,
                            foregroundColor: primaryDarkGreen,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          child: Text(
                            widget.isEditing
                                ? 'Save Changes'
                                : 'Submit for Approval',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventPreviewTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: primaryGold,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEventPreviewInfo(
    IconData icon,
    String label,
    String value,
  ) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: primaryGold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventPreviewBadge(
    IconData icon,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryGold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: primaryGold,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonFields() {
    return Column(
      children: [
        _buildField(
          'title',
          'Title / Name *',
        ),
        const SizedBox(height: 12),
        _buildCountryDropdown(),
        const SizedBox(height: 12),
        _buildField(
          'phoneNumber',
          'Phone Number *',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _buildField(
          'cityAddress',
          'City & Address *',
        ),
        const SizedBox(height: 12),
        _buildField(
          'description',
          'Description *',
          maxLines: 5,
        ),
      ],
    );
  }

  List<Widget> _buildTypeFields() {
    return switch (widget.type) {
      SubmissionType.employer => [
          _buildField(
            'companyName',
            'Nom de l’entreprise / organisation *',
          ),
          const SizedBox(height: 12),
          _buildField(
            'businessSector',
            'Secteur d’activité *',
          ),
          const SizedBox(height: 12),
          _buildField(
            'contactPerson',
            'Nom du responsable / recruteur *',
          ),
          const SizedBox(height: 12),
          _buildField(
            'address',
            'Adresse',
          ),
          const SizedBox(height: 12),
          _buildField(
            'websiteUrl',
            'Site internet (optionnel)',
          ),
          const SizedBox(height: 12),
          _buildField(
            'companyDescription',
            'Présentation de l’entreprise / organisation',
            maxLines: 3,
          ),
        ],
      SubmissionType.event => [
          const Text(
            'Event Details',
            style: TextStyle(
              color: primaryGold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell people everything they need to know about your event.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          _buildField(
            'eventCategory',
            'Event category, e.g. Music, Party, Festival, Cultural',
          ),
          const SizedBox(height: 12),
          _buildEventDateField(),
          const SizedBox(height: 12),
          _buildEventTimeField(
            key: 'startTime',
            label: 'Start time *',
          ),
          const SizedBox(height: 12),
          _buildEventTimeField(
            key: 'endTime',
            label: 'End time *',
          ),
          const SizedBox(height: 20),
          const Text(
            'Organizer Information',
            style: TextStyle(
              color: primaryGold,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildField(
            'organizerName',
            'Organizer / Company name',
          ),
          const SizedBox(height: 12),
          _buildField(
            'sirenNumber',
            'SIREN number (optional)',
          ),
          const SizedBox(height: 12),
          _buildField(
            'organizerEmail',
            'Organizer email',
          ),
          const SizedBox(height: 20),
          const Text(
            'Artists & Performers',
            style: TextStyle(
              color: primaryGold,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildEventArtistsBuilder(),
          const SizedBox(height: 24),
          const Text(
            'Tickets & Prices',
            style: TextStyle(
              color: primaryGold,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your ticket types, prices and available places.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _buildEventTicketTypes(),
          const SizedBox(height: 24),
          const Text(
            'Event Photos',
            style: TextStyle(
              color: primaryGold,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add up to 5 photos. The first photo will be used as the event cover.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _buildEventPhotoPicker(),
          const SizedBox(height: 22),
          const Text(
            'Event Options & Policies',
            style: TextStyle(
              color: primaryGold,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildSwitch(
            '18+ only',
            _age18Only,
            (value) {
              setState(() {
                _age18Only = value;

                if (value) {
                  _kidsAllowed = false;
                }
              });
            },
          ),
          _buildSwitch(
            'Kids allowed',
            _kidsAllowed,
            (value) {
              setState(() {
                _kidsAllowed = value;

                if (value) {
                  _age18Only = false;
                }
              });
            },
          ),
          _buildSwitch(
            'Shisha / Hookah available',
            _shishaAvailable,
            (value) {
              setState(() {
                _shishaAvailable = value;
              });
            },
          ),
          _buildSwitch(
            'Alcohol served',
            _alcoholAvailable,
            (value) {
              setState(() {
                _alcoholAvailable = value;
              });
            },
          ),
          _buildSwitch(
            'Food / Buffet available',
            _foodAvailable,
            (value) {
              setState(() {
                _foodAvailable = value;
              });
            },
          ),
          _buildSwitch(
            'Tickets are non-refundable',
            _nonRefundable,
            (value) {
              setState(() {
                _nonRefundable = value;
              });
            },
          ),
          _buildSwitch(
            'Tickets are non-transferable',
            _nonTransferable,
            (value) {
              setState(() {
                _nonTransferable = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildField(
            'amenities',
            'Other amenities, e.g. parking, VIP area, cloakroom',
            maxLines: 3,
          ),
        ],
      SubmissionType.community => [
          _buildDropdown(
            label: 'Community category *',
            value: _controller('communityCategory').text.isEmpty
                ? 'Groupes & Associations'
                : _controller('communityCategory').text,
            values: const [
              'Groupes & Associations',
              'Habesha par ville',
              'Entraide',
              'Logement',
              'Transport & déplacement',
              'Aide administrative',
              'Langues & traduction',
              'Études & formation',
              'Familles & parents',
              'Carrière & mentorat',
              'Culture & rencontres',
              'Bénévolat & solidarité',
            ],
            onChanged: (value) {
              setState(() {
                _controller('communityCategory').text = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildField(
            'communityType',
            'Community type, e.g. Orthodox Church, Mosque',
          ),
          const SizedBox(height: 12),
          _buildField(
            'meetingSchedule',
            'Service / gathering schedule',
          ),
          const SizedBox(height: 12),
          _buildField(
            'leaderName',
            'Leader or contact person',
          ),
          const SizedBox(height: 12),
          _buildField(
            'address',
            'Full address',
          ),
        ],
      SubmissionType.job => [
          _buildJobCategoryDropdown(),
          const SizedBox(height: 12),
          ..._buildJobSpecificFields(),
          const SizedBox(height: 12),
          _buildSwitch(
            'Allow WhatsApp contact using this phone number',
            _whatsappEnabled,
            (value) => setState(
              () => _whatsappEnabled = value,
            ),
          ),
          _buildSwitch(
            'Show exact address publicly',
            _showExactAddress,
            (value) => setState(
              () => _showExactAddress = value,
            ),
          ),
          _buildField(
            'cityOnlyLocation',
            'City shown publicly, e.g. Lyon',
            maxLines: 1,
          ),
          const SizedBox(height: 12),
          _buildField(
            'requirements',
            'Requirements / service details',
            maxLines: 3,
          ),
        ],
      SubmissionType.professional => [
          _buildField(
            'professionTitle',
            'Professional Title (Doctor, Lawyer, Translator, Caterer, etc.) *',
          ),
          const SizedBox(height: 12),
          _buildField(
            'registrationNumber',
            'SIRET / Professional License / Registration ID',
          ),
          const SizedBox(height: 12),
          _buildField(
            'servicesOffered',
            'Services Offered (list services, one per line) *',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildField(
            'pricingDetails',
            'Pricing & Rates (e.g. €25/hour, from €30/doc, menu prices) *',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildField(
            'qualifications',
            'Qualifications, Diplomas & Experience',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildField(
            'websiteUrl',
            'Website, LinkedIn or Portfolio URL (optional)',
          ),
          const SizedBox(height: 12),
          _buildSwitch(
            'Allow WhatsApp contact using this phone number',
            _whatsappEnabled,
            (value) => setState(
              () => _whatsappEnabled = value,
            ),
          ),
          _buildSwitch(
            'Show exact address publicly',
            _showExactAddress,
            (value) => setState(
              () => _showExactAddress = value,
            ),
          ),
        ],
      SubmissionType.business => [
          _buildField(
            'businessCategory',
            'Business category',
          ),
          const SizedBox(height: 12),
          _buildField(
            'openingHours',
            'Opening hours',
          ),
          const SizedBox(height: 12),
          _buildField(
            'address',
            'Full address',
          ),
          const SizedBox(height: 8),
          const Text(
            'Business profiles use Call for Reservation only. '
            'In-app messaging is disabled. Reserve Plus and Live Zone '
            'fields are reserved for future release.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      SubmissionType.verification => [
          _buildField(
            'verificationType',
            'Verification type',
          ),
          const SizedBox(height: 12),
          _buildField(
            'documentSummary',
            'Document or proof summary',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildField(
            'publicProfileLink',
            'Website or profile link',
          ),
        ],
      SubmissionType.marketplace => [
          _buildMarketplacePhotoPicker(),
          const SizedBox(height: 16),
          _buildMarketplaceTypeDropdown(),
          const SizedBox(height: 12),
          _buildMarketplaceCategoryDropdown(),
          const SizedBox(height: 12),
          _buildField(
            'price',
            'Price (€) *',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildMarketplaceConditionDropdown(),
          const SizedBox(height: 12),
          _buildMarketplaceDeliveryDropdown(),
          const SizedBox(height: 12),
          _buildSwitch(
            'Allow WhatsApp contact using this phone number',
            _whatsappEnabled,
            (value) => setState(
              () => _whatsappEnabled = value,
            ),
          ),
          _buildSwitch(
            'Show exact address publicly',
            _showExactAddress,
            (value) => setState(
              () => _showExactAddress = value,
            ),
          ),
        ],
    };
  }

  Widget _buildMarketplacePhotoPicker() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryGold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.photo_library_outlined,
                color: primaryGold,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Photos *',
                  style: TextStyle(
                    color: primaryGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '${_marketplacePhotos.length}/6',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Add clear photos of your product. '
            'The first photo will be used as the main image.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          if (_marketplacePhotos.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _marketplacePhotos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final photo = _marketplacePhotos[index];

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(photo.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        left: 5,
                        bottom: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'MAIN',
                            style: TextStyle(
                              color: primaryDarkGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _marketplacePhotos.removeAt(index);
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 12),
          if (_marketplacePhotos.length < 6)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickMarketplacePhotos,
                icon: const Icon(
                  Icons.add_a_photo_outlined,
                ),
                label: Text(
                  _marketplacePhotos.isEmpty ? 'Add photos' : 'Add more photos',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGold,
                  side: const BorderSide(
                    color: primaryGold,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickMarketplacePhotos() async {
    try {
      final remaining = 6 - _marketplacePhotos.length;

      if (remaining <= 0) {
        return;
      }

      final picked = await _picker.pickMultiImage(
        limit: remaining,
        imageQuality: 85,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (picked.isEmpty) {
        return;
      }

      setState(() {
        _marketplacePhotos.addAll(
          picked.take(remaining),
        );
      });
    } catch (e) {
      _showMessage(
        'Could not select photos: $e',
        isError: true,
      );
    }
  }

  Widget _buildMarketplaceTypeDropdown() {
    return _buildDropdown(
      label: 'Listing Type *',
      value: _marketplaceType,
      values: const [
        'For sale',
        'For rent',
        'Service',
      ],
      onChanged: (value) {
        setState(() {
          _marketplaceType = value;
        });
      },
    );
  }

  Widget _buildMarketplaceCategoryDropdown() {
    const categories = [
      'Habesha & Traditional',
      'Traditional Clothing',
      'Coffee & Ceremony',
      'Food & Spices',
      'Jewelry & Accessories',
      'Art & Decoration',
      'Vehicles',
      'Phones & Electronics',
      'Home & Furniture',
      'Fashion',
      'Beauty',
      'Baby & Kids',
      'Other',
    ];

    final categoryController = _controller('itemCategory');
    final savedCategory = categoryController.text.trim();

    final selectedValue = categories.contains(savedCategory)
        ? savedCategory
        : 'Habesha & Traditional';

    // Important:
    // If the user keeps the default category without touching
    // the dropdown, the category must still be saved in Firestore.
    if (categoryController.text.trim() != selectedValue) {
      categoryController.text = selectedValue;
    }

    return _buildDropdown(
      label: 'Category *',
      value: selectedValue,
      values: categories,
      onChanged: (value) {
        setState(() {
          categoryController.text = value;
        });
      },
    );
  }

  Widget _buildMarketplaceConditionDropdown() {
    return _buildDropdown(
      label: 'Condition *',
      value: _marketplaceCondition,
      values: const [
        'New',
        'Like new',
        'Good',
        'Used',
        'For parts',
      ],
      onChanged: (value) {
        setState(() {
          _marketplaceCondition = value;
        });
      },
    );
  }

  Widget _buildMarketplaceDeliveryDropdown() {
    return _buildDropdown(
      label: 'Delivery / Collection',
      value: _marketplaceDelivery,
      values: const [
        'Both',
        'Pickup only',
        'Delivery only',
      ],
      onChanged: (value) {
        setState(() {
          _marketplaceDelivery = value;
        });
      },
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCountry,
      isExpanded: true,
      dropdownColor: cardGreen,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: 'Country *',
        labelStyle: const TextStyle(
          color: Colors.white54,
        ),
        filled: true,
        fillColor: cardGreen,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      selectedItemBuilder: (context) => _countryDialCodes.keys
          .map(
            (country) => Text(
              country,
              overflow: TextOverflow.ellipsis,
            ),
          )
          .toList(),
      items: _countryDialCodes.keys
          .map(
            (country) => DropdownMenuItem<String>(
              value: country,
              child: Text(
                country,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (country) {
        if (country == null) {
          return;
        }

        setState(() {
          _selectedCountry = country;
          _controller('phoneNumber').text = '${_countryDialCodes[country]} ';
        });
      },
    );
  }

  Widget _buildJobCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedJobCategory,
      isExpanded: true,
      dropdownColor: cardGreen,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: 'Job Category / Profession *',
        labelStyle: const TextStyle(
          color: Colors.white54,
        ),
        filled: true,
        fillColor: cardGreen,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      selectedItemBuilder: (context) => _jobCategories
          .map(
            (category) => Text(
              category,
              overflow: TextOverflow.ellipsis,
            ),
          )
          .toList(),
      items: _jobCategories
          .map(
            (category) => DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (category) {
        if (category == null) {
          return;
        }

        setState(() {
          _selectedJobCategory = category;

          if (_selectedJobCategory == 'Catering / Food Seller (Injera & Wot)' &&
              _menuItems.isEmpty) {
            _menuItems.add(
              _MenuItemInput(),
            );
          }
        });
      },
    );
  }

  List<Widget> _buildJobSpecificFields() {
    if (_selectedJobCategory == 'Translator') {
      return [
        _buildDropdown(
          label: 'Service Type *',
          value: _translatorServiceType,
          values: const [
            'In-person',
            'Phone',
          ],
          onChanged: (value) {
            setState(() {
              _translatorServiceType = value;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildField(
          'ratePerHour',
          'Rate per hour',
        ),
        const SizedBox(height: 12),
        _buildField(
          'ratePerDocument',
          'Rate per document / paper',
        ),
        const SizedBox(height: 12),
        _buildField(
          'websiteUrl',
          'Website URL (optional)',
        ),
      ];
    }

    if (_selectedJobCategory == 'Fashion/Clothes Designer') {
      return [
        _buildPhotoPicker(
          'Portfolio photos',
          _portfolioPhotos,
          5,
        ),
        const SizedBox(height: 12),
        _buildField(
          'designerSpecialty',
          'Designer specialty',
        ),
        const SizedBox(height: 12),
        _buildField(
          'orderMeasurements',
          'Order/Command Form: height, size, chest, waist, hips, sleeve, notes',
          maxLines: 5,
        ),
        const SizedBox(height: 12),
        const Text(
          'Client orders for designer clothes are cash on delivery / pay on arrival only.',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ];
    }

    if (_selectedJobCategory == 'Catering / Food Seller (Injera & Wot)') {
      return [
        _buildPhotoPicker(
          'Catering photos',
          _cateringPhotos,
          10,
        ),
        const SizedBox(height: 12),
        _buildMenuBuilder(),
        const SizedBox(height: 12),
        _buildField(
          'depositPercentage',
          'Deposit percentage (0-100, optional)',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        const Text(
          'Customers can contact you directly or request an in-app deposit. The deposit is calculated from the order total.',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ];
    }

    return [
      _buildField(
        'payRange',
        'Pay range',
      ),
      const SizedBox(height: 12),
      _buildPhotoPicker(
        'Previous work photos',
        _workPhotos,
        3,
      ),
      const SizedBox(height: 12),
      _buildField(
        'exactAddressOptional',
        'Exact address (optional)',
      ),
    ];
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    final safeValue = values.contains(value) ? value : values.first;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      dropdownColor: cardGreen,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white54,
        ),
        filled: true,
        fillColor: cardGreen,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      selectedItemBuilder: (context) => values
          .map(
            (item) => Text(
              item,
              overflow: TextOverflow.ellipsis,
            ),
          )
          .toList(),
      items: values
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (item) {
        if (item != null) {
          onChanged(item);
        }
      },
    );
  }

  Widget _buildEventTicketTypes() {
    return Column(
      children: [
        for (var index = 0; index < _eventTicketTypes.length; index++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryGold.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ticket ${index + 1}',
                        style: const TextStyle(
                          color: primaryGold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_eventTicketTypes[index].sold > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${_eventTicketTypes[index].sold} sold',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (_eventTicketTypes.length > 1 &&
                        _eventTicketTypes[index].sold == 0)
                      IconButton(
                        tooltip: 'Delete ticket type',
                        onPressed: () {
                          setState(() {
                            final ticket = _eventTicketTypes.removeAt(index);
                            ticket.dispose();
                          });
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _eventTicketTypes[index].nameController,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Ticket name *',
                    hintText: 'Standard, VIP, Early Bird...',
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                    ),
                    labelStyle: const TextStyle(
                      color: Colors.white54,
                    ),
                    filled: true,
                    fillColor: primaryDarkGreen,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _eventTicketTypes[index].priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Price (€) *',
                          hintText: '0 = Free',
                          hintStyle: const TextStyle(
                            color: Colors.white38,
                          ),
                          labelStyle: const TextStyle(
                            color: Colors.white54,
                          ),
                          prefixIcon: const Icon(
                            Icons.euro,
                            color: primaryGold,
                          ),
                          filled: true,
                          fillColor: primaryDarkGreen,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          final price = double.tryParse(
                            (value ?? '').trim().replaceAll(',', '.'),
                          );

                          if (price == null || price < 0) {
                            return 'Invalid price';
                          }

                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _eventTicketTypes[index].capacityController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Places *',
                          hintText: '100',
                          hintStyle: const TextStyle(
                            color: Colors.white38,
                          ),
                          labelStyle: const TextStyle(
                            color: Colors.white54,
                          ),
                          prefixIcon: const Icon(
                            Icons.people_outline,
                            color: primaryGold,
                          ),
                          filled: true,
                          fillColor: primaryDarkGreen,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          final capacity = int.tryParse((value ?? '').trim());

                          if (capacity == null || capacity <= 0) {
                            return 'Invalid';
                          }

                          if (capacity < _eventTicketTypes[index].sold) {
                            return 'Min ${_eventTicketTypes[index].sold}';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                if (_eventTicketTypes[index].sold > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${_eventTicketTypes[index].sold} ticket(s) already sold. '
                    'Capacity cannot be lower than this number.',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _eventTicketTypes[index].active,
                  activeThumbColor: primaryGold,
                  title: const Text(
                    'Ticket available for sale',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    _eventTicketTypes[index].active
                        ? 'Customers can purchase this ticket.'
                        : 'This ticket is currently hidden from sales.',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _eventTicketTypes[index].active = value;
                    });
                  },
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _eventTicketTypes.add(
                  _EventTicketInput(
                    id: '',
                    name: '',
                    price: 0,
                    capacity: 100,
                    sold: 0,
                  ),
                );
              });
            },
            icon: const Icon(
              Icons.add_circle_outline,
              color: primaryGold,
            ),
            label: const Text(
              'Add ticket type',
              style: TextStyle(
                color: primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: primaryGold,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventArtistsBuilder() {
    return Column(
      children: [
        for (var index = 0; index < _eventArtists.length; index++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Artist / DJ ${index + 1}',
                        style: const TextStyle(
                          color: primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_eventArtists.length > 1)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            final artist = _eventArtists.removeAt(index);
                            artist.dispose();
                          });
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _eventArtists[index].nameController,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Artist / Performer / DJ name',
                    labelStyle: const TextStyle(
                      color: Colors.white54,
                    ),
                    filled: true,
                    fillColor: primaryDarkGreen,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_eventArtists[index].photo != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(
                            _eventArtists[index].photo!.path,
                          ),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _eventArtists[index].photo = null;
                            });
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                else if ((_eventArtists[index].existingPhotoUrl ?? '')
                    .isNotEmpty)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _eventArtists[index].existingPhotoUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              height: 150,
                              width: double.infinity,
                              color: primaryDarkGreen,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white54,
                                size: 36,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _eventArtists[index].existingPhotoUrl = null;
                            });
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final photo = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                          maxWidth: 1600,
                        );

                        if (photo == null || !mounted) {
                          return;
                        }

                        setState(() {
                          _eventArtists[index].photo = photo;
                        });
                      },
                      icon: const Icon(
                        Icons.add_a_photo_outlined,
                      ),
                      label: const Text(
                        'Add artist photo',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryGold,
                        side: const BorderSide(
                          color: primaryGold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _eventArtists.add(
                  _EventArtistInput(),
                );
              });
            },
            icon: const Icon(
              Icons.person_add_alt_1,
            ),
            label: const Text(
              'Add another artist',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryGold,
              side: const BorderSide(
                color: primaryGold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventPhotoPicker() {
    final totalPhotos = _existingEventPhotoUrls.length + _eventPhotos.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event photos ($totalPhotos/5)',
            style: const TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (totalPhotos > 0)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                for (var index = 0;
                    index < _existingEventPhotoUrls.length;
                    index++)
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _existingEventPhotoUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: primaryDarkGreen,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white54,
                              ),
                            );
                          },
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          left: 5,
                          bottom: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryGold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'COVER',
                              style: TextStyle(
                                color: primaryDarkGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _existingEventPhotoUrls.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                for (var index = 0; index < _eventPhotos.length; index++)
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_eventPhotos[index].path),
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (_existingEventPhotoUrls.isEmpty && index == 0)
                        Positioned(
                          left: 5,
                          bottom: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryGold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'COVER',
                              style: TextStyle(
                                color: primaryDarkGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _eventPhotos.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          if (totalPhotos > 0) const SizedBox(height: 12),
          if (totalPhotos < 5)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final currentTotal =
                        _existingEventPhotoUrls.length + _eventPhotos.length;
                    final remaining = 5 - currentTotal;

                    if (remaining <= 0) {
                      return;
                    }

                    final picked = await _picker.pickMultiImage(
                      limit: remaining,
                      imageQuality: 85,
                      maxWidth: 1800,
                      maxHeight: 1800,
                    );

                    if (picked.isEmpty || !mounted) {
                      return;
                    }

                    setState(() {
                      _eventPhotos.addAll(
                        picked.take(remaining),
                      );
                    });
                  } catch (e) {
                    if (!mounted) {
                      return;
                    }

                    _showMessage(
                      'Could not select photos: $e',
                      isError: true,
                    );
                  }
                },
                icon: const Icon(
                  Icons.add_a_photo_outlined,
                ),
                label: Text(
                  totalPhotos == 0 ? 'Add photos' : 'Add more photos',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGold,
                  side: const BorderSide(
                    color: primaryGold,
                  ),
                ),
              ),
            ),
          if (totalPhotos >= 5)
            const Text(
              'Maximum 5 photos reached.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker(
    String label,
    List<XFile> files,
    int maxCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label (${files.length}/$maxCount)',
            style: const TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final file in files)
                Chip(
                  label: SizedBox(
                    width: 150,
                    child: Text(
                      file.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  onDeleted: () {
                    setState(() {
                      files.remove(file);
                    });
                  },
                ),
              if (files.length < maxCount)
                ActionChip(
                  avatar: const Icon(
                    Icons.add_a_photo,
                    size: 18,
                  ),
                  label: const Text('Add photo'),
                  onPressed: () async {
                    final picked = await _picker.pickMultiImage(
                      limit: maxCount - files.length,
                    );

                    if (picked.isEmpty) {
                      return;
                    }

                    setState(() {
                      files.addAll(
                        picked.take(
                          maxCount - files.length,
                        ),
                      );
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuBuilder() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dynamic Menu Builder',
                  style: TextStyle(
                    color: primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _menuItems.add(
                      _MenuItemInput(),
                    );
                  });
                },
                icon: const Icon(
                  Icons.add_circle,
                  color: primaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final item = _menuItems[index];

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInlineField(
                        'Item',
                        item.nameController,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 96,
                      child: _buildInlineField(
                        'Price',
                        item.priceController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    IconButton(
                      onPressed: _menuItems.length == 1
                          ? null
                          : () {
                              setState(() {
                                final removed = _menuItems.removeAt(index);
                                removed.dispose();
                              });
                            },
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInlineField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
        filled: true,
        fillColor: primaryDarkGreen,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _pickEventDate(String key) async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      helpText: 'Select event date',
      cancelText: 'Cancel',
      confirmText: 'Select',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: primaryGold,
              onPrimary: primaryDarkGreen,
              surface: cardGreen,
              onSurface: Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: cardGreen,
              headerBackgroundColor: primaryDarkGreen,
              headerForegroundColor: primaryGold,
              weekdayStyle: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.white30;
                  }
                  if (states.contains(WidgetState.selected)) {
                    return primaryDarkGreen;
                  }
                  return Colors.white;
                },
              ),
              dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return primaryGold;
                  }
                  return Colors.transparent;
                },
              ),
              todayForegroundColor: const WidgetStatePropertyAll(
                primaryGold,
              ),
              todayBorder: const BorderSide(
                color: primaryGold,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryGold,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final day = pickedDate.day.toString().padLeft(2, '0');
    final month = pickedDate.month.toString().padLeft(2, '0');
    final year = pickedDate.year.toString();

    setState(() {
      _controller(key).text = '$day/$month/$year';
    });
  }

  Future<void> _pickEventTime(String key) async {
    final currentText = _controller(key).text.trim();

    TimeOfDay initialTime = TimeOfDay.now();

    if (currentText.contains(':')) {
      final parts = currentText.split(':');

      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);

        if (hour != null &&
            minute != null &&
            hour >= 0 &&
            hour <= 23 &&
            minute >= 0 &&
            minute <= 59) {
          initialTime = TimeOfDay(
            hour: hour,
            minute: minute,
          );
        }
      }
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: key == 'startTime' ? 'Select start time' : 'Select end time',
      cancelText: 'Cancel',
      confirmText: 'Select',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: primaryGold,
              onPrimary: primaryDarkGreen,
              surface: cardGreen,
              onSurface: Colors.white,
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: cardGreen,
              helpTextStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              hourMinuteColor: primaryDarkGreen,
              hourMinuteTextColor: Colors.white,
              dialBackgroundColor: primaryDarkGreen,
              dialHandColor: primaryGold,
              dialTextColor: Colors.white,
              entryModeIconColor: primaryGold,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryGold,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    final hour = pickedTime.hour.toString().padLeft(2, '0');
    final minute = pickedTime.minute.toString().padLeft(2, '0');

    setState(() {
      _controller(key).text = '$hour:$minute';
    });
  }

  Widget _buildEventDateField() {
    return TextFormField(
      controller: _controller('eventDate'),
      readOnly: true,
      style: const TextStyle(
        color: Colors.white,
      ),
      onTap: () => _pickEventDate('eventDate'),
      decoration: InputDecoration(
        labelText: 'Event date *',
        hintText: 'Choose a date',
        hintStyle: const TextStyle(
          color: Colors.white38,
        ),
        labelStyle: const TextStyle(
          color: Colors.white54,
        ),
        prefixIcon: const Icon(
          Icons.calendar_month_rounded,
          color: primaryGold,
        ),
        suffixIcon: const Icon(
          Icons.arrow_drop_down,
          color: primaryGold,
        ),
        filled: true,
        fillColor: cardGreen,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Widget _buildEventTimeField({
    required String key,
    required String label,
  }) {
    return TextFormField(
      controller: _controller(key),
      readOnly: true,
      style: const TextStyle(
        color: Colors.white,
      ),
      onTap: () => _pickEventTime(key),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Choose a time',
        hintStyle: const TextStyle(
          color: Colors.white38,
        ),
        labelStyle: const TextStyle(
          color: Colors.white54,
        ),
        prefixIcon: const Icon(
          Icons.schedule_rounded,
          color: primaryGold,
        ),
        suffixIcon: const Icon(
          Icons.arrow_drop_down,
          color: primaryGold,
        ),
        filled: true,
        fillColor: cardGreen,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Widget _buildField(
    String key,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: _controller(key),
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
      ),
      validator: label.endsWith('*')
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white54,
        ),
        filled: true,
        fillColor: cardGreen,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSwitch(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: primaryGold,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}

class _EventTicketInput {
  _EventTicketInput({
    required this.id,
    required String name,
    required double price,
    required int capacity,
    required this.sold,
    this.active = true,
  })  : nameController = TextEditingController(text: name),
        priceController = TextEditingController(
          text: price == price.roundToDouble()
              ? price.toInt().toString()
              : price.toStringAsFixed(2),
        ),
        capacityController = TextEditingController(
          text: capacity.toString(),
        );

  String id;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController capacityController;

  int sold;
  bool active;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    capacityController.dispose();
  }
}

class _MenuItemInput {
  final TextEditingController nameController = TextEditingController();

  final TextEditingController priceController = TextEditingController();

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }

  Map<String, String> toMap() {
    return {
      'name': nameController.text.trim(),
      'price': priceController.text.trim(),
    };
  }
}

class _EventArtistInput {
  final TextEditingController nameController = TextEditingController();

  XFile? photo;

  // Photo déjà enregistrée dans Firebase.
  String? existingPhotoUrl;

  void dispose() {
    nameController.dispose();
  }
}
