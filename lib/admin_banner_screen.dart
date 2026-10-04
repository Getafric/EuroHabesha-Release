import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_session.dart';

class AdminBannerScreen extends StatefulWidget {
  const AdminBannerScreen({super.key});

  @override
  State<AdminBannerScreen> createState() => _AdminBannerScreenState();
}

class _AdminBannerScreenState extends State<AdminBannerScreen> {
  static const Color darkGreen = Color(0xFF061E12);
  static const Color cardGreen = Color(0xFF004D40);
  static const Color gold = Color(0xFFFFD700);

  final _title = TextEditingController();
  final _body = TextEditingController();
  final _promoCode = TextEditingController();
  final _usageLimit = TextEditingController(text: '100');

  final ImagePicker _picker = ImagePicker();

  final List<double> _presetDiscounts = [
    5,
    10,
    15,
    20,
    25,
    30,
    50,
  ];

  double _discountPercent = 20;

  File? _bannerImageFile;
  String _existingImageUrl = '';

  String _targetType = 'business';

  String? _selectedTargetId;
  String? _selectedTargetName;
  Map<String, dynamic>? _selectedTargetData;

  DateTime _startsAt = DateTime.now();
  DateTime _endsAt = DateTime.now().add(
    const Duration(days: 30),
  );

  String? _editingBannerId;
  bool _saving = false;
  bool _showForm = false;

