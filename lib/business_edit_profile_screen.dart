import 'l10n/app_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'professional_profile_sync_service.dart';
import 'table_reservation_option.dart';
import 'professional_capabilities.dart';

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
  bool _tablesEnabled = false;
  bool _appointmentsEnabled = false;
  bool _ordersEnabled = false;
  bool _contactEnabled = true;
  bool _chatEnabled = false;
  bool _profileLoaded = false;

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

      if (!mounted) return;

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

      if (supportsTableReservations(widget.sourceCollection)) {
        final layout = await _documentReference
            .collection('roomLayouts')
            .doc('main')
            .get();
        if (!mounted) return;
        final rooms = layout.data()?['rooms'];
        _tablesEnabled =
            layout.data()?['reservationsEnabled'] != false &&
            initialTableReservationOption(
              data,
              category: _categoryController.text,
              hasLayout: rooms is List && rooms.isNotEmpty,
            );
      }
      final category = _categoryController.text.toLowerCase();
      final legacyOrders =
          widget.sourceCollection == 'businessSubmissions' ||
          ['cater', 'traiteur', 'design'].any(category.contains);
      final capabilities = ProfessionalCapabilities.fromData(
        data,
        legacyOrders: legacyOrders,
        legacyChat: widget.sourceCollection == 'jobSubmissions',
      );
      _appointmentsEnabled = capabilities.appointments;
      _ordersEnabled = capabilities.orders;
      _contactEnabled = capabilities.contact;
      _chatEnabled = capabilities.chat;
      if (!mounted) return;

      setState(() {
        _profileLoaded = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AppText('Impossible de charger le profil : $e')),
      );
    }
  }

  Widget _functionSwitch(
    String title,
    String subtitle,
    bool value,
    void Function(bool) update,
  ) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: Text(
      title,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
    value: value,
    activeThumbColor: primaryGold,
    onChanged: _saving ? null : (v) => setState(() => update(v)),
  );

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

      if (supportsTableReservations(widget.sourceCollection)) {
        updates['tableReservationsEnabled'] = _tablesEnabled;
        updates['appointmentsEnabled'] = _appointmentsEnabled;
        updates['ordersEnabled'] = _ordersEnabled;
        updates['contactEnabled'] = _contactEnabled;
        updates['chatEnabled'] = _chatEnabled;
      }
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final layoutRef = _documentReference
            .collection('roomLayouts')
            .doc('main');
        final supported = supportsTableReservations(widget.sourceCollection);
        final layout = supported ? await transaction.get(layoutRef) : null;
        transaction.update(_documentReference, updates);
        if (layout != null && layout.exists) {
          transaction.update(layoutRef, {
            'reservationsEnabled': _tablesEnabled,
          });
        }
      });
      await ProfessionalProfileSyncService.syncPublishedProfile(
        sourceCollection: widget.sourceCollection,
        sourceId: widget.businessId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText('Informations professionnelles enregistrées.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText('Impossible d’enregistrer les modifications : $e'),
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

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: primaryGold),
      filled: true,
      fillColor: cardGreen,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryGold.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryGold),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
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
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(label, icon),
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
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(label, icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        title: const AppText(
          'Modifier mes informations',
          style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryGold))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
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
                        Icon(Icons.info_outline, color: primaryGold),
                        SizedBox(width: 12),
                        Expanded(
                          child: AppText(
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
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('Pays', Icons.public),
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
                  const SizedBox(height: 22),
                  if (supportsTableReservations(widget.sourceCollection))
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardGreen,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: primaryGold.withValues(alpha: .35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText(
                            'Fonctions de mon établissement',
                            style: TextStyle(
                              color: primaryGold,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const AppText(
                              'Réservation de tables',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const AppText(
                              'Recevoir des clients sur place',
                              style: TextStyle(color: Colors.white70),
                            ),
                            value: _tablesEnabled,
                            activeThumbColor: primaryGold,
                            onChanged: _saving
                                ? null
                                : (value) =>
                                      setState(() => _tablesEnabled = value),
                          ),
                          _functionSwitch(
                            'Prise de rendez-vous',
                            'Configurer vos prestations et horaires dans Gérer les rendez-vous.',
                            _appointmentsEnabled,
                            (v) => _appointmentsEnabled = v,
                          ),
                          _functionSwitch(
                            'Commandes',
                            'Proposer la commande de vos produits, repas ou prestations.',
                            _ordersEnabled,
                            (v) => _ordersEnabled = v,
                          ),
                          _functionSwitch(
                            'Coordonnées de contact',
                            'Afficher les boutons téléphone, e-mail, site et WhatsApp disponibles.',
                            _contactEnabled,
                            (v) => _contactEnabled = v,
                          ),
                          _functionSwitch(
                            'Discussion dans l’application',
                            'Permettre aux clients de vous écrire avec le bouton Discuter.',
                            _chatEnabled,
                            (v) => _chatEnabled = v,
                          ),
                          const AppText(
                            'Chaque option concerne uniquement cette fiche. '
                            'Les tables nécessitent un plan configuré ; les rendez-vous '
                            'nécessitent au moins une prestation active.',
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving || !_profileLoaded
                          ? null
                          : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        foregroundColor: primaryDarkGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
