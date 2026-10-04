import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'professional_profile_sync_service.dart';

class BusinessEditProfileScreen extends StatefulWidget {
  final String businessId;
  final String sourceCollection;

  const BusinessEditProfileScreen({
    super.key,
    required this.businessId,
    required this.sourceCollection,
  });

  @override
  State<BusinessEditProfileScreen> createState() =>
      _BusinessEditProfileScreenState();
}

class _BusinessEditProfileScreenState extends State<BusinessEditProfileScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _categoryController = TextEditingController();

  String _country = '';
  bool _loading = true;
  bool _saving = false;

  DocumentReference<Map<String, dynamic>> get _documentReference =>
      FirebaseFirestore.instance
          .collection(widget.sourceCollection)
          .doc(widget.businessId);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final snapshot = await _documentReference.get();
      final data = snapshot.data();

      if (data == null) {
        throw Exception('Profil professionnel introuvable.');
      }

      final fields = Map<String, dynamic>.from(
        data['fields'] ?? <String, dynamic>{},
      );

      _titleController.text = fields['title']?.toString() ?? '';

      _phoneController.text = fields['phoneNumber']?.toString() ?? '';

      _cityController.text = fields['cityAddress']?.toString() ?? '';

      _descriptionController.text = fields['description']?.toString() ?? '';

      _websiteController.text = fields['websiteUrl']?.toString() ?? '';

      _country = fields['country']?.toString() ?? '';

      if (widget.sourceCollection == 'jobSubmissions') {
        _categoryController.text = fields['jobCategory']?.toString() ?? '';
      } else {
        _categoryController.text = fields['businessCategory']?.toString() ?? '';
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de charger le profil : $e',
          ),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final Map<String, dynamic> updates = {
        'fields.title': _titleController.text.trim(),
        'fields.phoneNumber': _phoneController.text.trim(),
        'fields.cityAddress': _cityController.text.trim(),
        'fields.description': _descriptionController.text.trim(),
        'fields.websiteUrl': _websiteController.text.trim(),
        'fields.country': _country.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.sourceCollection == 'jobSubmissions') {
        updates['fields.jobCategory'] = _categoryController.text.trim();
      } else {
        updates['fields.businessCategory'] = _categoryController.text.trim();
      }

      await _documentReference.update(updates);
      await ProfessionalProfileSyncService.syncPublishedProfile(
        sourceCollection: widget.sourceCollection,
        sourceId: widget.businessId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informations professionnelles enregistrées.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible d’enregistrer les modifications : $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  InputDecoration _decoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white60,
      ),
      prefixIcon: Icon(
        icon,
        color: primaryGold,
      ),
      filled: true,
      fillColor: cardGreen,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: primaryGold.withValues(alpha: 0.25),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryGold,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  Widget _requiredField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: _decoration(
        label,
        icon,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ce champ est obligatoire.';
        }

        return null;
      },
    );
  }

  Widget _optionalField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: _decoration(
        label,
        icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        title: const Text(
          'Modifier mes informations',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  40,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardGreen,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryGold.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: primaryGold,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ces informations seront utilisées '
                            'sur votre page professionnelle publique.',
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _requiredField(
                    controller: _titleController,
                    label: 'Nom / activité',
                    icon: Icons.storefront_outlined,
                  ),
                  const SizedBox(height: 14),
                  _requiredField(
                    controller: _categoryController,
                    label: 'Catégorie',
                    icon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 14),
                  _requiredField(
                    controller: _phoneController,
                    label: 'Téléphone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _requiredField(
                    controller: _cityController,
                    label: 'Ville et adresse',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: _country,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: _decoration(
                      'Pays',
                      Icons.public,
                    ),
                    onChanged: (value) {
                      _country = value;
                    },
                  ),
                  const SizedBox(height: 14),
                  _requiredField(
                    controller: _descriptionController,
                    label: 'Description',
                    icon: Icons.description_outlined,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 14),
                  _optionalField(
                    controller: _websiteController,
                    label: 'Site internet / Portfolio',
                    icon: Icons.language,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        foregroundColor: primaryDarkGreen,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryDarkGreen,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _saving
                            ? 'Enregistrement...'
                            : 'Enregistrer les modifications',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
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
