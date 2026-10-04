import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dynamic_submission_screen.dart';

class SubmissionMenuScreen extends StatelessWidget {
  const SubmissionMenuScreen({super.key});

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  @override
  Widget build(BuildContext context) {
    final options = [
      const _SubmissionOption(
        'Request Verification',
        'Verify your personal, business, or community page',
        Icons.verified_user,
        SubmissionType.verification,
      ),
      const _SubmissionOption(
        'Register a Business / Restaurant',
        'Business profile, phone, address, and reservation setup',
        Icons.storefront,
        SubmissionType.business,
      ),
      const _SubmissionOption(
        'Register as a Professional',
        'Doctor, lawyer, accountant, translator, photographer, etc.',
        Icons.medical_services_outlined,
        SubmissionType.professional,
      ),
      const _SubmissionOption(
        'Submit a Job or Service',
        'Job or service listing with contact options',
        Icons.work,
        SubmissionType.job,
      ),
      const _SubmissionOption(
        'Submit an Event',
        'Events, tickets, performers, and information',
        Icons.event,
        SubmissionType.event,
      ),
    ];

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text(
          'Submissions & Registration',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: primaryGold),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: options.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == options.length) {
            return Card(
              color: cardGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(
                  color: primaryGold,
                  width: 1.2,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  backgroundColor: primaryGold,
                  child: Icon(
                    Icons.campaign,
                    color: primaryDarkGreen,
                  ),
                ),
                title: const Text(
                  'Request Sponsored Advertising',
                  style: TextStyle(
                    color: primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                    'Promote your business, service, product, or event',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white38,
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdvertisementRequestScreen(),
                    ),
                  );
                },
              ),
            );
          }

          final option = options[index];

          return Card(
            color: cardGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: primaryGold,
                child: Icon(
                  option.icon,
                  color: primaryDarkGreen,
                ),
              ),
              title: Text(
                option.title,
                style: const TextStyle(
                  color: primaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  option.subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white38,
                size: 16,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DynamicSubmissionScreen(
                      type: option.type,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AdvertisementRequestScreen extends StatefulWidget {
  final bool isAdminCreated;

  const AdvertisementRequestScreen({
    super.key,
    this.isAdminCreated = false,
  });

  @override
  State<AdvertisementRequestScreen> createState() =>
      _AdvertisementRequestScreenState();
}

class _AdvertisementRequestScreenState
    extends State<AdvertisementRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _businessController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _durationController = TextEditingController();
  final _promotionController = TextEditingController();
  final _promoCodeController = TextEditingController();

  // Informations du propriétaire
  final _ownerNameController = TextEditingController();
  final _ownerContactController = TextEditingController();

  String _advertisementType = 'Business';

  String? _selectedTargetId;
  String? _selectedTargetName;
  Map<String, dynamic>? _selectedTargetData;

  bool _isSubmitting = false;
  DateTime? _startDate;
  DateTime? _endDate;
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  @override
  void dispose() {
    _businessController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _durationController.dispose();
    _promotionController.dispose();
    _promoCodeController.dispose();
    _ownerNameController.dispose();
    _ownerContactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1000,
    );

    if (image == null) return;
    if (!mounted) return;
    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _selectAdvertisingDate({
    required bool startDate,
  }) async {
    final now = DateTime.now();

    final initialDate = startDate
        ? (_startDate ?? now)
        : (_endDate ??
            _startDate?.add(const Duration(days: 1)) ??
            now.add(const Duration(days: 1)));

    final firstDate = startDate ? now : (_startDate ?? now);

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 730)),
      helpText: startDate
          ? 'Select advertising start date'
          : 'Select advertising end date',
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (startDate) {
        _startDate = selected;

        if (_endDate != null && _endDate!.isBefore(selected)) {
          _endDate = null;
        }
      } else {
        _endDate = selected;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select the advertising start and end dates.',
          ),
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The end date cannot be before the start date.',
          ),
        ),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before submitting a request.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload de l'image dans Firebase Storage
      String imageUrl = '';

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();

        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('advertisement_requests/${user.uid}/$fileName');

        await storageRef.putData(
          bytes,
          SettableMetadata(
            contentType: 'image/jpeg',
          ),
        );

        imageUrl = await storageRef.getDownloadURL();
      }

      // 2. Enregistrement de la demande dans Firestore
      await FirebaseFirestore.instance.collection('advertisementRequests').add({
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'businessName': _businessController.text.trim(),
        'advertisementType': _advertisementType,

        'targetType': _advertisementType == 'Event'
            ? 'event'
            : _advertisementType == 'Marketplace'
                ? 'marketplace'
                : 'business',

        'targetId': _selectedTargetId ?? '',
        'targetName': _selectedTargetName ?? '',
        'targetData': _selectedTargetData ?? {},

        'description': _descriptionController.text.trim(),
        'budget': _budgetController.text.trim(),
        'startDate': Timestamp.fromDate(_startDate!),

        'endDate': Timestamp.fromDate(
          DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
            23,
            59,
            59,
          ),
        ),

        'durationDays': _endDate!.difference(_startDate!).inDays + 1,

        'expiresAt': Timestamp.fromDate(
          DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
            23,
            59,
            59,
          ),
        ),
        'promotion': _promotionController.text.trim(),
        'promoCode': _promoCodeController.text.trim(),
        'imageUrl': imageUrl,

        // Informations de création
        'submissionSource': widget.isAdminCreated ? 'admin' : 'user',
        'createdByUserId': user.uid,
        'createdByEmail': user.email ?? '',

        // Informations du propriétaire
        'businessOwnerName': _ownerNameController.text.trim(),
        'businessOwnerContact': _ownerContactController.text.trim(),

        // Statut
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your advertising request has been sent for admin review.',
          ),
          backgroundColor: cardGreen,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: primaryGold),
      filled: true,
      fillColor: cardGreen,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGold),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildAdvertisementTargetSelector() {
    final collection = _advertisementType == 'Event'
        ? 'events'
        : _advertisementType == 'Marketplace'
            ? 'marketplace'
            : 'businesses';

    final label = _advertisementType == 'Event'
        ? 'Choose your event'
        : _advertisementType == 'Marketplace'
            ? 'Choose your marketplace listing'
            : 'Choose your business / restaurant';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(
            color: primaryGold,
          );
        }

        if (snapshot.hasError) {
          return const Text(
            'Unable to load available destinations.',
            style: TextStyle(color: Colors.redAccent),
          );
        }

        final docs = (snapshot.data?.docs ?? []).where((doc) {
          if (_advertisementType == 'Business') {
            return true;
          }

          final status = (doc.data()['status'] ?? '').toString().toLowerCase();

          return status == 'approved' || status == 'published';
        }).toList();

        if (docs.isEmpty) {
          return Text(
            _advertisementType == 'Event'
                ? 'No approved event available.'
                : _advertisementType == 'Marketplace'
                    ? 'No approved marketplace listing available.'
                    : 'No business available.',
            style: const TextStyle(color: Colors.white70),
          );
        }

        final validIds = docs.map((doc) => doc.id).toSet();

        final selectedValue =
            _selectedTargetId != null && validIds.contains(_selectedTargetId)
                ? _selectedTargetId
                : null;

        return DropdownButtonFormField<String>(
          initialValue: selectedValue,
          isExpanded: true,
          dropdownColor: cardGreen,
          iconEnabledColor: Colors.white70,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
          decoration: _decoration(
            label,
            Icons.link,
          ),
          hint: const Text(
            'Select from your businesses',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white54,
            ),
          ),
          items: docs.map((doc) {
            final data = doc.data();

            final fields = data['fields'] is Map
                ? Map<String, dynamic>.from(data['fields'])
                : <String, dynamic>{};

            final name = (fields['title'] ??
                    data['title'] ??
                    data['name'] ??
                    data['businessName'] ??
                    'Untitled')
                .toString();

            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                name,
                maxLines: 1,
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
                ? Map<String, dynamic>.from(rawData['fields'])
                : <String, dynamic>{};

            final name = (fields['title'] ??
                    rawData['title'] ??
                    rawData['name'] ??
                    rawData['businessName'] ??
                    'Untitled')
                .toString();

            setState(() {
              _selectedTargetId = doc.id;
              _selectedTargetName = name;

              _selectedTargetData = {
                ...rawData,
                'id': doc.id,
              };

              if (_businessController.text.trim().isEmpty) {
                _businessController.text = name;
              }
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text(
          'Sponsored Advertising',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: primaryGold),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Request advertising for your business, service, product, or event.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(
                Icons.add_photo_alternate,
                color: primaryGold,
              ),
              label: Text(
                _selectedImage == null
                    ? 'Choose advertising photo'
                    : 'Change advertising photo',
                style: const TextStyle(color: primaryGold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryGold),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 12),
              FutureBuilder<Uint8List>(
                future: _selectedImage!.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          snapshot.data!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: primaryGold,
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessController,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration(
                'Business or organisation name',
                Icons.business,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            if (widget.isAdminCreated) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration(
                  'Business owner name',
                  Icons.person,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the owner name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerContactController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration(
                  'Owner WhatsApp / phone',
                  Icons.phone,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the owner contact';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _advertisementType,
              dropdownColor: cardGreen,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration(
                'Advertisement type',
                Icons.category,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Business',
                  child: Text('Business'),
                ),
                DropdownMenuItem(
                  value: 'Professional',
                  child: Text('Professional'),
                ),
                DropdownMenuItem(
                  value: 'Marketplace',
                  child: Text('Marketplace'),
                ),
                DropdownMenuItem(
                  value: 'Event',
                  child: Text('Event'),
                ),
                DropdownMenuItem(
                  value: 'Service',
                  child: Text('Service'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _advertisementType = value;
                  _selectedTargetId = null;
                  _selectedTargetName = null;
                  _selectedTargetData = null;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_advertisementType == 'Business' ||
                _advertisementType == 'Event' ||
                _advertisementType == 'Marketplace') ...[
              _buildAdvertisementTargetSelector(),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration(
                'Describe your advertisement',
                Icons.description,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration(
                'Budget (€)',
                Icons.euro,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectAdvertisingDate(startDate: true),
                    icon: const Icon(
                      Icons.calendar_today,
                      color: primaryGold,
                    ),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Start date',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_startDate),
                          style: const TextStyle(
                            color: primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      side: const BorderSide(color: primaryGold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectAdvertisingDate(startDate: false),
                    icon: const Icon(
                      Icons.event_available,
                      color: primaryGold,
                    ),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'End date',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_endDate),
                          style: const TextStyle(
                            color: primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      side: const BorderSide(color: primaryGold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _promotionController,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration(
                'Promotion (ex: -20% cette semaine)',
                Icons.local_offer,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your promotion';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _promoCodeController,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration(
                'Promo code (optional)',
                Icons.confirmation_number,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitRequest,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isSubmitting ? 'Sending...' : 'Submit Request',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGold,
                  foregroundColor: primaryDarkGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final SubmissionType type;

  const _SubmissionOption(
    this.title,
    this.subtitle,
    this.icon,
    this.type,
  );
}
