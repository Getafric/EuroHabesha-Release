import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'admin_role_service.dart';
import 'access_control.dart';
import 'admin_qa_screen.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final _announcementFormKey = GlobalKey<FormState>();
  final _jobFormKey = GlobalKey<FormState>();
  final _businessFormKey = GlobalKey<FormState>();
  final _verifiedProfessionalFormKey = GlobalKey<FormState>();
  final TextEditingController _subAdminEmailController = TextEditingController();

  // Announcement fields
  final TextEditingController _announcementTitleController = TextEditingController();
  final TextEditingController _announcementDescController = TextEditingController();
  final TextEditingController _announcementLinkController = TextEditingController();
  String _announcementCategory = 'Promotions';
  DateTime _announcementExpiryDate = DateTime.now().add(const Duration(days: 30));
  final List<_SelectedAttachment> _announcementFiles = [];
  bool _isUploadingAnnouncement = false;

  // Job fields
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobCompanyController = TextEditingController();
  final TextEditingController _jobPriceController = TextEditingController();
  final TextEditingController _jobCityController = TextEditingController();
  final TextEditingController _jobPhoneController = TextEditingController();
  final TextEditingController _jobDescController = TextEditingController();
  final List<String> _defaultJobCategories = const [
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
  List<String> _jobCategories = const ['Business Services'];
  String _selectedJobCategory = 'Business Services';
  String _selectedJobCountry = 'France';
  String _selectedJobDialCode = '+33';
  final Map<String, String> _jobCountryDialCodes = {
    'France': '+33',
    'Switzerland': '+41',
    'Germany': '+49',
    'United Kingdom': '+44',
    'Italy': '+39',
    'Spain': '+34',
    'Netherlands': '+31',
    'Belgium': '+32',
    'Austria': '+43',
    'United States': '+1',
    'Canada': '+1',
  };

  // Business profile fields
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessCategoryController = TextEditingController();
  final TextEditingController _businessOwnerController = TextEditingController();
  final TextEditingController _businessPhoneController = TextEditingController();
  final TextEditingController _businessEmailController = TextEditingController();
  final TextEditingController _businessCityController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _businessWebsiteController = TextEditingController();
  final TextEditingController _businessDescController = TextEditingController();
  final TextEditingController _businessRateController = TextEditingController();
  String _businessType = 'Professional';
  String _selectedBusinessCountry = 'France';
  String _selectedBusinessDialCode = '+33';
  final Map<String, String> _businessCountryDialCodes = {
    'France': '+33',
    'Switzerland': '+41',
    'Germany': '+49',
    'United Kingdom': '+44',
    'Italy': '+39',
    'Spain': '+34',
    'Netherlands': '+31',
    'Belgium': '+32',
    'Austria': '+43',
    'United States': '+1',
    'Canada': '+1',
  };
  final Map<String, String> _businessCountryFlags = {
    'France': '🇫🇷',
    'Switzerland': '🇨🇭',
    'Germany': '🇩🇪',
    'United Kingdom': '🇬🇧',
    'Italy': '🇮🇹',
    'Spain': '🇪🇸',
    'Netherlands': '🇳🇱',
    'Belgium': '🇧🇪',
    'Austria': '🇦🇹',
    'United States': '🇺🇸',
    'Canada': '🇨🇦',
  };
  final List<_SelectedAttachment> _businessPhotos = [];
  bool _isPublishingBusiness = false;

  // Verified professional fields
  final TextEditingController _professionalNameController = TextEditingController();
  final TextEditingController _professionalCategoryController = TextEditingController();
  final TextEditingController _professionalCountryController = TextEditingController(text: 'France');
  final TextEditingController _professionalCityController = TextEditingController();
  final TextEditingController _professionalPhoneController = TextEditingController();
  final TextEditingController _professionalEmailController = TextEditingController();
  final TextEditingController _professionalWebsiteController = TextEditingController();
  final TextEditingController _professionalWhatsappController = TextEditingController();
  final TextEditingController _professionalBioController = TextEditingController();
  final TextEditingController _professionalImageUrlController = TextEditingController();
  final TextEditingController _professionalUserIdController = TextEditingController();
  final TextEditingController _messageBypassUidController = TextEditingController();
  String _professionalVerificationStage = 'professional';
  bool _professionalVerified = true;
  bool _isPublishingProfessional = false;
  bool _isBackfillingLegacyListings = false;
  bool _isLinkingLegacyListings = false;
  bool _isUpdatingMessageBypass = false;

  bool _isCheckingAccess = true;
  bool _isOwner = false;

  _RateRange? _parseRateRange(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return null;

    final normalized = input
        .toLowerCase()
        .replaceAll('eur', '')
        .replaceAll('€', '')
        .replaceAll('/hr', '')
        .replaceAll('per hour', '')
        .replaceAll('to', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final parts = normalized.split('-').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return null;

    final first = double.tryParse(parts.first.replaceAll(',', '.'));
    if (first == null || first < 0) return null;

    if (parts.length == 1) {
      return _RateRange(min: first, max: first);
    }

    final second = double.tryParse(parts[1].replaceAll(',', '.'));
    if (second == null || second < 0) return null;

    final min = first <= second ? first : second;
    final max = first <= second ? second : first;
    return _RateRange(min: min, max: max);
  }

  @override
  void initState() {
    super.initState();
    _selectedBusinessDialCode = _businessCountryDialCodes[_selectedBusinessCountry] ?? '+33';
    _selectedJobDialCode = _jobCountryDialCodes[_selectedJobCountry] ?? '+33';
    _jobCategories = [..._defaultJobCategories];
    _selectedJobCategory = _jobCategories.first;
    _loadAdminJobCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminAccess();
    });
  }

  Future<void> _loadAdminJobCategories() async {
    try {
      final jobsSnap = await FirebaseFirestore.instance.collection('jobs').limit(200).get();
      final submissionsSnap = await FirebaseFirestore.instance.collection('job_submissions').limit(200).get();

      final merged = <String>{..._defaultJobCategories};
      for (final doc in jobsSnap.docs) {
        final category = (doc.data()['category'] ?? '').toString().trim();
        if (category.isNotEmpty) merged.add(category);
      }
      for (final doc in submissionsSnap.docs) {
        final category = (doc.data()['category'] ?? '').toString().trim();
        if (category.isNotEmpty) merged.add(category);
      }

      final ordered = merged.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _jobCategories = ordered;
        if (!_jobCategories.contains(_selectedJobCategory)) {
          _selectedJobCategory = _jobCategories.isEmpty ? 'Business Services' : _jobCategories.first;
        }
      });
    } catch (_) {
      // Keep default categories available even if category preload fails.
    }
  }

  void _handleBusinessCountryChange(String? value) {
    if (value == null) return;
    setState(() {
      _selectedBusinessCountry = value;
      _selectedBusinessDialCode = _businessCountryDialCodes[value] ?? '+33';
    });
  }

  void _handleJobCountryChange(String? value) {
    if (value == null) return;
    setState(() {
      _selectedJobCountry = value;
      _selectedJobDialCode = _jobCountryDialCodes[value] ?? '+33';
    });
  }

  Future<void> _checkAdminAccess() async {
    final allowed = await AccessControl.ensureAdminAccess(
      context,
      actionLabel: 'Open Admin Panel',
    );
    if (!mounted) return;
    if (!allowed) {
      Navigator.of(context).pop();
      return;
    }

    final owner = await AccessControl.isCurrentUserOwner();
    if (!mounted) return;
    setState(() {
      _isOwner = owner;
      _isCheckingAccess = false;
    });
  }

  Future<void> _submitAnnouncement() async {
    if (!_announcementFormKey.currentState!.validate()) return;
    if (_isUploadingAnnouncement) return;

    final link = _announcementLinkController.text.trim();
    if (link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      final valid = uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('External link must start with http:// or https://')),
        );
        return;
      }
    }

    setState(() {
      _isUploadingAnnouncement = true;
    });

    List<Map<String, String>> attachments = [];
    try {
      attachments = await _uploadAnnouncementFiles();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isUploadingAnnouncement = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attachment upload failed: $error')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': _announcementTitleController.text.trim(),
        'body': _announcementDescController.text.trim(),
        'category': _announcementCategory,
        'type': 'event_alert',
        'attachments': attachments,
        'externalLink': link,
        'expiryDate': Timestamp.fromDate(
          DateTime(
            _announcementExpiryDate.year,
            _announcementExpiryDate.month,
            _announcementExpiryDate.day,
            23,
            59,
            59,
          ),
        ),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _isUploadingAnnouncement = false;
      });
      final msg = switch (error.code) {
        'permission-denied' => 'Posting blocked by Firestore rules. Please check admin write permissions.',
        'unavailable' => 'Network unavailable. Please check your internet and try again.',
        _ => error.message ?? error.code,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement save failed: $msg')),
      );
      return;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isUploadingAnnouncement = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement save failed: $error')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isUploadingAnnouncement = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Announcement saved. Push notifications will be sent to users.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
    _announcementTitleController.clear();
    _announcementDescController.clear();
    _announcementLinkController.clear();
    setState(() {
      _announcementFiles.clear();
      _announcementCategory = 'Promotions';
      _announcementExpiryDate = DateTime.now().add(const Duration(days: 30));
    });
  }

  Future<void> _pickAnnouncementFiles() async {
    final pickedFiles = await openFiles();
    if (pickedFiles.isEmpty) return;

    final selected = <_SelectedAttachment>[];
    for (final file in pickedFiles) {
      final path = file.path;
      Uint8List? bytes;
      int size = 0;

      if (kIsWeb) {
        bytes = await file.readAsBytes();
        size = bytes.lengthInBytes;
      } else {
        if (path.isNotEmpty) {
          final ioFile = File(path);
          if (await ioFile.exists()) {
            size = await ioFile.length();
          }
        }
      }

      selected.add(
        _SelectedAttachment(
          name: file.name,
          path: path.isEmpty ? null : path,
          bytes: bytes,
          size: size,
        ),
      );
    }

    _addAnnouncementFiles(selected);
  }

  void _addAnnouncementFiles(List<_SelectedAttachment> files) {
    setState(() {
      for (final file in files) {
        final duplicate = _announcementFiles.any((existing) =>
            existing.name == file.name &&
            existing.size == file.size &&
            (existing.path ?? '') == (file.path ?? ''));
        if (!duplicate) {
          _announcementFiles.add(file);
        }
      }
    });
  }

  Future<List<Map<String, String>>> _uploadAnnouncementFiles() async {
    return _uploadFilesToFolder(_announcementFiles, 'announcements');
  }

  Future<List<Map<String, String>>> _uploadFilesToFolder(
    List<_SelectedAttachment> files,
    String folder,
  ) async {
    if (files.isEmpty) return const [];

    final uploaded = <Map<String, String>>[];
    for (final file in files) {
      final fileName = file.name.replaceAll(' ', '_');
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final resolvedFolder = folder == 'business_profiles' && uid.isNotEmpty
          ? 'profileMedia/$uid/business_profiles'
          : folder;
      final ref = FirebaseStorage.instance.ref('$resolvedFolder/$stamp-$fileName');

      UploadTask task;
      if (kIsWeb || file.bytes != null) {
        final bytes = file.bytes;
        if (bytes == null) {
          throw Exception('Missing file bytes for ${file.name}.');
        }
        task = ref.putData(bytes);
      } else {
        final path = file.path;
        if (path == null || path.isEmpty) {
          throw Exception('Missing file path for ${file.name}.');
        }
        task = ref.putFile(File(path));
      }

      await task;
      final url = await ref.getDownloadURL();
      uploaded.add({'name': file.name, 'url': url});
    }

    return uploaded;
  }

  Future<void> _pickBusinessPhotos() async {
    final pickedFiles = await openFiles();
    if (pickedFiles.isEmpty) return;

    final selected = <_SelectedAttachment>[];
    for (final file in pickedFiles) {
      final path = file.path;
      Uint8List? bytes;
      int size = 0;

      if (kIsWeb) {
        bytes = await file.readAsBytes();
        size = bytes.lengthInBytes;
      } else {
        if (path.isNotEmpty) {
          final ioFile = File(path);
          if (await ioFile.exists()) {
            size = await ioFile.length();
          }
        }
      }

      selected.add(
        _SelectedAttachment(
          name: file.name,
          path: path.isEmpty ? null : path,
          bytes: bytes,
          size: size,
        ),
      );
    }

    setState(() {
      for (final file in selected) {
        final duplicate = _businessPhotos.any(
          (existing) =>
              existing.name == file.name &&
              existing.size == file.size &&
              (existing.path ?? '') == (file.path ?? ''),
        );
        if (!duplicate) {
          _businessPhotos.add(file);
        }
      }
    });
  }

  Future<void> _publishBusinessProfile() async {
    if (!_businessFormKey.currentState!.validate()) return;
    if (_isPublishingBusiness) return;

    final website = _businessWebsiteController.text.trim();
    if (website.isNotEmpty) {
      final uri = Uri.tryParse(website);
      final valid = uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Website must start with http:// or https://')),
        );
        return;
      }
    }

    setState(() {
      _isPublishingBusiness = true;
    });

    List<Map<String, String>> photoAssets = [];
    try {
      photoAssets = await _uploadFilesToFolder(_businessPhotos, 'business_profiles');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isPublishingBusiness = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo upload failed: $error')),
      );
      return;
    }

    final name = _businessNameController.text.trim();
    final category = _businessCategoryController.text.trim();
    final owner = _businessOwnerController.text.trim();
    final localPhone = _businessPhoneController.text.trim();
    final phone = '$_selectedBusinessDialCode $localPhone'.trim();
    final email = _businessEmailController.text.trim();
    final country = _selectedBusinessCountry;
    final city = _businessCityController.text.trim();
    final address = _businessAddressController.text.trim();
    final description = _businessDescController.text.trim();
    final parsedRate = _parseRateRange(_businessRateController.text.trim());
    final rateMin = parsedRate?.min ?? 0.0;
    final rateMax = parsedRate?.max ?? 0.0;
    final rateText = parsedRate == null
      ? ''
      : (rateMin == rateMax
        ? 'EUR ${rateMin.toStringAsFixed(0)}'
        : 'EUR ${rateMin.toStringAsFixed(0)}-${rateMax.toStringAsFixed(0)}');
    final photoUrls = photoAssets.map((e) => e['url'] ?? '').where((e) => e.isNotEmpty).toList();

    try {
      final profileRef = FirebaseFirestore.instance.collection('business_profiles').doc();
      final jobsRef = FirebaseFirestore.instance.collection('jobs').doc();
      final batch = FirebaseFirestore.instance.batch();

      batch.set(profileRef, {
        'name': name,
        'businessType': _businessType,
        'category': category,
        'ownerName': owner,
        'phone': phone,
        'email': email,
        'country': country,
        'city': city,
        'address': address,
        'website': website,
        'description': description,
        'serviceRate': rateMin,
        'serviceRateMin': rateMin,
        'serviceRateMax': rateMax,
        'serviceRateText': rateText,
        'photos': photoAssets,
        'photoUrls': photoUrls,
        'verified': true,
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
      });

      batch.set(jobsRef, {
        'title': '$name - $category',
        'authorName': owner.isEmpty ? name : owner,
        'category': category,
        'country': country,
        'city': city,
        'price': rateMin,
        'priceMin': rateMin,
        'priceMax': rateMax,
        'priceText': rateText,
        'phone': phone,
        'description': description,
        'authorPhone': phone,
        'verified': true,
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': photoUrls.isEmpty ? '' : photoUrls.first,
        'businessType': _businessType,
        'source': 'admin_business_profile',
        'sourceProfileId': profileRef.id,
      });

      await batch.commit();
      await _publishListingToHomeFeed(
        title: '$name - $category',
        category: 'Business',
        city: city,
        description: description,
        providerName: owner.isEmpty ? name : owner,
        phone: phone,
        email: email,
        website: website,
        sourceCollection: 'business_profiles',
        sourceId: profileRef.id,
        imageUrl: photoUrls.isEmpty ? '' : photoUrls.first,
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _isPublishingBusiness = false;
      });
      String msg;
      if (error.code == 'permission-denied') {
        final diag = await AccessControl.diagnoseCurrentUserAdminAccess();
        if (!mounted) return;
        msg = 'Business publishing blocked by Firestore rules. '
            'Admin diagnostics: granted=${diag.granted}, byRoleDoc=${diag.byRoleDoc}, '
            'byUserRole=${diag.byUserRole}, roleDoc=${diag.roleDocId.isEmpty ? 'none' : diag.roleDocId}, '
            'role=${diag.roleDocRole.isEmpty ? 'none' : diag.roleDocRole}, active=${diag.roleDocActive}.';
      } else if (error.code == 'unavailable') {
        msg = 'Network unavailable. Please try again.';
      } else {
        msg = error.message ?? error.code;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publish failed: $msg')),
      );
      return;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isPublishingBusiness = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publish failed: $error')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isPublishingBusiness = false;
      _businessType = 'Professional';
      _businessPhotos.clear();
    });
    _businessNameController.clear();
    _businessCategoryController.clear();
    _businessOwnerController.clear();
    _businessPhoneController.clear();
    _businessEmailController.clear();
    _businessCityController.clear();
    _businessAddressController.clear();
    _businessWebsiteController.clear();
    _businessDescController.clear();
    _businessRateController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Business profile published and added to listings.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  Future<void> _publishListingToHomeFeed({
    required String title,
    required String category,
    required String city,
    required String description,
    String providerName = '',
    String phone = '',
    String email = '',
    String website = '',
    String userId = '',
    String sourceCollection = '',
    String sourceId = '',
    String imageUrl = '',
  }) async {
    await FirebaseFirestore.instance.collection('announcements').add({
      'title': title,
      'body': description,
      'category': category,
      'city': city,
      'type': 'listing',
      'providerName': providerName,
      'phone': phone,
      'email': email,
      'website': website,
      'userId': userId,
      'sourceCollection': sourceCollection,
      'sourceId': sourceId,
      'imageUrl': imageUrl,
      'active': true,
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 90))),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': 'admin',
    });
  }

  Future<void> _notifyUser({
    required String uid,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? payload,
  }) async {
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(trimmedUid)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'type': type,
      'payload': payload ?? const <String, dynamic>{},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': 'admin',
    });
  }

  Future<void> _submitJob() async {
    if (!_jobFormKey.currentState!.validate()) return;

    final title = _jobTitleController.text.trim();
    final company = _jobCompanyController.text.trim();
    final category = _selectedJobCategory.trim().isEmpty ? 'Business Services' : _selectedJobCategory.trim();
    final country = _selectedJobCountry.trim();
    final localPhone = _jobPhoneController.text.trim();
    final phone = localPhone.isEmpty ? '' : '$_selectedJobDialCode $localPhone';
    final city = _jobCityController.text.trim();
    final description = _jobDescController.text.trim();
    final hourlyRate = double.tryParse(_jobPriceController.text.trim().replaceAll(',', '.')) ?? 0.0;

    try {
      await FirebaseFirestore.instance.collection('jobs').add({
        'title': title,
        'authorName': company,
        'category': category,
        'country': country,
        'city': city,
        'price': hourlyRate,
        'hourlyRate': hourlyRate,
        'phone': phone,
        'description': description,
        'authorPhone': phone,
        'verified': true,
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'admin_featured_job',
      });

      await _publishListingToHomeFeed(
        title: title,
        category: category,
        city: city,
        description: description,
        providerName: company,
        phone: phone,
        sourceCollection: 'jobs',
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      String msg;
      if (error.code == 'permission-denied') {
        final diag = await AccessControl.diagnoseCurrentUserAdminAccess();
        if (!mounted) return;
        msg = 'Posting blocked by Firestore rules. '
            'Admin diagnostics: granted=${diag.granted}, byClaim=${diag.byClaim}, '
            'byRoleDoc=${diag.byRoleDoc}, byUserRole=${diag.byUserRole}, '
            'roleDoc=${diag.roleDocId.isEmpty ? 'none' : diag.roleDocId}, '
            'role=${diag.roleDocRole.isEmpty ? 'none' : diag.roleDocRole}, '
            'active=${diag.roleDocActive}, userRole=${diag.userRole.isEmpty ? 'none' : diag.userRole}.';
      } else if (error.code == 'unavailable') {
        msg = 'Network unavailable. Please try again.';
      } else {
        msg = error.message ?? error.code;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to publish job: $msg')));
      return;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to publish job: $error')));
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Featured Job Listing live on Job Board & Home Feed.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
    _jobTitleController.clear();
    _jobCompanyController.clear();
    _jobPriceController.clear();
    _jobCityController.clear();
    _jobPhoneController.clear();
    _jobDescController.clear();
  }

  Future<void> _updateAssociationVerification({
    required String associationId,
    required bool approve,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    await FirebaseFirestore.instance.collection('associations').doc(associationId).set({
      'verificationStatus': approve ? 'verified' : 'rejected',
      'verifiedTick': approve,
      'reviewedAt': FieldValue.serverTimestamp(),
      'verificationNotice': approve
          ? 'Association verified by admin. Blue verified tick is active.'
          : 'Verification rejected. Please resubmit valid documents.',
    }, SetOptions(merge: true));

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          approve
              ? 'Association approved. Blue verified tick is now active.'
              : 'Association verification rejected.',
        ),
      ),
    );
  }

  Future<void> _approvePendingSubmission({
    required String submissionId,
    required Map<String, dynamic> data,
  }) async {
    final title = (data['title'] ?? 'Job listing').toString();
    final providerName = (data['providerName'] ?? '').toString();
    final category = (data['category'] ?? '').toString();
    final listingType = (data['listingType'] ?? '').toString();
    final country = (data['country'] ?? '').toString();
    final city = (data['city'] ?? '').toString();
    final phone = (data['phone'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final website = (data['website'] ?? '').toString();
    final governmentRegistrationNumber = (data['governmentRegistrationNumber'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final price = (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0;
    final userId = (data['userId'] ?? '').toString();

    final batch = FirebaseFirestore.instance.batch();
    final jobsRef = FirebaseFirestore.instance.collection('jobs').doc();
    final submissionsRef = FirebaseFirestore.instance.collection('job_submissions').doc(submissionId);

    batch.set(jobsRef, {
      'title': title,
      'authorName': providerName,
      'category': category,
      'listingType': listingType,
      'country': country,
      'city': city,
      'price': price,
      'phone': phone,
      'email': email,
      'website': website,
      'governmentRegistrationNumber': governmentRegistrationNumber,
      'description': description,
      'authorPhone': phone,
      'userId': userId,
      'verified': true,
      'status': 'approved',
      'createdAt': FieldValue.serverTimestamp(),
      'sourceSubmissionId': submissionId,
    });

    batch.update(submissionsRef, {
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    final approvedTitle = title.isEmpty ? 'Your listing' : title;
    await _notifyUser(
      uid: userId,
      title: 'Listing Approved',
      body: 'Your listing "$approvedTitle" has been approved and is now live.',
      type: 'approval',
      payload: {
        'submissionId': submissionId,
        'status': 'approved',
      },
    );

    await _publishListingToHomeFeed(
      title: title,
      category: category,
      city: city,
      description: description,
      providerName: providerName,
      phone: phone,
      email: email,
      website: website,
      userId: userId,
      sourceCollection: 'jobs',
      sourceId: jobsRef.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submission approved and published live.')),
    );
  }

  Future<void> _rejectPendingSubmission(String submissionId) async {
    final submissionDoc = await FirebaseFirestore.instance.collection('job_submissions').doc(submissionId).get();
    final data = submissionDoc.data() ?? const <String, dynamic>{};
    final userId = (data['userId'] ?? '').toString().trim();
    final title = (data['title'] ?? 'Your listing').toString();

    await FirebaseFirestore.instance.collection('job_submissions').doc(submissionId).set({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _notifyUser(
      uid: userId,
      title: 'Listing Update',
      body: 'Your listing "$title" was reviewed and not approved. Please edit and submit again.',
      type: 'rejection',
      payload: {
        'submissionId': submissionId,
        'status': 'rejected',
      },
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submission rejected.')),
    );
  }

  Future<void> _showAssociationDocumentDialog({
    required String legalName,
    required String documentName,
    required String documentDownloadUrl,
    required String documentImageBase64,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0E2E1E),
          title: Text(
            'Document Review: $legalName',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 360,
            child: documentDownloadUrl.trim().isNotEmpty
                ? InteractiveViewer(
                    child: Image.network(
                      documentDownloadUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'Unable to load document from URL.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                : documentImageBase64.trim().isEmpty
                    ? const Text('No document image uploaded.', style: TextStyle(color: Colors.white70))
                    : InteractiveViewer(
                        child: Image.memory(base64Decode(documentImageBase64), fit: BoxFit.contain),
                      ),
          ),
          actions: [
            Text(documentName, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _publishVerifiedProfessional() async {
    if (!_verifiedProfessionalFormKey.currentState!.validate()) return;
    if (_isPublishingProfessional) return;

    final website = _professionalWebsiteController.text.trim();
    if (website.isNotEmpty) {
      final uri = Uri.tryParse(website);
      final valid = uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Website must start with http:// or https://')),
        );
        return;
      }
    }

    setState(() {
      _isPublishingProfessional = true;
    });

    try {
      await FirebaseFirestore.instance.collection('verified_professionals').add({
        'name': _professionalNameController.text.trim(),
        'category': _professionalCategoryController.text.trim(),
        'country': _professionalCountryController.text.trim(),
        'city': _professionalCityController.text.trim(),
        'phone': _professionalPhoneController.text.trim(),
        'email': _professionalEmailController.text.trim(),
        'website': website,
        'whatsapp': _professionalWhatsappController.text.trim(),
        'bio': _professionalBioController.text.trim(),
        'imageUrl': _professionalImageUrlController.text.trim(),
        'userId': _professionalUserIdController.text.trim(),
        'verificationStage': _professionalVerificationStage,
        'isVerified': _professionalVerified,
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
      });

      if (!mounted) return;
      setState(() {
        _isPublishingProfessional = false;
      });
      _professionalNameController.clear();
      _professionalCategoryController.clear();
      _professionalCountryController.text = 'France';
      _professionalCityController.clear();
      _professionalPhoneController.clear();
      _professionalEmailController.clear();
      _professionalWebsiteController.clear();
      _professionalWhatsappController.clear();
      _professionalBioController.clear();
      _professionalImageUrlController.clear();
      _professionalUserIdController.clear();
      setState(() {
        _professionalVerificationStage = 'professional';
        _professionalVerified = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verified professional published successfully.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _isPublishingProfessional = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish professional: ${error.message ?? error.code}')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isPublishingProfessional = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish professional: $error')),
      );
    }
  }

  String _primaryPostTitle(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    if (title.isNotEmpty) return title;
    final name = (data['name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    final category = (data['category'] ?? '').toString().trim();
    return category.isNotEmpty ? category : 'Untitled';
  }

  String _secondaryPostLine(Map<String, dynamic> data) {
    final category = (data['category'] ?? '').toString().trim();
    final city = (data['city'] ?? '').toString().trim();
    final status = (data['status'] ?? '').toString().trim();
    final parts = <String>[];
    if (category.isNotEmpty) parts.add(category);
    if (city.isNotEmpty) parts.add(city);
    if (status.isNotEmpty) parts.add(status);
    return parts.join(' • ');
  }

  List<String> _editableFieldsForCollection(String collectionName, Map<String, dynamic> data) {
    final base = <String>['status'];
    switch (collectionName) {
      case 'announcements':
        return [...base, 'title', 'body', 'category', 'city', 'externalLink'];
      case 'jobs':
        return [...base, 'title', 'authorName', 'category', 'country', 'city', 'price', 'phone', 'email', 'website', 'description'];
      case 'business_profiles':
        return [...base, 'name', 'ownerName', 'businessType', 'category', 'country', 'city', 'phone', 'email', 'website', 'serviceRate', 'description'];
      case 'market_items':
        return [...base, 'title', 'authorName', 'category', 'country', 'city', 'price', 'phone', 'description'];
      case 'verified_professionals':
        return [...base, 'name', 'category', 'country', 'city', 'phone', 'email', 'website', 'whatsapp', 'bio', 'imageUrl', 'verificationStage'];
      default:
        final dynamicKeys = data.keys.where((key) {
          final value = data[key];
          return value is String || value is num || value is bool;
        }).toList();
        return dynamicKeys;
    }
  }

  Future<void> _showEditPostDialog({
    required String collectionName,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final fields = _editableFieldsForCollection(collectionName, data);
    final controllers = <String, TextEditingController>{
      for (final field in fields) field: TextEditingController(text: (data[field] ?? '').toString()),
    };

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0E2E1E),
          title: Text('Edit $collectionName', style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                children: fields
                    .map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: controllers[field],
                          style: const TextStyle(color: Colors.white),
                          maxLines: field == 'body' || field == 'description' || field == 'bio' ? 4 : 1,
                          decoration: _buildInputDecoration(field),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF061E12),
              ),
              onPressed: () {
                final payload = <String, dynamic>{};
                for (final field in fields) {
                  final raw = controllers[field]!.text.trim();
                  if (field == 'price' || field == 'serviceRate') {
                    payload[field] = double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
                  } else if (field == 'isVerified' || field == 'verified') {
                    payload[field] = raw.toLowerCase() == 'true';
                  } else {
                    payload[field] = raw;
                  }
                }
                payload['updatedAt'] = FieldValue.serverTimestamp();
                Navigator.of(dialogContext).pop(payload);
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );

    for (final controller in controllers.values) {
      controller.dispose();
    }

    if (result == null) return;
    try {
      await FirebaseFirestore.instance.collection(collectionName).doc(docId).set(result, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${error.message ?? error.code}')),
      );
    }
  }

  Future<void> _confirmDeletePost({
    required String collectionName,
    required String docId,
    required String title,
  }) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0E2E1E),
          title: const Text('Delete Post', style: TextStyle(color: Colors.white)),
          content: Text(
            'Delete "$title" from $collectionName? This cannot be undone.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (approved != true) return;
    try {
      await FirebaseFirestore.instance.collection(collectionName).doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: ${error.message ?? error.code}')),
      );
    }
  }

  Widget _buildManageCollectionSection({
    required String title,
    required String collectionName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(collectionName)
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
              );
            }

            if (snapshot.hasError) {
              return Text(
                'Unable to load $collectionName: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Text(
                'No records in $collectionName.',
                style: const TextStyle(color: Colors.white54),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final itemTitle = _primaryPostTitle(data);
                final subtitle = _secondaryPostLine(data);

                return Card(
                  color: const Color(0xFF0E2E1E),
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  child: ListTile(
                    title: Text(itemTitle, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    subtitle: subtitle.isEmpty
                        ? null
                        : Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFFF59E0B), size: 20),
                          onPressed: () => _showEditPostDialog(
                            collectionName: collectionName,
                            docId: doc.id,
                            data: data,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => _confirmDeletePost(
                            collectionName: collectionName,
                            docId: doc.id,
                            title: itemTitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _pad2(int value) => value.toString().padLeft(2, '0');

  String _formatDateTimeField(dynamic value) {
    if (value is Timestamp) {
      final dt = value.toDate().toLocal();
      return '${dt.year}-${_pad2(dt.month)}-${_pad2(dt.day)} ${_pad2(dt.hour)}:${_pad2(dt.minute)}';
    }
    return 'N/A';
  }

  DateTime _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Widget _buildMessageQuotaMonitorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Direct Message Credits Monitor',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tracks free quota usage (10 free) and purchased message credits by user.',
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('message_quota')
              .limit(200)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
              );
            }

            if (snapshot.hasError) {
              return Text(
                'Unable to load message quota data: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              );
            }

            final docs = [...(snapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[])];
            docs.sort((a, b) {
              final aDt = _timestampToDate(a.data()['updatedAt']);
              final bDt = _timestampToDate(b.data()['updatedAt']);
              return bDt.compareTo(aDt);
            });

            if (docs.isEmpty) {
              return const Text(
                'No message quota records yet.',
                style: TextStyle(color: Colors.white54),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final freeUsed = (data['freeUsed'] is num) ? (data['freeUsed'] as num).toInt() : 0;
                final purchasedCredits = (data['purchasedCredits'] is num) ? (data['purchasedCredits'] as num).toInt() : 0;
                final freeRemaining = (10 - freeUsed).clamp(0, 10);
                final totalRemaining = freeRemaining + purchasedCredits;
                final updatedAt = _formatDateTimeField(data['updatedAt']);

                return Card(
                  color: const Color(0xFF0E2E1E),
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  child: ListTile(
                    title: Text(
                      'User: ${doc.id}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Remaining: $totalRemaining  |  Free used: $freeUsed/10  |  Purchased left: $purchasedCredits\nUpdated: $updatedAt',
                      style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3),
                    ),
                    isThreeLine: true,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _setMessageBypassForUid({required bool enabled}) async {
    final uid = _messageBypassUidController.text.trim();
    if (uid.isEmpty || _isUpdatingMessageBypass) return;

    setState(() {
      _isUpdatingMessageBypass = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'messageCreditBypass': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(enabled ? 'Message bypass enabled for $uid.' : 'Message bypass disabled for $uid.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update bypass: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingMessageBypass = false;
        });
      }
    }
  }

  Widget _buildMessageBypassControlSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Message Bypass Controls',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Temporarily bypass message credits for a specific user UID.',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageBypassUidController,
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration('Target user UID'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                  ),
                  onPressed: _isUpdatingMessageBypass ? null : () => _setMessageBypassForUid(enabled: true),
                  icon: const Icon(Icons.verified_user_outlined, size: 16),
                  label: const Text('Enable Bypass'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  onPressed: _isUpdatingMessageBypass ? null : () => _setMessageBypassForUid(enabled: false),
                  icon: const Icon(Icons.block_outlined, size: 16),
                  label: const Text('Disable Bypass'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _firstNonEmptyValue(List<dynamic> values) {
    for (final value in values) {
      final text = value == null ? '' : value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  Map<String, dynamic> _listingPatchFromSource(Map<String, dynamic> source, {required String sourceCollection, required String sourceId}) {
    final title = _firstNonEmptyValue([source['title'], source['name']]);
    final providerName = _firstNonEmptyValue([
      source['providerName'],
      source['authorName'],
      source['ownerName'],
      source['name'],
      title,
    ]);

    String imageUrl = _firstNonEmptyValue([source['imageUrl'], source['photoUrl']]);
    final photoUrls = source['photoUrls'];
    if (imageUrl.isEmpty && photoUrls is List && photoUrls.isNotEmpty) {
      imageUrl = _firstNonEmptyValue([photoUrls.first]);
    }

    return {
      'providerName': providerName,
      'phone': _firstNonEmptyValue([source['phone'], source['authorPhone']]),
      'email': _firstNonEmptyValue([source['email'], source['businessEmail'], source['contactEmail']]),
      'website': _firstNonEmptyValue([source['website'], source['businessWebsite'], source['webSite']]),
      'userId': _firstNonEmptyValue([
        source['userId'],
        source['providerUid'],
        source['ownerUid'],
        source['authorUid'],
        source['submittedByUid'],
        source['uid'],
      ]),
      'sourceCollection': sourceCollection,
      'sourceId': sourceId,
      'imageUrl': imageUrl,
      'city': _firstNonEmptyValue([source['city']]),
      'category': _firstNonEmptyValue([source['category']]),
      'title': title,
      'body': _firstNonEmptyValue([source['description'], source['body']]),
    };
  }

  Future<String> _lookupUidByEmail(String email) async {
    final raw = email.trim();
    final normalized = raw.toLowerCase();
    if (normalized.isEmpty) return '';

    Future<String> lookupByField(String field, String value) async {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where(field, isEqualTo: value)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return '';
      return snap.docs.first.id.trim();
    }

    final byEmailNormalized = await lookupByField('email', normalized);
    if (byEmailNormalized.isNotEmpty) return byEmailNormalized;

    final byEmailRaw = raw == normalized ? '' : await lookupByField('email', raw);
    if (byEmailRaw.isNotEmpty) return byEmailRaw;

    final byContactNormalized = await lookupByField('contact', normalized);
    if (byContactNormalized.isNotEmpty) return byContactNormalized;

    final byContactRaw = raw == normalized ? '' : await lookupByField('contact', raw);
    if (byContactRaw.isNotEmpty) return byContactRaw;

    return '';
  }

  Future<_LegacyLinkResolution> _resolveLegacyListingLink(Map<String, dynamic> data) async {
    var resolvedUid = '';
    var resolvedBy = 'unknown';
    var sourceCollection = (data['sourceCollection'] ?? '').toString().trim();
    var sourceId = (data['sourceId'] ?? '').toString().trim();

    final found = await _findSourceForLegacyListing(data);
    if (found != null) {
      resolvedUid = (found['userId'] ?? '').toString().trim();
      if (resolvedUid.isNotEmpty) {
        resolvedBy = 'source';
      }
      if (sourceCollection.isEmpty) {
        sourceCollection = (found['sourceCollection'] ?? '').toString().trim();
      }
      if (sourceId.isEmpty) {
        sourceId = (found['sourceId'] ?? '').toString().trim();
      }
    }

    if (resolvedUid.isEmpty) {
      final email = _firstNonEmptyValue([
        data['email'],
        found?['email'],
        data['contactEmail'],
        data['businessEmail'],
      ]).toLowerCase();

      if (email.isNotEmpty) {
        resolvedUid = await _lookupUidByEmail(email);
        if (resolvedUid.isNotEmpty) {
          resolvedBy = 'email';
        }
      }
    }

    return _LegacyLinkResolution(
      userId: resolvedUid,
      resolvedBy: resolvedBy,
      sourceCollection: sourceCollection,
      sourceId: sourceId,
    );
  }

  Future<_LegacyAccountLinkPreview> _buildLegacyAccountLinkPreview() async {
    var scanned = 0;
    var needsLink = 0;
    var resolvable = 0;
    var bySource = 0;
    var byEmail = 0;
    final unresolvedSamples = <String>[];
    final unresolvedDetails = <_LegacyUnresolvedItem>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;

    while (true) {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('announcements')
          .where('type', isEqualTo: 'listing')
          .orderBy('createdAt', descending: true)
          .limit(200);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final page = await query.get();
      if (page.docs.isEmpty) break;

      for (final doc in page.docs) {
        scanned += 1;
        final data = doc.data();
        final existingUid = (data['userId'] ?? '').toString().trim();
        if (existingUid.isNotEmpty) continue;

        needsLink += 1;
        final resolved = await _resolveLegacyListingLink(data);
        if (resolved.userId.isNotEmpty) {
          resolvable += 1;
          if (resolved.resolvedBy == 'source') {
            bySource += 1;
          } else if (resolved.resolvedBy == 'email') {
            byEmail += 1;
          }
        } else if (unresolvedSamples.length < 5) {
          final sampleTitle = _firstNonEmptyValue([data['title'], data['providerName'], data['category'], doc.id]);
          unresolvedSamples.add(sampleTitle);
          unresolvedDetails.add(
            _LegacyUnresolvedItem(
              docId: doc.id,
              title: _firstNonEmptyValue([data['title'], data['providerName'], data['category'], 'Untitled']),
              category: _firstNonEmptyValue([data['category']]),
            ),
          );
        }
      }

      cursor = page.docs.last;
      if (page.docs.length < 200) break;
    }

    return _LegacyAccountLinkPreview(
      scanned: scanned,
      needsLink: needsLink,
      resolvable: resolvable,
      bySource: bySource,
      byEmail: byEmail,
      unresolvedSamples: unresolvedSamples,
      unresolvedDetails: unresolvedDetails,
    );
  }

  Future<void> _showAccountLinkPreviewDialog() async {
    if (_isLinkingLegacyListings || _isBackfillingLegacyListings) return;

    final shouldRun = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<_LegacyAccountLinkPreview>(
          future: _buildLegacyAccountLinkPreview(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                backgroundColor: Color(0xFF0E2E1E),
                title: Text('Account Link Preview', style: TextStyle(color: Colors.white)),
                content: SizedBox(
                  height: 84,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFF59E0B)),
                        SizedBox(height: 12),
                        Text('Analyzing listing account links...', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                backgroundColor: const Color(0xFF0E2E1E),
                title: const Text('Account Link Preview Failed', style: TextStyle(color: Colors.white)),
                content: Text(
                  'Could not compute preview: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            final preview = snapshot.data
                ?? const _LegacyAccountLinkPreview(
                  scanned: 0,
                  needsLink: 0,
                  resolvable: 0,
                  bySource: 0,
                  byEmail: 0,
                  unresolvedSamples: [],
                  unresolvedDetails: [],
                );

            return AlertDialog(
              backgroundColor: const Color(0xFF0E2E1E),
              title: const Text('Account Link Preview', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Scanned listing posts: ${preview.scanned}', style: const TextStyle(color: Colors.white70)),
                    Text('Missing userId and needs linking: ${preview.needsLink}', style: const TextStyle(color: Colors.white70)),
                    Text('Resolvable now: ${preview.resolvable}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
                    Text('By source metadata: ${preview.bySource}', style: const TextStyle(color: Colors.white70)),
                    Text('By email lookup: ${preview.byEmail}', style: const TextStyle(color: Colors.white70)),
                    Text(
                      'Unresolved: ${preview.needsLink - preview.resolvable}',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w700),
                    ),
                    if (preview.unresolvedSamples.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text('Sample unresolved listings:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...preview.unresolvedSamples.map(
                        (sample) => Text('• $sample', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF061E12),
                  ),
                  onPressed: preview.resolvable == 0 ? null : () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Run Linking'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldRun == true) {
      await _linkLegacyListingsToAccounts();
    }
  }

  Future<void> _linkLegacyListingsToAccounts() async {
    if (_isLinkingLegacyListings || _isBackfillingLegacyListings) return;
    setState(() {
      _isLinkingLegacyListings = true;
    });

    var scanned = 0;
    var linked = 0;
    var bySource = 0;
    var byEmail = 0;
    final patches = <String, Map<String, dynamic>>{};

    try {
      QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
      while (true) {
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection('announcements')
            .where('type', isEqualTo: 'listing')
            .orderBy('createdAt', descending: true)
            .limit(200);
        if (cursor != null) {
          query = query.startAfterDocument(cursor);
        }

        final page = await query.get();
        if (page.docs.isEmpty) break;

        for (final doc in page.docs) {
          scanned += 1;
          final data = doc.data();
          final existingUid = (data['userId'] ?? '').toString().trim();
          if (existingUid.isNotEmpty) continue;

          final resolved = await _resolveLegacyListingLink(data);
          if (resolved.userId.isEmpty) continue;
          if (resolved.resolvedBy == 'source') {
            bySource += 1;
          } else if (resolved.resolvedBy == 'email') {
            byEmail += 1;
          }

          final patch = <String, dynamic>{
            'userId': resolved.userId,
            'linkedAt': FieldValue.serverTimestamp(),
            'linkSource': resolved.resolvedBy,
          };

          if (resolved.sourceCollection.isNotEmpty) {
            patch['sourceCollection'] = resolved.sourceCollection;
          }
          if (resolved.sourceId.isNotEmpty) {
            patch['sourceId'] = resolved.sourceId;
          }

          patches[doc.id] = patch;
        }

        cursor = page.docs.last;
        if (page.docs.length < 200) break;
      }

      if (patches.isNotEmpty) {
        var batch = FirebaseFirestore.instance.batch();
        var opCount = 0;
        for (final entry in patches.entries) {
          final ref = FirebaseFirestore.instance.collection('announcements').doc(entry.key);
          batch.set(ref, entry.value, SetOptions(merge: true));
          opCount += 1;
          if (opCount >= 350) {
            await batch.commit();
            linked += opCount;
            batch = FirebaseFirestore.instance.batch();
            opCount = 0;
          }
        }
        if (opCount > 0) {
          await batch.commit();
          linked += opCount;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account link completed. Scanned: $scanned, Linked: $linked (source: $bySource, email: $byEmail).',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account link failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLinkingLegacyListings = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _findSourceForLegacyListing(Map<String, dynamic> listing) async {
    final sourceCollection = (listing['sourceCollection'] ?? '').toString().trim();
    final sourceId = (listing['sourceId'] ?? '').toString().trim();
    final title = (listing['title'] ?? '').toString().trim();

    if (sourceCollection.isNotEmpty && sourceId.isNotEmpty) {
      final sourceDoc = await FirebaseFirestore.instance.collection(sourceCollection).doc(sourceId).get();
      if (sourceDoc.exists) {
        final sourceData = sourceDoc.data() ?? const <String, dynamic>{};
        return _listingPatchFromSource(sourceData, sourceCollection: sourceCollection, sourceId: sourceDoc.id);
      }
    }

    if (title.isEmpty) return null;

    Future<Map<String, dynamic>?> search(String collection) async {
      final snap = await FirebaseFirestore.instance
          .collection(collection)
          .where('title', isEqualTo: title)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return _listingPatchFromSource(doc.data(), sourceCollection: collection, sourceId: doc.id);
    }

    return await search('jobs')
        ?? await search('market_items')
        ?? await search('business_profiles')
        ?? await search('verified_professionals');
  }

  Future<void> _backfillLegacyListingContacts() async {
    if (_isBackfillingLegacyListings) return;
    setState(() {
      _isBackfillingLegacyListings = true;
    });

    var scanned = 0;
    var updated = 0;
    final patches = <String, Map<String, dynamic>>{};

    try {
      QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
      while (true) {
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection('announcements')
            .where('type', isEqualTo: 'listing')
            .orderBy('createdAt', descending: true)
            .limit(200);
        if (cursor != null) {
          query = query.startAfterDocument(cursor);
        }

        final page = await query.get();
        if (page.docs.isEmpty) break;

        for (final doc in page.docs) {
          scanned += 1;
          final data = doc.data();
          final needsBackfill = (data['providerName'] ?? '').toString().trim().isEmpty
              || (data['phone'] ?? '').toString().trim().isEmpty
              || (data['email'] ?? '').toString().trim().isEmpty
              || (data['website'] ?? '').toString().trim().isEmpty
              || (data['userId'] ?? '').toString().trim().isEmpty
              || (data['sourceCollection'] ?? '').toString().trim().isEmpty
              || (data['sourceId'] ?? '').toString().trim().isEmpty;

          if (!needsBackfill) continue;
          final found = await _findSourceForLegacyListing(data);
          if (found == null) continue;

          final patch = <String, dynamic>{};
          for (final entry in found.entries) {
            final current = (data[entry.key] ?? '').toString().trim();
            final incoming = (entry.value ?? '').toString().trim();
            if (current.isEmpty && incoming.isNotEmpty) {
              patch[entry.key] = entry.value;
            }
          }
          if (patch.isNotEmpty) {
            patch['backfilledAt'] = FieldValue.serverTimestamp();
            patches[doc.id] = patch;
          }
        }

        cursor = page.docs.last;
        if (page.docs.length < 200) break;
      }

      if (patches.isNotEmpty) {
        var batch = FirebaseFirestore.instance.batch();
        var opCount = 0;
        for (final entry in patches.entries) {
          final ref = FirebaseFirestore.instance.collection('announcements').doc(entry.key);
          batch.set(ref, entry.value, SetOptions(merge: true));
          opCount += 1;
          if (opCount >= 350) {
            await batch.commit();
            updated += opCount;
            batch = FirebaseFirestore.instance.batch();
            opCount = 0;
          }
        }
        if (opCount > 0) {
          await batch.commit();
          updated += opCount;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Legacy listing backfill completed. Scanned: $scanned, Updated: $updated.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Legacy listing backfill failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBackfillingLegacyListings = false;
        });
      }
    }
  }

  Future<_LegacyBackfillPreview> _buildLegacyBackfillPreview() async {
    var scanned = 0;
    var needsBackfill = 0;
    var resolvable = 0;
    final unresolvedSamples = <String>[];
    final unresolvedDetails = <_LegacyUnresolvedItem>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;

    while (true) {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('announcements')
          .where('type', isEqualTo: 'listing')
          .orderBy('createdAt', descending: true)
          .limit(200);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final page = await query.get();
      if (page.docs.isEmpty) break;

      for (final doc in page.docs) {
        scanned += 1;
        final data = doc.data();
        final missing = (data['providerName'] ?? '').toString().trim().isEmpty
            || (data['phone'] ?? '').toString().trim().isEmpty
            || (data['email'] ?? '').toString().trim().isEmpty
            || (data['website'] ?? '').toString().trim().isEmpty
            || (data['userId'] ?? '').toString().trim().isEmpty
            || (data['sourceCollection'] ?? '').toString().trim().isEmpty
            || (data['sourceId'] ?? '').toString().trim().isEmpty;
        if (!missing) continue;

        needsBackfill += 1;
        final found = await _findSourceForLegacyListing(data);
        if (found != null) {
          resolvable += 1;
        } else if (unresolvedSamples.length < 5) {
          final sampleTitle = _firstNonEmptyValue([data['title'], data['providerName'], data['category'], doc.id]);
          unresolvedSamples.add(sampleTitle);
          unresolvedDetails.add(
            _LegacyUnresolvedItem(
              docId: doc.id,
              title: _firstNonEmptyValue([data['title'], data['providerName'], data['category'], 'Untitled']),
              category: _firstNonEmptyValue([data['category']]),
            ),
          );
        }
      }

      cursor = page.docs.last;
      if (page.docs.length < 200) break;
    }

    return _LegacyBackfillPreview(
      scanned: scanned,
      needsBackfill: needsBackfill,
      resolvable: resolvable,
      unresolvedSamples: unresolvedSamples,
      unresolvedDetails: unresolvedDetails,
    );
  }

  String _legacyBackfillPreviewReport(_LegacyBackfillPreview preview) {
    final unresolvedCount = preview.needsBackfill - preview.resolvable;
    final lines = <String>[
      'Legacy Backfill Preview Report',
      'Scanned: ${preview.scanned}',
      'Needs Backfill: ${preview.needsBackfill}',
      'Resolvable: ${preview.resolvable}',
      'Unresolved: $unresolvedCount',
      '',
      'Sample unresolved listings:',
    ];

    if (preview.unresolvedDetails.isEmpty) {
      lines.add('- none');
    } else {
      for (final detail in preview.unresolvedDetails) {
        lines.add(
          '- ${detail.title} | category=${detail.category.isEmpty ? 'unknown' : detail.category} | docId=${detail.docId}',
        );
      }
    }
    return lines.join('\n');
  }

  Future<void> _copyBackfillPreviewReport(_LegacyBackfillPreview preview) async {
    final text = _legacyBackfillPreviewReport(preview);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backfill preview report copied to clipboard.')),
    );
  }

  String _legacyBackfillPreviewJson(_LegacyBackfillPreview preview) {
    final unresolvedCount = preview.needsBackfill - preview.resolvable;
    final payload = <String, dynamic>{
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'scanned': preview.scanned,
      'needsBackfill': preview.needsBackfill,
      'resolvable': preview.resolvable,
      'unresolved': unresolvedCount,
      'unresolvedSamples': preview.unresolvedSamples,
      'unresolvedDetails': preview.unresolvedDetails
          .map(
            (item) => <String, String>{
              'docId': item.docId,
              'title': item.title,
              'category': item.category,
            },
          )
          .toList(growable: false),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> _copyBackfillPreviewJson(_LegacyBackfillPreview preview) async {
    final text = _legacyBackfillPreviewJson(preview);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backfill preview JSON copied to clipboard.')),
    );
  }

  Future<void> _saveBackfillPreviewJson(_LegacyBackfillPreview preview) async {
    final fileName = 'legacy_backfill_preview_${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}.json';
    final jsonText = _legacyBackfillPreviewJson(preview);

    try {
      String outputPath;
      if (kIsWeb) {
        outputPath = fileName;
        await XFile.fromData(
          Uint8List.fromList(utf8.encode(jsonText)),
          name: fileName,
          mimeType: 'application/json',
        ).saveTo(outputPath);
      } else {
        final userHome = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
        final baseDir = (userHome != null && userHome.trim().isNotEmpty)
            ? Directory('$userHome${Platform.pathSeparator}Desktop${Platform.pathSeparator}euro_habesha_reports${Platform.pathSeparator}backfill_previews')
            : Directory('${Directory.systemTemp.path}${Platform.pathSeparator}euro_habesha_reports${Platform.pathSeparator}backfill_previews');

        if (!await baseDir.exists()) {
          await baseDir.create(recursive: true);
        }

        outputPath = '${baseDir.path}${Platform.pathSeparator}$fileName';
        await File(outputPath).writeAsString(jsonText);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved preview JSON to $outputPath')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save JSON file: $error')),
      );
    }
  }

  Future<void> _showBackfillPreviewDialog() async {
    if (_isBackfillingLegacyListings) return;
    final shouldRun = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<_LegacyBackfillPreview>(
          future: _buildLegacyBackfillPreview(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                backgroundColor: Color(0xFF0E2E1E),
                title: Text('Backfill Preview', style: TextStyle(color: Colors.white)),
                content: SizedBox(
                  height: 84,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFF59E0B)),
                        SizedBox(height: 12),
                        Text('Analyzing legacy listings...', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                backgroundColor: const Color(0xFF0E2E1E),
                title: const Text('Backfill Preview Failed', style: TextStyle(color: Colors.white)),
                content: Text(
                  'Could not compute preview: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            final preview = snapshot.data
                ?? const _LegacyBackfillPreview(
                  scanned: 0,
                  needsBackfill: 0,
                  resolvable: 0,
                  unresolvedSamples: [],
                  unresolvedDetails: [],
                );
            return AlertDialog(
              backgroundColor: const Color(0xFF0E2E1E),
              title: const Text('Backfill Preview', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Scanned listing posts: ${preview.scanned}', style: const TextStyle(color: Colors.white70)),
                    Text('Need metadata backfill: ${preview.needsBackfill}', style: const TextStyle(color: Colors.white70)),
                    Text('Resolvable and ready to update: ${preview.resolvable}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
                    Text(
                      'Unresolved: ${preview.needsBackfill - preview.resolvable}',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w700),
                    ),
                    if (preview.unresolvedSamples.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text('Sample unresolved listings:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...preview.unresolvedSamples.map(
                        (sample) => Text('• $sample', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Running backfill updates only missing fields and leaves existing values unchanged.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => _copyBackfillPreviewReport(preview),
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text('Copy Report'),
                ),
                TextButton.icon(
                  onPressed: () => _copyBackfillPreviewJson(preview),
                  icon: const Icon(Icons.data_object_outlined, size: 16),
                  label: const Text('Copy JSON'),
                ),
                TextButton.icon(
                  onPressed: () => _saveBackfillPreviewJson(preview),
                  icon: const Icon(Icons.save_alt_outlined, size: 16),
                  label: const Text('Save JSON (Desktop)'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF061E12),
                  ),
                  onPressed: preview.resolvable == 0 ? null : () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Run Backfill'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldRun == true) {
      await _backfillLegacyListingContacts();
    }
  }

  @override
  void dispose() {
    _announcementTitleController.dispose();
    _announcementDescController.dispose();
    _announcementLinkController.dispose();
    _jobTitleController.dispose();
    _jobCompanyController.dispose();
    _jobPriceController.dispose();
    _jobCityController.dispose();
    _jobPhoneController.dispose();
    _jobDescController.dispose();
    _businessNameController.dispose();
    _businessCategoryController.dispose();
    _businessOwnerController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    _businessCityController.dispose();
    _businessAddressController.dispose();
    _businessWebsiteController.dispose();
    _businessDescController.dispose();
    _businessRateController.dispose();
    _professionalNameController.dispose();
    _professionalCategoryController.dispose();
    _professionalCountryController.dispose();
    _professionalCityController.dispose();
    _professionalPhoneController.dispose();
    _professionalEmailController.dispose();
    _professionalWebsiteController.dispose();
    _professionalWhatsappController.dispose();
    _professionalBioController.dispose();
    _professionalImageUrlController.dispose();
    _professionalUserIdController.dispose();
    _messageBypassUidController.dispose();
    _subAdminEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAccess) {
      return const Scaffold(
        backgroundColor: Color(0xFF061E12),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF061E12), // Deep emerald
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2E1E),
        title: GestureDetector(
          onLongPress: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminQaScreen()),
            );
          },
          child: const Text(
            'ADMIN GATEWAY & SPONSOR PANEL',
            style: TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: 7,
        child: Column(
          children: [
            Container(
              color: const Color(0xFF0E2E1E),
              child: const TabBar(
                indicatorColor: Color(0xFFF59E0B),
                labelColor: Color(0xFFF59E0B),
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(text: 'Announce', icon: Icon(Icons.star, size: 18)),
                  Tab(text: 'Add Job', icon: Icon(Icons.work_outline, size: 18)),
                  Tab(text: 'Add Business', icon: Icon(Icons.storefront_outlined, size: 18)),
                  Tab(text: 'Verified Pro', icon: Icon(Icons.workspace_premium_outlined, size: 18)),
                  Tab(text: 'Verify / Audit', icon: Icon(Icons.gavel_outlined, size: 18)),
                  Tab(text: 'Manage Posts', icon: Icon(Icons.edit_note_outlined, size: 18)),
                  Tab(text: 'Sub-admins', icon: Icon(Icons.manage_accounts_outlined, size: 18)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAnnounceTab(),
                  _buildAddJobTab(),
                  _buildAddBusinessTab(),
                  _buildVerifiedProfessionalTab(),
                  _buildVerifyTab(),
                  _buildManagePostsTab(),
                  _buildSubAdminTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnounceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _announcementFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PIN A NEW ANNOUNCEMENT / ታላቅ ማስታወቂያ',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pinned announcements will appear at the top of the Home feed with high-priority visual borders.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _announcementTitleController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Announcement Title (e.g. Festival in London)'),
              validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 14),

            // Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _announcementCategory,
              dropdownColor: const Color(0xFF0E2E1E),
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Category'),
              items: ['Events', 'Jobs', 'Promotions', 'Legal Update', 'Immigration Alert', 'General']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _announcementCategory = val!;
                });
              },
            ),
            const SizedBox(height: 14),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
                side: const BorderSide(color: Color(0xFFF59E0B)),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _announcementExpiryDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked == null || !mounted) return;
                setState(() {
                  _announcementExpiryDate = picked;
                });
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(
                'Expiry Date: ${_announcementExpiryDate.year}-${_announcementExpiryDate.month.toString().padLeft(2, '0')}-${_announcementExpiryDate.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 14),

            // Content
            TextFormField(
              controller: _announcementDescController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Description & Call to Action (Support Amharic Unicode)'),
              validator: (val) => val == null || val.isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _announcementLinkController,
              keyboardType: TextInputType.url,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('External Link (optional, https://...)'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tip: Paste ticket/website/news link here if users should open something online.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0E2E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attach files for this announcement',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Click "Select Files" to attach images, PDFs, or documents.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _announcementFiles
                        .map(
                          (file) => Chip(
                            backgroundColor: const Color(0xFF123425),
                            label: Text(file.name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            deleteIconColor: Colors.redAccent,
                            onDeleted: () {
                              setState(() {
                                _announcementFiles.remove(file);
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                    ),
                    onPressed: _pickAnnouncementFiles,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Select Files'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isUploadingAnnouncement ? null : _submitAnnouncement,
                child: _isUploadingAnnouncement
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publish Pinned Banner', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddJobTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _jobFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FEATURED JOB CREATION / አዲስ የስራ ማስታወቂያ',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Introduce vetted, premium job opportunities for Ethiopian/Eritrean professionals in Europe.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Job Title
            TextFormField(
              controller: _jobTitleController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Job Position (e.g. Legal Secretary)'),
              validator: (val) => val == null || val.isEmpty ? 'Job position is required' : null,
            ),
            const SizedBox(height: 14),

            // Company/Author
            TextFormField(
              controller: _jobCompanyController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Sponsoring Organization / Member Name'),
              validator: (val) => val == null || val.isEmpty ? 'Company or Member name is required' : null,
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _selectedJobCategory,
              dropdownColor: const Color(0xFF0E2E1E),
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Job Category / Type'),
              items: _jobCategories
                  .map((category) => DropdownMenuItem<String>(value: category, child: Text(category)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedJobCategory = value;
                });
              },
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _selectedJobCountry,
              dropdownColor: const Color(0xFF0E2E1E),
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Country'),
              items: _jobCountryDialCodes.keys
                  .map((country) => DropdownMenuItem<String>(
                        value: country,
                        child: Text('$country (${_jobCountryDialCodes[country]})'),
                      ))
                  .toList(),
              onChanged: _handleJobCountryChange,
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _jobPriceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration('Hourly Rate (€ / Hour)'),
                    validator: (val) => val == null || val.isEmpty ? 'Hourly rate required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _jobCityController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration('City (e.g. Frankfurt)'),
                    validator: (val) => val == null || val.isEmpty ? 'City required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _jobPhoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\s-]')),
              ],
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Contact Phone (optional)').copyWith(
                prefixText: '$_selectedJobDialCode ',
                prefixStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                hintText: 'e.g. 612345678',
              ),
            ),
            const SizedBox(height: 14),

            // Description
            TextFormField(
              controller: _jobDescController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Describe Job requirements, location details, etc.'),
              validator: (val) => val == null || val.isEmpty ? 'Job description is required' : null,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _submitJob,
                child: const Text('Post Featured Job Listing', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBusinessTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _businessFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PROFESSIONAL / RESTAURANT / BUSINESS PUBLISHING',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create and publish full business profiles with photos, address, and complete service details.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              initialValue: _businessType,
              dropdownColor: const Color(0xFF0E2E1E),
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Business Type'),
              items: const [
                DropdownMenuItem(value: 'Professional', child: Text('Professional')),
                DropdownMenuItem(value: 'Restaurant', child: Text('Restaurant')),
                DropdownMenuItem(value: 'Other Business', child: Text('Other Business')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _businessType = value;
                });
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _businessNameController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Business/Profile Name'),
              validator: (val) => val == null || val.trim().isEmpty ? 'Business name is required' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _businessCategoryController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Service Category (e.g. Doctor, Restaurant, Lawyer)'),
              validator: (val) => val == null || val.trim().isEmpty ? 'Category is required' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _businessOwnerController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Owner / Contact Person'),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _selectedBusinessCountry,
              dropdownColor: const Color(0xFF0E2E1E),
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Country (choose by flag)'),
              items: _businessCountryDialCodes.keys.map((country) {
                final flag = _businessCountryFlags[country] ?? '🌍';
                final dial = _businessCountryDialCodes[country] ?? '';
                return DropdownMenuItem<String>(
                  value: country,
                  child: Text('$flag  $country  ($dial)'),
                );
              }).toList(),
              onChanged: _handleBusinessCountryChange,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _businessPhoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\s-]')),
                    ],
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration('Local Phone Number').copyWith(
                      prefixText: '$_selectedBusinessDialCode ',
                      prefixStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      hintText: 'e.g. 612345678',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Phone is required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _businessEmailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration('Email (optional)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _businessCityController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration('City'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'City is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _businessAddressController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Full Address'),
              validator: (val) => val == null || val.trim().isEmpty ? 'Address is required' : null,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _businessRateController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration('Service Rate EUR (optional, e.g. 20-30)').copyWith(
                      hintText: '20-30 or 25',
                    ),
                    validator: (val) {
                      final value = (val ?? '').trim();
                      if (value.isEmpty) return null;
                      if (_parseRateRange(value) == null) {
                        return 'Use 20-30 or 25';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _businessWebsiteController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration('Website (optional, https://...)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _businessDescController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Business Details / Services Description'),
              validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0E2E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile & Business Photos',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Attach logo/profile image and business photos. First photo will be used as the listing image.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _businessPhotos
                        .map(
                          (file) => Chip(
                            backgroundColor: const Color(0xFF123425),
                            label: Text(file.name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            deleteIconColor: Colors.redAccent,
                            onDeleted: () {
                              setState(() {
                                _businessPhotos.remove(file);
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                    ),
                    onPressed: _pickBusinessPhotos,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Select Photos'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isPublishingBusiness ? null : _publishBusinessProfile,
                child: _isPublishingBusiness
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create & Publish Business Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Pending User-Created Content',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('job_submissions')
              .limit(250)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
              );
            }

            if (snapshot.hasError) {
              return Text(
                'Could not load pending submissions: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              );
            }

            bool isPending(Map<String, dynamic> data) {
              final status = (data['status'] ?? '').toString().trim().toLowerCase();
              final moderation = (data['moderationStatus'] ?? '').toString().trim().toLowerCase();
              final adminReview = (data['adminReview'] ?? '').toString().trim().toLowerCase();

              return status == 'pending'
                  || status == 'submitted'
                  || status == 'pending_admin'
                  || status == 'pending_approval'
                  || moderation == 'pending'
                  || adminReview == 'pending';
            }

            final docs = (snapshot.data?.docs ?? []).where((doc) => isPending(doc.data())).toList();
            if (docs.isEmpty) {
              return const Text(
                'No pending profiles/listings/associations. If users posted recently, verify they are writing to this Firebase project and that your admin account has access.',
                style: TextStyle(color: Colors.white54),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final title = (data['title'] ?? 'Untitled submission').toString();
                final submittedBy = (data['submittedBy'] ?? 'unknown').toString();

                return Card(
                  color: const Color(0xFF0E2E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  child: ListTile(
                    title: Text('Job: $title', style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'Submitted by $submittedBy',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _rejectPendingSubmission(doc.id),
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                        ),
                        IconButton(
                          onPressed: () => _approvePendingSubmission(submissionId: doc.id, data: data),
                          icon: const Icon(Icons.check, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Pending Association Verifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Review legal documents submitted by associations. Approve to activate the Blue Verified Tick.',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('associations')
              .where('verificationStatus', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Text('No pending association verifications to audit.', style: TextStyle(color: Colors.white54));
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final legalName = (data['legalName'] ?? 'Unknown').toString();
                final address = (data['exactAddress'] ?? 'Unknown').toString();
                final serial = (data['serialRegistrationNumber'] ?? '').toString();
                final email = (data['email'] ?? '').toString();
                final documentName = (data['documentName'] ?? 'registration_document.jpg').toString();
                final documentDownloadUrl = (data['documentDownloadUrl'] ?? '').toString();
                final documentBase64 = (data['documentImageBase64'] ?? '').toString();

                return Card(
                  color: const Color(0xFF0E2E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          legalName,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text('Email: $email', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('Address: $address', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('Serial Number: $serial', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        const Divider(color: Colors.white12, height: 20),
                        Text('Document: $documentName', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showAssociationDocumentDialog(
                                legalName: legalName,
                                documentName: documentName,
                                documentDownloadUrl: documentDownloadUrl,
                                documentImageBase64: documentBase64,
                              ),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Review Document'),
                            ),
                            TextButton(
                              onPressed: () => _updateAssociationVerification(
                                associationId: doc.id,
                                approve: false,
                              ),
                              child: const Text('Deny', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B721),
                                foregroundColor: const Color(0xFF061E12),
                              ),
                              onPressed: () => _updateAssociationVerification(
                                associationId: doc.id,
                                approve: true,
                              ),
                              child: const Text('Approve & Activate Blue Tick'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVerifiedProfessionalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _verifiedProfessionalFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Publish Verified Professional',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This publishes directly to the verified professionals feed shown in home/profile sections.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _professionalNameController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Name'),
              validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _professionalCategoryController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Category (Doctor, Lawyer, etc.)'),
              validator: (val) => val == null || val.trim().isEmpty ? 'Category is required' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _professionalCountryController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration('Country'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Country is required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _professionalCityController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _buildInputDecoration('City'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'City is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _professionalPhoneController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Phone'),
              validator: (val) => val == null || val.trim().isEmpty ? 'Phone is required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _professionalEmailController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Email (optional)'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _professionalWebsiteController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Website (optional, https://...)'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _professionalWhatsappController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('WhatsApp (optional)'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _professionalImageUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Image URL (optional)'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _professionalUserIdController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Linked userId for messaging (optional)'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _professionalVerificationStage,
              dropdownColor: const Color(0xFF0E2E1E),
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Verification Stage'),
              items: const [
                DropdownMenuItem(value: 'professional', child: Text('Professional')),
                DropdownMenuItem(value: 'vip', child: Text('VIP')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _professionalVerificationStage = value;
                });
              },
            ),
            const SizedBox(height: 10),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _professionalVerified,
              activeThumbColor: const Color(0xFFF59E0B),
              activeTrackColor: const Color(0x66F59E0B),
              title: const Text('Mark as verified', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Controls admin-verified badge visibility.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              onChanged: (value) {
                setState(() {
                  _professionalVerified = value;
                });
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _professionalBioController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration('Bio / Service details'),
              validator: (val) => val == null || val.trim().isEmpty ? 'Bio is required' : null,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                ),
                onPressed: _isPublishingProfessional ? null : _publishVerifiedProfessional,
                child: _isPublishingProfessional
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publish Verified Professional', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagePostsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Modify or Delete Any Post',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Edit and delete actions apply immediately to live content.',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: const Color(0xFF061E12),
          ),
          onPressed: _isBackfillingLegacyListings ? null : _showBackfillPreviewDialog,
          icon: _isBackfillingLegacyListings
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF061E12)),
                )
              : const Icon(Icons.sync_alt_outlined),
          label: Text(_isBackfillingLegacyListings ? 'Backfilling...' : 'Backfill Legacy Listing Contacts'),
        ),
        const SizedBox(height: 6),
        const Text(
          'Hydrates old live listings with provider contact and source metadata for universal messaging.',
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A2D),
            foregroundColor: Colors.white,
          ),
          onPressed: (_isLinkingLegacyListings || _isBackfillingLegacyListings) ? null : _showAccountLinkPreviewDialog,
          icon: _isLinkingLegacyListings
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.link_outlined),
          label: Text(_isLinkingLegacyListings ? 'Linking Accounts...' : 'Link Legacy Listings To Accounts'),
        ),
        const SizedBox(height: 6),
        const Text(
          'Auto-links listings missing userId using source metadata first, then users by email.',
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 12),
        _buildMessageBypassControlSection(),
        const SizedBox(height: 12),
        _buildMessageQuotaMonitorSection(),
        const SizedBox(height: 12),
        _buildManageCollectionSection(title: 'Announcements', collectionName: 'announcements'),
        const SizedBox(height: 14),
        _buildManageCollectionSection(title: 'Jobs', collectionName: 'jobs'),
        const SizedBox(height: 14),
        _buildManageCollectionSection(title: 'Business Profiles', collectionName: 'business_profiles'),
        const SizedBox(height: 14),
        _buildManageCollectionSection(title: 'Market Items', collectionName: 'market_items'),
        const SizedBox(height: 14),
        _buildManageCollectionSection(title: 'Verified Professionals', collectionName: 'verified_professionals'),
      ],
    );
  }

  Widget _buildSubAdminTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Add and manage sub-admins for moderation support.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _subAdminEmailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration('Sub-admin email'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                ),
                onPressed: _isOwner
                    ? () async {
                  final value = _subAdminEmailController.text.trim();
                  if (value.isEmpty) return;
                  final invitedBy = AccessControl.currentNormalizedContact() ?? 'unknown';
                  await AdminRoleService.grantSubAdmin(email: value, invitedBy: invitedBy);
                  if (!mounted) return;
                  setState(() {
                    _subAdminEmailController.clear();
                  });
                }
                    : null,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!_isOwner)
            const Text(
              'Only owner can grant or revoke admin access.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('admin_roles')
                  .where('role', isEqualTo: 'subadmin')
                  .where('active', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No invited sub-admins yet.', style: TextStyle(color: Colors.white54)),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final email = (data['contact'] ?? docs[index].id).toString();
                    return Card(
                      color: const Color(0xFF0E2E1E),
                      child: ListTile(
                        title: Text(email, style: const TextStyle(color: Colors.white)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: _isOwner
                              ? () async {
                                  await AdminRoleService.revokeAdmin(email);
                                }
                              : null,
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

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF59E0B)),
      ),
    );
  }

}

class _SelectedAttachment {
  const _SelectedAttachment({
    required this.name,
    required this.size,
    this.path,
    this.bytes,
  });

  final String name;
  final int size;
  final String? path;
  final Uint8List? bytes;
}

class _RateRange {
  const _RateRange({required this.min, required this.max});

  final double min;
  final double max;
}

class _LegacyBackfillPreview {
  const _LegacyBackfillPreview({
    required this.scanned,
    required this.needsBackfill,
    required this.resolvable,
    required this.unresolvedSamples,
    required this.unresolvedDetails,
  });

  final int scanned;
  final int needsBackfill;
  final int resolvable;
  final List<String> unresolvedSamples;
  final List<_LegacyUnresolvedItem> unresolvedDetails;
}

class _LegacyAccountLinkPreview {
  const _LegacyAccountLinkPreview({
    required this.scanned,
    required this.needsLink,
    required this.resolvable,
    required this.bySource,
    required this.byEmail,
    required this.unresolvedSamples,
    required this.unresolvedDetails,
  });

  final int scanned;
  final int needsLink;
  final int resolvable;
  final int bySource;
  final int byEmail;
  final List<String> unresolvedSamples;
  final List<_LegacyUnresolvedItem> unresolvedDetails;
}

class _LegacyLinkResolution {
  const _LegacyLinkResolution({
    required this.userId,
    required this.resolvedBy,
    required this.sourceCollection,
    required this.sourceId,
  });

  final String userId;
  final String resolvedBy;
  final String sourceCollection;
  final String sourceId;
}

class _LegacyUnresolvedItem {
  const _LegacyUnresolvedItem({
    required this.docId,
    required this.title,
    required this.category,
  });

  final String docId;
  final String title;
  final String category;
}