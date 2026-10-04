import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DirectAdminBannerScreen extends StatefulWidget {
  const DirectAdminBannerScreen({super.key});

  @override
  State<DirectAdminBannerScreen> createState() =>
      _DirectAdminBannerScreenState();
}

class _DirectAdminBannerScreenState extends State<DirectAdminBannerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _businessController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _promotionController = TextEditingController();
  final _promoCodeController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _usageLimitController = TextEditingController(text: '100');

  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedImage;
  bool _isSaving = false;

  String _advertisementType = 'Business';

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  @override
  void dispose() {
    _businessController.dispose();
    _descriptionController.dispose();
    _promotionController.dispose();
    _promoCodeController.dispose();
    _durationController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (image == null || !mounted) return;

    setState(() {
      _selectedImage = image;
    });
  }

  Future<String> _uploadImage(String uid) async {
    if (_selectedImage == null) return '';

    final Uint8List bytes = await _selectedImage!.readAsBytes();

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final reference = FirebaseStorage.instance
        .ref()
        .child('sponsored_banners/$uid/$fileName');

    await reference.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return reference.getDownloadURL();
  }

  Future<void> _createBanner() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please sign in first.', isError: true);
      return;
    }

    final durationDays = int.tryParse(_durationController.text.trim());

    final usageLimit = int.tryParse(_usageLimitController.text.trim());

    if (durationDays == null || durationDays <= 0) {
      _showMessage(
        'Please enter a valid duration.',
        isError: true,
      );
      return;
    }

    if (usageLimit == null || usageLimit < 0) {
      _showMessage(
        'Please enter a valid usage limit.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final imageUrl = await _uploadImage(user.uid);

      final now = Timestamp.now();

      final endDate = Timestamp.fromDate(
        DateTime.now().add(
          Duration(days: durationDays),
        ),
      );

      final bannerReference =
          FirebaseFirestore.instance.collection('sponsoredBanners').doc();

      await bannerReference.set({
        'businessName': _businessController.text.trim(),
        'advertisementType': _advertisementType,
        'description': _descriptionController.text.trim(),
        'promotion': _promotionController.text.trim(),
        'promoCode': _promoCodeController.text.trim(),
        'imageUrl': imageUrl,
        'status': 'active',
        'startsAt': now,
        'endsAt': endDate,
        'usageLimit': usageLimit,
        'claimsCount': 0,
        'createdByUserId': user.uid,
        'createdByEmail': user.email ?? '',
        'createdFrom': 'admin_direct',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage('Sponsored banner created successfully.');

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Error creating banner: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : cardGreen,
      ),
    );
  }

  InputDecoration _decoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(
        icon,
        color: primaryGold,
      ),
      filled: true,
      fillColor: cardGreen,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.white24,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: primaryGold,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text(
          'Create Sponsored Banner',
          style: TextStyle(
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
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Create a sponsored advertisement directly.',
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
                    ? 'Choose banner photo'
                    : 'Change banner photo',
                style: const TextStyle(
                  color: primaryGold,
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
            if (_selectedImage != null) ...[
              const SizedBox(height: 12),
              FutureBuilder<Uint8List>(
                future: _selectedImage!.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        snapshot.data!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    );
                  }

                  return const Center(
                    child: CircularProgressIndicator(
                      color: primaryGold,
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 18),
            TextFormField(
              controller: _businessController,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration(
                'Business name',
                Icons.business,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the business name';
                }
                return null;
              },
            ),
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
                if (value != null) {
                  setState(() {
                    _advertisementType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration(
                'Description',
                Icons.description,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _promotionController,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration(
                'Promotion',
                Icons.local_offer,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the promotion';
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration(
                'Duration in days',
                Icons.calendar_month,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter duration';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usageLimitController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration(
                'Usage limit (0 = unlimited)',
                Icons.people,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter usage limit';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _createBanner,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryDarkGreen,
                        ),
                      )
                    : const Icon(Icons.publish),
                label: Text(
                  _isSaving ? 'Creating...' : 'Create Sponsored Banner',
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