  bool get _isEditing => _editingBannerId != null;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _promoCode.dispose();
    _usageLimit.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: cardGreen,
      ),
    );
  }

  Future<void> _pickBannerImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null || !mounted) return;

    setState(() {
      _bannerImageFile = File(picked.path);
    });
  }

  void _resetForm() {
    _title.clear();
    _body.clear();
    _promoCode.clear();
    _usageLimit.text = '100';

    setState(() {
      _editingBannerId = null;
      _bannerImageFile = null;
      _existingImageUrl = '';
      _targetType = 'business';
      _selectedTargetId = null;
      _selectedTargetName = null;
      _selectedTargetData = null;
      _discountPercent = 20;
      _startsAt = DateTime.now();
      _endsAt = DateTime.now().add(
        const Duration(days: 30),
      );
      _showForm = false;
    });
  }

  void _startCreate() {
    _title.clear();
    _body.clear();
    _promoCode.clear();
    _usageLimit.text = '100';

    setState(() {
      _editingBannerId = null;
      _bannerImageFile = null;
      _existingImageUrl = '';
      _targetType = 'business';
      _selectedTargetId = null;
      _selectedTargetName = null;
      _selectedTargetData = null;
      _discountPercent = 20;
      _startsAt = DateTime.now();
      _endsAt = DateTime.now().add(
        const Duration(days: 30),
      );
      _showForm = true;
    });
  }

  void _startEdit(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    _title.text = (data['title'] ??
            data['businessName'] ??
            data['targetBusinessName'] ??
            '')
        .toString();

    _body.text = (data['body'] ?? data['description'] ?? '').toString();

    _promoCode.text = (data['promoCode'] ?? '').toString();

    _usageLimit.text = (data['usageLimit'] ?? 100).toString();

    final discount = data['discountPercent'];

    final startsAt = data['startsAt'];
    final endsAt = data['endsAt'];

    setState(() {
      _editingBannerId = doc.id;
      _bannerImageFile = null;
      _existingImageUrl = (data['imageUrl'] ?? '').toString();

      _targetType = (data['targetType'] ?? 'business').toString().toLowerCase();

      if (!['business', 'event', 'marketplace'].contains(_targetType)) {
        _targetType = 'business';
      }

      _selectedTargetId =
          (data['targetId'] ?? data['targetBusinessId'] ?? '').toString();

      if (_selectedTargetId!.isEmpty) {
        _selectedTargetId = null;
      }

      _selectedTargetName =
          (data['targetName'] ?? data['targetBusinessName'] ?? '').toString();

      final savedTargetData = data['targetData'] ?? data['targetBusinessData'];

      _selectedTargetData = savedTargetData is Map
          ? Map<String, dynamic>.from(savedTargetData)
          : null;

      _discountPercent = discount is num ? discount.toDouble() : 20;

      if (!_presetDiscounts.contains(
        _discountPercent,
      )) {
        _discountPercent = 20;
      }

      _startsAt = startsAt is Timestamp ? startsAt.toDate() : DateTime.now();

      _endsAt = endsAt is Timestamp
          ? endsAt.toDate()
          : DateTime.now().add(
              const Duration(days: 30),
            );

      _showForm = true;
    });
  }

  Future<void> _chooseStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (date == null || !mounted) return;

    setState(() {
      _startsAt = date;

      if (_endsAt.isBefore(_startsAt)) {
        _endsAt = _startsAt.add(
          const Duration(days: 30),
        );
      }
    });
  }

  Future<void> _chooseEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endsAt.isBefore(_startsAt) ? _startsAt : _endsAt,
      firstDate: _startsAt,
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (date == null || !mounted) return;

    setState(() {
      _endsAt = date;
    });
  }

  Future<String> _uploadImage() async {
    if (_bannerImageFile == null) {
      return _existingImageUrl;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Administrator is not signed in.');
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_banner.jpg';

    final ref = FirebaseStorage.instance.ref(
      'announcements/${user.uid}/$fileName',
    );

    await ref.putFile(_bannerImageFile!);

    return ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (!AppSession.isSuperAdmin) {
      _message('Super Admin access required.');
      return;
    }

    final title = _title.text.trim();
    final body = _body.text.trim();

    if (title.isEmpty) {
      _message('Please enter banner title.');
      return;
    }

    if (_endsAt.isBefore(_startsAt)) {
      _message('End date must be after start date.');
      return;
    }

    setState(() => _saving = true);

    try {
      final imageUrl = await _uploadImage();

      final promotion = '${_discountPercent.toInt()}% OFF';

      final data = <String, dynamic>{
        // Existing schema.
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'promoCode': _promoCode.text.trim().toUpperCase(),
        'discountPercent': _discountPercent,
        'discountText': promotion,
        'usageLimit': int.tryParse(_usageLimit.text.trim()) ?? 100,
        'targetType': _targetType,
        'targetId': _selectedTargetId ?? '',
        'targetName': _selectedTargetName ?? '',
        'targetData': _selectedTargetData ?? {},
        'targetRoute': _targetType == 'event'
            ? '/event'
            : _targetType == 'marketplace'
                ? '/marketplace'
                : '/business',

// Compatibilité avec les anciennes publicités Business.
        'targetBusinessId':
            _targetType == 'business' ? _selectedTargetId ?? '' : '',
        'targetBusinessName':
            _targetType == 'business' ? _selectedTargetName ?? '' : '',
        'targetBusinessData':
            _targetType == 'business' ? _selectedTargetData ?? {} : {},

        // New carousel-compatible schema.
        'businessName': (_selectedTargetName?.trim().isNotEmpty ?? false)
            ? _selectedTargetName
            : title,
        'description': body,
        'promotion': promotion,

        'startsAt': Timestamp.fromDate(_startsAt),
        'endsAt': Timestamp.fromDate(_endsAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final collection =
          FirebaseFirestore.instance.collection('sponsoredBanners');

      if (_isEditing) {
        await collection.doc(_editingBannerId).set(
              data,
              SetOptions(merge: true),
            );

        _message('Advertisement updated successfully.');
      } else {
        await collection.add({
          ...data,
          'status': 'active',
          'claimsCount': 0,
          'createdBy': AppSession.email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _message('Advertisement created successfully.');
      }

      _resetForm();
    } catch (error) {
      _message('Could not save advertisement: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _toggleStatus(
    String bannerId,
    String currentStatus,
  ) async {
    try {
      final nextStatus = currentStatus == 'active' ? 'paused' : 'active';

      await FirebaseFirestore.instance
          .collection('sponsoredBanners')
          .doc(bannerId)
          .update({
        'status': nextStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _message(
        nextStatus == 'active'
            ? 'Advertisement activated.'
            : 'Advertisement paused.',
      );
    } catch (error) {
      _message('Could not update advertisement: $error');
    }
  }

  Future<void> _deleteBanner(
    String bannerId,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: gold),
          ),
          title: const Text(
            'Delete advertisement?',
            style: TextStyle(
              color: gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Do you want to permanently delete "$title"?',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: gold,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: darkGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('sponsoredBanners')
          .doc(bannerId)
          .delete();

      if (_editingBannerId == bannerId) {
        _resetForm();
      }

      _message('Advertisement deleted.');
    } catch (error) {
      _message('Could not delete advertisement: $error');
    }
  }

  String _dateText(dynamic value) {
    if (value is! Timestamp) return 'No date';

    final date = value.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (!AppSession.isSuperAdmin) {
      return const Center(
        child: Text(
          'Super Admin access required.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Container(
      color: darkGreen,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          40,
        ),
        children: [
          const Text(
            'Banners & Advertising',
            style: TextStyle(
              color: gold,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Create and manage sponsored advertising shown in Euro Habesha.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          _buildBannerList(),
          const SizedBox(height: 18),
          if (!_showForm)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: darkGreen,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Create New Advertisement',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          if (_showForm) ...[
            const SizedBox(height: 6),
            _buildForm(),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('sponsoredBanners').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Advertisements could not be loaded.',
            style: TextStyle(color: Colors.white70),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: gold,
            ),
          );
        }

        final docs = [...snapshot.data!.docs];

        docs.sort((a, b) {
          final aDate = a.data()['createdAt'] as Timestamp?;
          final bDate = b.data()['createdAt'] as Timestamp?;

          return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(
            aDate?.millisecondsSinceEpoch ?? 0,
          );
        });

        final activeCount = docs
            .where(
              (doc) => doc.data()['status'] == 'active',
            )
            .length;

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'No advertisements yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$activeCount Active • '
              '${docs.length - activeCount} Paused',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...docs.map(_buildBannerCard),
          ],
        );
      },
    );
  }

  Widget _buildBannerCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final title =
        (data['title'] ?? data['businessName'] ?? 'Advertisement').toString();

    final imageUrl = (data['imageUrl'] ?? '').toString();

    final promotion =
        (data['promotion'] ?? data['discountText'] ?? '').toString();

    final promoCode = (data['promoCode'] ?? '').toString();

    final status = (data['status'] ?? 'paused').toString();

    final active = status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? gold.withValues(alpha: 0.45) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              height: 125,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const SizedBox(height: 10);
              },
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active ? gold : Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        active ? 'ACTIVE' : 'PAUSED',
                        style: TextStyle(
                          color: active ? darkGreen : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (promotion.isNotEmpty || promoCode.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    [
                      if (promotion.isNotEmpty) promotion,
                      if (promoCode.isNotEmpty) 'Code $promoCode',
                    ].join(' • '),
                    style: const TextStyle(
                      color: gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${_dateText(data['startsAt'])} → '
                  '${_dateText(data['endsAt'])}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _smallAction(
                      icon: Icons.edit_outlined,
                      text: 'Edit',
                      onPressed: () => _startEdit(doc),
                    ),
                    _smallAction(
                      icon: active
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      text: active ? 'Pause' : 'Activate',
                      onPressed: () => _toggleStatus(doc.id, status),
                    ),
                    _smallAction(
                      icon: Icons.delete_outline,
                      text: 'Delete',
                      onPressed: () => _deleteBanner(doc.id, title),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallAction({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: gold,
        side: BorderSide(
          color: gold.withValues(alpha: 0.4),
        ),
      ),
      icon: Icon(icon, size: 17),
      label: Text(text),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF031A10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gold.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isEditing ? 'Edit Advertisement' : 'Create Advertisement',
                  style: const TextStyle(
                    color: gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: _resetForm,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pickBannerImage,
            child: Container(
              height: 145,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: gold.withValues(alpha: 0.35),
                ),
              ),
              child: _bannerImageFile != null
                  ? Image.file(
                      _bannerImageFile!,
                      fit: BoxFit.cover,
                    )
                  : _existingImageUrl.isNotEmpty
                      ? Image.network(
                          _existingImageUrl,
                          fit: BoxFit.cover,
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              color: gold,
                              size: 40,
                            ),
                            SizedBox(height: 7),
                            Text(
                              'Choose Banner Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          const SizedBox(height: 16),
          _field(
            'Banner Title *',
            _title,
            hint: 'Lucy Habesha Restaurant',
          ),
          _field(
            'Promotional Text',
            _body,
            maxLines: 3,
            hint: 'Describe the sponsored offer.',
          ),
          _field(
            'Promo Code',
            _promoCode,
            hint: 'HABESHA20',
          ),
          const Text(
            'Discount',
            style: TextStyle(
              color: gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cardGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: _discountPercent,
                isExpanded: true,
                dropdownColor: cardGreen,
                style: const TextStyle(
                  color: Colors.white,
                ),
                items: _presetDiscounts.map((discount) {
                  return DropdownMenuItem<double>(
                    value: discount,
                    child: Text(
                      '${discount.toInt()}% OFF',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _discountPercent = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildTargetSelector(),
          const SizedBox(height: 14),
          _field(
            'Usage Limit',
            _usageLimit,
            keyboardType: TextInputType.number,
            hint: '100',
          ),
          Row(
            children: [
              Expanded(
                child: _dateButton(
                  'Start date',
                  _startsAt,
                  _chooseStartDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateButton(
                  'End date',
                  _endsAt,
                  _chooseEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: darkGreen,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: darkGreen,
                      ),
                    )
                  : Icon(
                      _isEditing ? Icons.save_outlined : Icons.campaign,
                    ),
              label: Text(
                _saving
                    ? 'Saving...'
                    : _isEditing
                        ? 'Save Changes'
                        : 'Publish Advertisement',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Advertisement Destination',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cardGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _targetType,
              isExpanded: true,
              dropdownColor: cardGreen,
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(
                  value: 'business',
                  child: Text('Business / Restaurant'),
                ),
                DropdownMenuItem(
                  value: 'event',
                  child: Text('Event'),
                ),
                DropdownMenuItem(
                  value: 'marketplace',
                  child: Text('Marketplace'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _targetType = value;
                  _selectedTargetId = null;
                  _selectedTargetName = null;
                  _selectedTargetData = null;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildTargetItemSelector(),
      ],
    );
  }

  Widget _buildTargetItemSelector() {
    final collection = _targetType == 'event'
        ? 'events'
        : _targetType == 'marketplace'
            ? 'marketplace'
            : 'businesses';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator(
            color: gold,
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          final status =
              (doc.data()['status'] ?? 'published').toString().toLowerCase();

          return status == 'approved' ||
              status == 'published' ||
              _targetType == 'business';
        }).toList();

        final ids = docs.map((doc) => doc.id).toSet();

        final selectedValue =
            _selectedTargetId != null && ids.contains(_selectedTargetId)
                ? _selectedTargetId
                : null;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: cardGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              dropdownColor: cardGreen,
              hint: Text(
                _targetType == 'event'
                    ? 'Choose an event'
                    : _targetType == 'marketplace'
                        ? 'Choose a marketplace listing'
                        : 'Choose a business / restaurant',
                style: const TextStyle(
                  color: Colors.white54,
                ),
              ),
              style: const TextStyle(
                color: Colors.white,
              ),
              items: docs.map((doc) {
                final data = doc.data();

                final fields = data['fields'] is Map
                    ? Map<String, dynamic>.from(
                        data['fields'],
                      )
                    : <String, dynamic>{};

                final name = (fields['title'] ??
                        data['title'] ??
                        data['name'] ??
                        'Untitled')
                    .toString();

                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                final matches = docs.where((doc) => doc.id == value).toList();

                if (matches.isEmpty) return;

                final doc = matches.first;
                final rawData = doc.data();

                final fields = rawData['fields'] is Map
                    ? Map<String, dynamic>.from(
                        rawData['fields'],
                      )
                    : <String, dynamic>{};

                final name = (fields['title'] ??
                        rawData['title'] ??
                        rawData['name'] ??
                        'Untitled')
                    .toString();

                setState(() {
                  _selectedTargetId = doc.id;
                  _selectedTargetName = name;

                  _selectedTargetData = {
                    ...rawData,
                    'id': doc.id,
                  };
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _dateButton(
    String label,
    DateTime date,
    VoidCallback onPressed,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: gold.withValues(alpha: 0.4),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: gold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: gold,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
              filled: true,
              fillColor: cardGreen,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
