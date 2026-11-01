import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'business_countries.dart';
import 'business_country_picker.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

class ProfessionalVerificationScreen extends StatefulWidget {
  final String businessId;

  final String sourceCollection;

  final String currentStatus;

  final bool isVerified;

  const ProfessionalVerificationScreen({
    super.key,
    required this.businessId,
    required this.sourceCollection,
    required this.currentStatus,
    required this.isVerified,
  });

  @override
  State<ProfessionalVerificationScreen> createState() =>
      _ProfessionalVerificationScreenState();
}

class _ProfessionalVerificationScreenState
    extends State<ProfessionalVerificationScreen> {
  static const Color darkGreen = Color(0xFF061E12);

  static const Color cardGreen = Color(0xFF0C3022);

  static const Color gold = Color(0xFFFFD700);

  final _formKey = GlobalKey<FormState>();

  final _legalName = TextEditingController();

  final _registration = TextEditingController();

  BusinessCountry? _country;
  String _countryHint = '';
  String _unknownSavedCountry = '';
  bool _detectingCountry = false;
  int _countryGeneration = 0;

  final _phone = TextEditingController();
  final _otpCode = TextEditingController();
  String? _smsVerificationId;
  int? _smsResendToken;
  bool _otpBusy = false;
  String? _otpRequestedFor;

  final _address = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  int _step = 0;

  bool _loading = true;

  bool _saving = false;

  bool _phoneVerified = false;
  String _verificationStatus = 'draft';
  String _loadError = '';
  String _loadErrorDetail = '';
  bool _isOwner = false;

  String _idUrl = '';

  String _businessDocUrl = '';

  String _addressProofUrl = '';

  String _videoUrl = ''; // Ancienne video, conservee pour compatibilite.
  String _selfieUrl = '';

  @override
  void initState() {
    super.initState();

    _loadDraft();
  }

  @override
  void dispose() {
    _legalName.dispose();

    _registration.dispose();

    _phone.dispose();
    _otpCode.dispose();

    _address.dispose();

    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> get _verificationRef =>
      FirebaseFirestore.instance
          .collection(widget.sourceCollection)
          .doc(widget.businessId)
          .collection('verification')
          .doc('professional');

  Future<void> _loadDraft() async {
    var loaded = false;
    _countryGeneration++;
    try {
      _loadError = '';
      _loadErrorDetail = '';
      final business = await FirebaseFirestore.instance
          .collection(widget.sourceCollection)
          .doc(widget.businessId)
          .get();

      final data = business.data() ?? <String, dynamic>{};
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) {
        throw StateError(
          'Connectez-vous avec un compte pour accéder à la vérification.',
        );
      }
      // Match the server: creatorId is a fallback only for legacy profiles
      // with neither ownerId nor submittedBy.
      final owner = (data['ownerId'] ?? '').toString();
      final submitter = (data['submittedBy'] ?? '').toString();
      _isOwner =
          owner == user.uid ||
          submitter == user.uid ||
          (owner.isEmpty &&
              submitter.isEmpty &&
              (data['creatorId'] ?? '').toString() == user.uid);
      if (!_isOwner) {
        throw StateError('Cet établissement ne vous appartient pas.');
      }

      final fields = Map<String, dynamic>.from(
        data['fields'] ?? <String, dynamic>{},
      );

      // Parent document permissions do not cover this subcollection.
      final draft = await _verificationRef.get();

      final v = draft.data() ?? <String, dynamic>{};

      final resolvedCountry = BusinessCountries.resolveSaved(
        draft: v,
        fields: fields,
        profile: data,
      );
      _country = resolvedCountry.country;
      _unknownSavedCountry = resolvedCountry.unknownName;
      _countryHint = _unknownSavedCountry.isNotEmpty
          ? 'Pays enregistré : $_unknownSavedCountry. Retrouvez-le dans la liste.'
          : _country != null
          ? 'Pays repris depuis votre ${resolvedCountry.source}.'
          : 'Choisissez le pays de votre établissement.';
      _legalName.text = (v['legalName'] ?? fields['title'] ?? '').toString();

      _registration.text = (v['registrationNumber'] ?? fields['siret'] ?? '')
          .toString();

      _phone.text = (v['phone'] ?? fields['phoneNumber'] ?? '').toString();

      _address.text = (v['address'] ?? fields['cityAddress'] ?? '').toString();

      // Display-only state: a client-written boolean is NOT proof of SMS OTP.
      // The server must validate an OTP before enabling submission.
      _phoneVerified =
          user.phoneNumber != null && user.phoneNumber == _phone.text.trim();
      final draftStatus = v['status']?.toString();
      final parentStatus = (data['verificationStatus'] ?? widget.currentStatus)
          .toString();
      _verificationStatus = draftStatus != null && draftStatus.isNotEmpty
          ? draftStatus
          : [
              'approved',
              'pendingApproval',
              'pending',
              'rejected',
            ].contains(parentStatus)
          ? parentStatus
          : 'draft';

      _idUrl = (v['idDocumentUrl'] ?? '').toString();

      _businessDocUrl = (v['businessDocumentUrl'] ?? '').toString();

      _addressProofUrl = (v['addressProofUrl'] ?? '').toString();

      _videoUrl = (v['verificationVideoUrl'] ?? '').toString();
      _selfieUrl = (v['verificationSelfieUrl'] ?? '').toString();
      loaded = true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _loadError = 'Accès refusé par les règles Cloud Firestore.';
        _loadErrorDetail =
            'Le document entreprise ou verification/professional est bloqué. '
            'Les règles du serveur doivent être vérifiées.';
      } else {
        _loadError =
            'Impossible de charger le dossier : ${e.message ?? e.code}';
      }
    } catch (e) {
      _loadError = 'Impossible de charger le dossier : $e';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
    if (loaded &&
        mounted &&
        _country == null &&
        _unknownSavedCountry.isEmpty &&
        _editableVerification) {
      unawaited(_detectCountry(askPermission: false));
    }
  }

  bool get _supportsCountryLocation =>
      !kIsWeb &&
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform);

  bool get _editableVerification =>
      !widget.isVerified && ['draft', 'rejected'].contains(_verificationStatus);

  Future<void> _chooseCountry() async {
    if (_saving || !_editableVerification) {
      return;
    }
    final selected = await showModalBottomSheet<BusinessCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BusinessCountryPicker(selectedCode: _country?.code),
    );
    if (!mounted || selected == null) {
      return;
    }
    setState(() {
      _countryGeneration++;
      _country = selected;
      _unknownSavedCountry = '';
      _countryHint = 'Pays choisi pour cet établissement.';
    });
  }

  Future<void> _detectCountry({required bool askPermission}) async {
    if (!_supportsCountryLocation ||
        _detectingCountry ||
        !_editableVerification) {
      return;
    }
    if (!askPermission &&
        (_country != null || _unknownSavedCountry.isNotEmpty)) {
      return;
    }
    final generation = ++_countryGeneration;
    setState(() => _detectingCountry = true);
    String? hint;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        hint =
            'La localisation est désactivée. Vous pouvez choisir le pays dans la liste.';
        return;
      }
      if (!mounted || generation != _countryGeneration) {
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && askPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        hint =
            'Choisissez un pays dans la liste ou autorisez la localisation pour le détecter.';
        return;
      }
      if (!mounted ||
          generation != _countryGeneration ||
          _step != 0 ||
          _saving) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted ||
          generation != _countryGeneration ||
          _step != 0 ||
          _saving) {
        return;
      }
      final places = await Geocoding()
          .placemarkFromCoordinates(position.latitude, position.longitude)
          .timeout(const Duration(seconds: 6));
      BusinessCountry? detected;
      for (final place in places) {
        detected =
            BusinessCountries.byCode(place.isoCountryCode) ??
            BusinessCountries.find(place.country);
        if (detected != null) {
          break;
        }
      }
      if (!mounted ||
          generation != _countryGeneration ||
          _step != 0 ||
          _saving) {
        return;
      }
      if (detected == null) {
        hint = 'Le pays n’a pas pu être détecté. Choisissez-le dans la liste.';
        return;
      }
      setState(() {
        _country = detected;
        _unknownSavedCountry = '';
        _countryHint =
            'Pays proposé depuis votre position. Vérifiez qu’il correspond à votre établissement.';
      });
    } catch (_) {
      hint =
          'Détection momentanément indisponible. Le choix manuel reste disponible.';
    } finally {
      if (mounted) {
        final message = hint;
        setState(() {
          _detectingCountry = false;
          if (generation == _countryGeneration && message != null) {
            _countryHint = message;
          }
        });
      }
    }
  }

  Widget _countryField() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FormField<String>(
        key: ValueKey('business-country-${_country?.code ?? 'none'}'),
        initialValue: _country?.code,
        validator: (value) => value == null || value.isEmpty
            ? 'Choisissez le pays de votre établissement.'
            : null,
        builder: (field) => Semantics(
          button: true,
          label: 'Pays de l’établissement : ${_country?.name ?? 'à choisir'}',
          child: InkWell(
            onTap: _saving ? null : _chooseCountry,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Pays de l’établissement',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.public, color: gold),
                suffixIcon: const Icon(Icons.expand_more, color: gold),
                errorText: field.errorText,
                errorMaxLines: 3,
                errorStyle: const TextStyle(color: Color(0xFFFFB4AB)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: gold),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: darkGreen,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
              ),
              child: Text(
                _country?.name ?? 'Choisir un pays',
                style: TextStyle(
                  color: _country == null ? Colors.white60 : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
      if (_countryHint.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 9),
          child: Text(
            _countryHint,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      if (_supportsCountryLocation)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: OutlinedButton.icon(
            onPressed: _saving || _detectingCountry
                ? null
                : () => _detectCountry(askPermission: true),
            icon: _detectingCountry
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: gold,
                    ),
                  )
                : const Icon(Icons.my_location),
            label: Text(
              _detectingCountry
                  ? 'Détection du pays…'
                  : 'Détecter depuis ma position',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: gold,
              disabledForegroundColor: Colors.white54,
              side: const BorderSide(color: gold),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      const SizedBox(height: 8),
      const Text(
        'Le pays doit correspondre à l’adresse et aux documents de l’établissement.',
        style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
      ),
    ],
  );

  Future<String> _upload(XFile file, String kind) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Utilisateur non connecté.');
    }

    final ext = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';
    final contentType = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'pdf' => 'application/pdf',
      _ => throw StateError('Format de fichier non autorisé : $ext'),
    };

    final ref = FirebaseStorage.instance.ref(
      'professional_verification/${user.uid}/${widget.businessId}/'
      '${kind}_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );

    // Works on Android, iOS and Flutter Web; use size limits in Storage rules.
    final bytes = await file.readAsBytes();
    const maxBytes = 10 * 1024 * 1024;
    if (bytes.length > maxBytes) {
      throw StateError('Fichier trop volumineux (maximum 10 Mo).');
    }
    await ref.putData(bytes, SettableMetadata(contentType: contentType));

    return ref.getDownloadURL();
  }

  Future<void> _pickDocument(String kind) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1800,
      );

      if (file == null) {
        return;
      }

      setState(() => _saving = true);

      final url = await _upload(file, kind);

      setState(() {
        if (kind == 'identity') {
          _idUrl = url;
        }

        if (kind == 'business') {
          _businessDocUrl = url;
        }

        if (kind == 'address') {
          _addressProofUrl = url;
        }
      });

      await _saveDraft();
    } catch (e) {
      _message('Envoi impossible : $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickSelfie() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (file == null) {
        return;
      }
      setState(() => _saving = true);
      final url = await _upload(file, 'selfie');
      _selfieUrl = url;
      await _saveDraft();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _message('Selfie impossible : $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _saveDraft() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || !_isOwner) {
      throw StateError('Accès refusé : profil non autorisé.');
    }
    if (!_editableVerification) {
      throw StateError('Ce dossier est déjà envoyé ou approuvé.');
    }
    final country = _country;
    if (country == null) {
      throw StateError('Choisissez le pays de votre établissement.');
    }
    await _verificationRef.set({
      'ownerId': user.uid,
      'status': 'draft',
      'businessId': widget.businessId,
      'sourceCollection': widget.sourceCollection,
      'legalName': _legalName.text.trim(),
      'registrationNumber': _registration.text.trim(),
      'country': country.name,
      'countryCode': country.code,
      'phone': _phone.text.trim(),
      'address': _address.text.trim(),
      'idDocumentUrl': _idUrl,
      'businessDocumentUrl': _businessDocUrl,
      'addressProofUrl': _addressProofUrl,
      'verificationVideoUrl': _videoUrl,
      'verificationSelfieUrl': _selfieUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _verificationStatus = 'draft';
  }

  Future<void> _submit() async {
    final signedInUser = FirebaseAuth.instance.currentUser;
    if (signedInUser == null || signedInUser.isAnonymous) {
      _message('Connectez-vous avant de soumettre le dossier.');
      return;
    }
    try {
      await signedInUser.reload();
    } catch (_) {
      _message(
        'Impossible de vérifier votre session. Réessayez avec une connexion Internet.',
      );
      return;
    }
    if (!mounted) {
      return;
    }
    final refreshedUser = FirebaseAuth.instance.currentUser;
    if (refreshedUser == null || refreshedUser.uid != signedInUser.uid) {
      _message(
        'Votre session a changé. Rouvrez le dossier avec le compte propriétaire.',
      );
      return;
    }
    if (!refreshedUser.emailVerified) {
      _message('Vérifiez votre adresse e-mail avant de soumettre le dossier.');
      return;
    }
    if (!_isOwner) {
      _message('Accès refusé : établissement non autorisé.');
      return;
    }
    if (_country == null ||
        _legalName.text.trim().isEmpty ||
        _registration.text.trim().isEmpty ||
        _address.text.trim().isEmpty ||
        !(_formKey.currentState?.validate() ?? false)) {
      setState(() => _step = 0);

      return;
    }

    if (!_isPhoneLinkedToCurrentUser()) {
      _message('Le numéro de téléphone doit être vérifié avant l’envoi.');

      setState(() => _step = 1);

      return;
    }

    if (_idUrl.isEmpty || _businessDocUrl.isEmpty || _addressProofUrl.isEmpty) {
      _message('Ajoutez les trois documents demandés.');

      setState(() => _step = 2);

      return;
    }

    if (_selfieUrl.isEmpty) {
      _message('Ajoutez un selfie de vérification.');

      setState(() => _step = 3);

      return;
    }

    setState(() => _saving = true);

    try {
      await _saveDraft();
      // Refresh trusted email and linked-phone claims before the final write.
      await refreshedUser.getIdToken(true);
      if (FirebaseAuth.instance.currentUser?.uid != refreshedUser.uid) {
        throw StateError('Votre session a changé.');
      }
      await _verificationRef.set({
        'status': 'pendingApproval',
        'submittedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Parent verificationStatus is admin-only under current Firestore rules.
      // The admin reads the verification/professional subdocument.

      if (!mounted) {
        return;
      }

      _message('Dossier envoyé. Il est maintenant en attente de validation.');

      Navigator.pop(context);
    } catch (e) {
      _message('Impossible d’envoyer le dossier : $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _message(String text) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: darkGreen,
        body: Center(child: CircularProgressIndicator(color: gold)),
      );
    }

    if (_loadError.isNotEmpty) {
      return Scaffold(
        backgroundColor: darkGreen,
        appBar: _appBar(),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: gold, size: 44),
                const SizedBox(height: 12),
                Text(
                  _loadError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                if (_loadErrorDetail.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _loadErrorDetail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _loading = true);
                    _loadDraft();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: darkGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.isVerified || _verificationStatus == 'approved') {
      return Scaffold(
        backgroundColor: darkGreen,
        appBar: _appBar(),
        body: const Center(
          child: _StatusCard(
            icon: Icons.verified,
            title: 'Professionnel vérifié',
            subtitle:
                'Cet établissement a déjà été validé. Le badge Verified est actif.',
          ),
        ),
      );
    }

    final pending =
        _verificationStatus == 'pendingApproval' ||
        _verificationStatus == 'pending';

    return Scaffold(
      backgroundColor: darkGreen,
      appBar: _appBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _progress(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                  child: pending
                      ? const _StatusCard(
                          icon: Icons.hourglass_top,
                          title: 'Vérification en cours',
                          subtitle:
                              'Votre dossier est en attente de validation administrative.',
                        )
                      : _stepBody(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: pending ? null : _bottomBar(),
    );
  }

  AppBar _appBar() => AppBar(
    backgroundColor: darkGreen,
    foregroundColor: gold,
    elevation: 0,
    title: const Text(
      'Vérification professionnelle',
      style: TextStyle(color: gold, fontWeight: FontWeight.bold),
    ),
  );

  Widget _progress() {
    const names = ['Entreprise', 'Téléphone', 'Documents', 'Selfie', 'Envoi'];

    return Container(
      color: cardGreen,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Row(
        children: List.generate(names.length, (i) {
          final active = i <= _step;

          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 27,
                  height: 27,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? gold : darkGreen,
                    border: Border.all(color: gold.withValues(alpha: .55)),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: active ? darkGreen : gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  names[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? gold : Colors.white54,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _companyStep();

      case 1:
        return _phoneStep();

      case 2:
        return _documentsStep();

      case 3:
        return _selfieStep();

      default:
        return _reviewStep();
    }
  }

  Widget _companyStep() => _section(
    icon: Icons.storefront,
    title: 'Informations de l’établissement',
    subtitle: 'Les informations doivent correspondre aux documents officiels.',
    children: [
      _countryField(),
      const SizedBox(height: 12),
      _field(
        _legalName,
        'Nom légal / nom de l’établissement',
        Icons.business_outlined,
      ),
      _field(
        _registration,
        BusinessCountries.registrationLabel(_country),
        Icons.badge_outlined,
      ),
      _field(_address, 'Adresse professionnelle', Icons.location_on_outlined),
    ],
  );

  bool _isPhoneLinkedToCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null &&
        user.phoneNumber != null &&
        user.phoneNumber == _phone.text.trim();
  }

  Future<void> _sendOtp() async {
    if (!_isOwner) {
      return;
    }
    if (kIsWeb) {
      _message(
        'OTP Web : parcours reCAPTCHA et liaison au compte à intégrer séparément. Testez sur Android/iOS pour le moment.',
      );
      return;
    }
    final number = _phone.text.trim();
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(number)) {
      _message(
        'Entrez le numéro au format international, par exemple +33612345678.',
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      _message('Connectez-vous à votre compte professionnel.');
      return;
    }
    if (_isPhoneLinkedToCurrentUser()) {
      setState(() => _phoneVerified = true);
      return;
    }
    setState(() {
      _otpBusy = true;
      _phoneVerified = false;
      _smsVerificationId = null;
      _otpRequestedFor = number;
    });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: number,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _smsResendToken,
        verificationCompleted: (credential) async {
          try {
            await _linkPhoneCredential(credential);
          } catch (e) {
            _message('Vérification automatique impossible : $e');
          }
        },
        verificationFailed: (e) {
          if (mounted) {
            setState(() => _otpBusy = false);
          }
          _message('SMS impossible : ${e.message ?? e.code}');
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) {
            return;
          }
          setState(() {
            _smsVerificationId = verificationId;
            _smsResendToken = resendToken;
            _otpBusy = false;
          });
          _message('Code envoyé. Saisissez-le pour vérifier votre numéro.');
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!mounted) {
            return;
          }
          setState(() {
            _smsVerificationId ??= verificationId;
            _otpBusy = false;
          });
        },
      );
    } on FirebaseAuthException catch (e) {
      _message('SMS impossible : ${e.message ?? e.code}');
      if (mounted) {
        setState(() => _otpBusy = false);
      }
    } catch (e) {
      _message('SMS impossible : $e');
      if (mounted) {
        setState(() => _otpBusy = false);
      }
    }
  }

  Future<void> _confirmOtp() async {
    final verificationId = _smsVerificationId;
    final code = _otpCode.text.trim();
    if (verificationId == null || !RegExp(r'^\d{6}$').hasMatch(code)) {
      _message('Saisissez le code SMS à 6 chiffres.');
      return;
    }
    if (_phone.text.trim() != _otpRequestedFor) {
      _message('Le numéro a changé : demandez un nouveau code.');
      return;
    }
    setState(() => _otpBusy = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );
      await _linkPhoneCredential(credential);
    } on FirebaseAuthException catch (e) {
      _message('Code refusé : ${e.message ?? e.code}');
    } catch (e) {
      _message('Vérification impossible : $e');
    } finally {
      if (mounted) {
        setState(() => _otpBusy = false);
      }
    }
  }

  Future<void> _linkPhoneCredential(PhoneAuthCredential credential) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Session expirée.');
    }
    if (_otpRequestedFor != _phone.text.trim()) {
      throw StateError('Le numéro a changé.');
    }
    // linkWithCredential preserves the existing email account and UID.
    await user.linkWithCredential(credential);
    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed?.uid != user.uid ||
        refreshed?.phoneNumber != _otpRequestedFor) {
      throw StateError('Le numéro n’est pas lié au compte connecté.');
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _phoneVerified = true;
      _smsVerificationId = null;
      _otpCode.clear();
      _otpBusy = false;
    });
    _message('Numéro vérifié et lié à votre compte.');
  }

  Widget _phoneStep() => _section(
    icon: Icons.phone_android,
    title: 'Vérification du téléphone',
    subtitle:
        'Le SMS/OTP confirme que le numéro appartient bien au professionnel.',
    children: [
      _field(
        _phone,
        'Numéro de téléphone',
        Icons.phone_outlined,
        keyboard: TextInputType.phone,
      ),
      const SizedBox(height: 10),
      _infoBox(
        _phoneVerified
            ? 'Numéro vérifié.'
            : 'Saisissez un numéro international (+33…), demandez le code puis confirmez-le. La vérification sera liée à votre compte connecté.',
        _phoneVerified ? Icons.check_circle : Icons.sms_outlined,
      ),
      if (!_phoneVerified)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: OutlinedButton.icon(
            onPressed: _otpBusy ? null : _sendOtp,
            icon: const Icon(Icons.sms_outlined),
            label: const Text('Envoyer le code SMS'),
            style: OutlinedButton.styleFrom(
              foregroundColor: gold,
              side: const BorderSide(color: gold),
            ),
          ),
        ),
      if (_smsVerificationId != null && !_phoneVerified) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _otpCode,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Code SMS à 6 chiffres',
            labelStyle: TextStyle(color: gold),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _otpBusy ? null : _confirmOtp,
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('Vérifier le code'),
          style: OutlinedButton.styleFrom(
            foregroundColor: gold,
            side: const BorderSide(color: gold),
          ),
        ),
      ],
    ],
  );

  Widget _documentsStep() => _section(
    icon: Icons.folder_copy_outlined,
    title: 'Documents professionnels',
    subtitle:
        'Ajoutez des documents lisibles. Ils seront examinés par l’administrateur.',
    children: [
      _uploadTile(
        'Pièce d’identité du responsable',
        _idUrl.isNotEmpty,
        () => _pickDocument('identity'),
      ),
      _uploadTile(
        'Document officiel d’enregistrement (${_country?.name ?? ''})',
        _businessDocUrl.isNotEmpty,
        () => _pickDocument('business'),
      ),
      _uploadTile(
        'Justificatif d’adresse ou lien avec l’établissement',
        _addressProofUrl.isNotEmpty,
        () => _pickDocument('address'),
      ),
    ],
  );

  Widget _selfieStep() => _section(
    icon: Icons.camera_alt_outlined,
    title: 'Selfie de vérification',
    subtitle:
        'Prenez une photo claire de votre visage. Aucune vidéo nécessaire.',
    children: [
      _uploadTile(
        _selfieUrl.isEmpty ? 'Prendre un selfie' : 'Selfie ajouté',
        _selfieUrl.isNotEmpty,
        _pickSelfie,
      ),
      const SizedBox(height: 12),
      _infoBox(
        'Le selfie est confidentiel. Il sert uniquement à comparer le visage avec la pièce d’identité et à examiner la demande.',
        Icons.lock_outline,
      ),
    ],
  );

  Widget _reviewStep() => _section(
    icon: Icons.fact_check_outlined,
    title: 'Vérifier et envoyer',
    subtitle:
        'Après l’envoi, l’administrateur pourra accepter ou refuser le dossier.',
    children: [
      _review('Pays', _country?.name ?? ''),
      _review('Entreprise', _legalName.text),
      _review('N° officiel', _registration.text),
      _review(
        'Téléphone',
        _phoneVerified ? '${_phone.text} • Vérifié' : _phone.text,
      ),
      _review('Pièce d’identité', _idUrl.isNotEmpty ? 'Ajoutée' : 'Manquante'),
      _review(
        'Document pro',
        _businessDocUrl.isNotEmpty ? 'Ajouté' : 'Manquant',
      ),
      _review(
        'Justificatif adresse',
        _addressProofUrl.isNotEmpty ? 'Ajouté' : 'Manquant',
      ),
      _review('Selfie', _selfieUrl.isNotEmpty ? 'Ajouté' : 'Manquant'),
    ],
  );

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold.withValues(alpha: .25)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Champ obligatoire' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: gold),
          filled: true,
          fillColor: darkGreen,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: gold.withValues(alpha: .25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: gold),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _uploadTile(
    String title,
    bool done,
    VoidCallback onTap, {
    bool video = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: done ? gold : gold.withValues(alpha: .22)),
      ),
      child: ListTile(
        onTap: _saving ? null : onTap,
        leading: Icon(
          video ? Icons.videocam_outlined : Icons.description_outlined,
          color: gold,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          done ? 'Ajouté' : 'Touchez pour ajouter',
          style: TextStyle(color: done ? gold : Colors.white54),
        ),
        trailing: Icon(
          done ? Icons.check_circle : Icons.add_circle_outline,
          color: gold,
        ),
      ),
    );
  }

  Widget _review(String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: darkGreen,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
        Flexible(
          child: Text(
            value.isEmpty ? '—' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: gold,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _infoBox(String text, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: darkGreen,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: gold.withValues(alpha: .18)),
    ),
    child: Row(
      children: [
        Icon(icon, color: gold, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
      ],
    ),
  );

  Widget _bottomBar() {
    return Container(
      color: cardGreen,
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => setState(() => _step--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: gold,
                  side: const BorderSide(color: gold),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Retour'),
              ),
            ),
          if (_step > 0) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (_step == 0 && !_formKey.currentState!.validate()) {
                        return;
                      }

                      if (_step == 4) {
                        await _submit();
                        return;
                      }
                      setState(() => _saving = true);
                      try {
                        await _saveDraft();
                        if (mounted) {
                          setState(() => _step++);
                        }
                      } catch (e) {
                        _message('Enregistrement impossible : $e');
                      } finally {
                        if (mounted) {
                          setState(() => _saving = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: darkGreen,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: darkGreen,
                      ),
                    )
                  : Text(
                      _step == 4 ? 'Envoyer pour validation' : 'Continuer',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;

  final String title;

  final String subtitle;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF061E12);

    const cardGreen = Color(0xFF0C3022);

    const gold = Color(0xFFFFD700);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold.withValues(alpha: .35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: darkGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: gold, size: 34),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: gold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
