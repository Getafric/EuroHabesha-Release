// Euro Habesha: photos et publicites v1
import 'promotion_pause_info.dart';
import 'dart:typed_data';



import 'package:cloud_firestore/cloud_firestore.dart';



import 'package:easy_localization/easy_localization.dart';



import 'package:cloud_functions/cloud_functions.dart';
import 'promotion_photo_editor.dart';
import 'promotion_request_service.dart';
import 'promotion_settings.dart';
import 'app_session.dart';



import 'package:firebase_auth/firebase_auth.dart';



import 'package:flutter/material.dart';



import 'package:image_picker/image_picker.dart';



import 'dynamic_submission_screen.dart';







class SubmissionMenuScreen extends StatelessWidget {

  const SubmissionMenuScreen({super.key});



  static const Color primaryDarkGreen = Color(0xFF061E12);

  static const Color primaryGold = Color(0xFFFFD700);

  static const Color cardGreen = Color(0xFF004D40);



  void _openSubmission(BuildContext context, SubmissionType type) {

    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) => DynamicSubmissionScreen(type: type),

      ),

    );

  }



  Widget _actionCard({

    required BuildContext context,

    required IconData icon,

    required String title,

    required String subtitle,

    required VoidCallback onTap,

  }) {

    return Card(

      elevation: 0,

      color: cardGreen,

      margin: EdgeInsets.zero,

      shape: RoundedRectangleBorder(

        borderRadius: BorderRadius.circular(16),

        side: BorderSide(

          color: primaryGold.withValues(alpha: 0.30),

          width: 1,

        ),

      ),

      child: InkWell(

        onTap: onTap,

        borderRadius: BorderRadius.circular(16),

        child: Padding(

          padding: const EdgeInsets.all(15),

          child: Row(

            children: [

              Container(

                width: 48,

                height: 48,

                decoration: BoxDecoration(

                  color: primaryGold,

                  borderRadius: BorderRadius.circular(14),

                ),

                child: Icon(icon, color: primaryDarkGreen, size: 25),

              ),

              const SizedBox(width: 14),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      title,

                      style: const TextStyle(

                        color: primaryGold,

                        fontSize: 15,

                        fontWeight: FontWeight.w800,

                      ),

                    ),

                    const SizedBox(height: 4),

                    Text(

                      subtitle,

                      style: const TextStyle(

                        color: Colors.white70,

                        fontSize: 12,

                        height: 1.25,

                      ),

                    ),

                  ],

                ),

              ),

              const Icon(

                Icons.chevron_right_rounded,

                color: Colors.white38,

                size: 24,

              ),

            ],

          ),

        ),

      ),

    );

  }



  void _showQrMessage(BuildContext context) {

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(

          'Le scanner QR sera connecté à la fonction QR / check-in à l’étape suivante.',

        ),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: primaryDarkGreen,

      appBar: AppBar(

        elevation: 0,

        backgroundColor: primaryDarkGreen,

        iconTheme: const IconThemeData(color: primaryGold),

        title: const Text(

          'Créer & Publier',

          style: TextStyle(

            color: primaryGold,

            fontWeight: FontWeight.w800,

          ),

        ),

      ),

      body: SafeArea(

        top: false,

        child: ListView(

          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),

          children: [

            const Text(

              'Que voulez-vous faire ?',

              style: TextStyle(

                color: Colors.white,

                fontSize: 24,

                fontWeight: FontWeight.w800,

              ),

            ),

            const SizedBox(height: 6),

            const Text(

              'Choisissez une action pour publier sur Euro Habesha.',

              style: TextStyle(

                color: Colors.white60,

                fontSize: 13,

              ),

            ),

            const SizedBox(height: 20),



            _actionCard(

              context: context,

              icon: Icons.storefront_rounded,

              title: 'Ajouter un commerce ou restaurant',

              subtitle: 'Restaurant, boutique, épicerie, salon et autres établissements.',

              onTap: () => _openSubmission(

                context,

                SubmissionType.business,

              ),

            ),

            const SizedBox(height: 12),



            _actionCard(

              context: context,

              icon: Icons.work_outline_rounded,

              title: 'Publier un service ou une offre d’emploi',

              subtitle: 'Proposez un service ou publiez une opportunité professionnelle.',

              onTap: () => _openSubmission(

                context,

                SubmissionType.job,

              ),

            ),

            const SizedBox(height: 12),



            _actionCard(

              context: context,

              icon: Icons.event_available_rounded,

              title: 'Créer un événement',

              subtitle: 'Concert, soirée, rencontre, conférence ou événement communautaire.',

              onTap: () => _openSubmission(

                context,

                SubmissionType.event,

              ),

            ),

            const SizedBox(height: 12),



            _actionCard(

              context: context,

              icon: Icons.campaign_rounded,

              title: 'Faire une publicité sponsorisée',

              subtitle: 'Promouvez un commerce, un événement, un service ou une offre.',

              onTap: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (_) => const AdvertisementRequestScreen(),

                  ),

                );

              },

            ),

            const SizedBox(height: 12),



            _actionCard(

              context: context,

              icon: Icons.qr_code_scanner_rounded,

              title: 'Scanner un QR code',

              subtitle: 'QR de ticket, check-in, table ou commande.',

              onTap: () => _showQrMessage(context),

            ),



            const SizedBox(height: 22),

            Container(

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(

                color: primaryGold.withValues(alpha: 0.08),

                borderRadius: BorderRadius.circular(14),

                border: Border.all(

                  color: primaryGold.withValues(alpha: 0.22),

                ),

              ),

              child: const Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Icon(

                    Icons.verified_user_outlined,

                    color: primaryGold,

                    size: 21,

                  ),

                  SizedBox(width: 10),

                  Expanded(

                    child: Text(

                      'La vérification professionnelle reste dans le profil / espace professionnel. Elle n’est pas une publication.',

                      style: TextStyle(

                        color: Colors.white70,

                        fontSize: 12,

                        height: 1.35,

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

  }

}





class AdvertisementRequestScreen extends StatefulWidget {
  const AdvertisementRequestScreen({super.key, this.isAdminCreated = false,
    this.sourceCollection, this.businessId, this.businessName,
    this.editingRequestId, this.initialData});
  final bool isAdminCreated;
  final String? sourceCollection;
  final String? businessId;
  final String? businessName;
  final String? editingRequestId;
  final Map<String, dynamic>? initialData;
  @override
  State<AdvertisementRequestScreen> createState() => _AdvertisementRequestScreenState();
}

class _AdvertisementRequestScreenState extends State<AdvertisementRequestScreen> {
  static const _dark = Color(0xFF061E12);
  static const _green = Color(0xFF004D40);
  static const _gold = Color(0xFFFFD700);
  final _formKey = GlobalKey<FormState>();
  final _business = TextEditingController();
  final _description = TextEditingController();
  final _promotion = TextEditingController();
  final _promoCode = TextEditingController();
  final _externalUrl = TextEditingController();
  final _budget = TextEditingController();
  final _ownerName = TextEditingController();
  final _ownerContact = TextEditingController();
  final _photo = PromotionPhotoController();
  final _picker = ImagePicker();
  late final PromotionRequestService _service;
  String _advertisementType = 'Business';
  String? _targetId;
  String? _targetName;
  DateTime? _startDate;
  DateTime? _endDate;
  Uint8List? _preview;
  Map<String, dynamic>? _pending;
  bool _busy = false;
  bool _loaded = false;
  String? _loadError;
  int _step = 0;
  bool get _bound => widget.sourceCollection != null && widget.businessId != null;
  bool get _editing => widget.editingRequestId != null;
  Map<String, dynamic> get _initial => widget.initialData ?? <String, dynamic>{};
  String get _existingImageUrl => (_initial['imageUrl'] ?? '').toString();
  bool get _hasExistingPhoto => _editing && _existingImageUrl.isNotEmpty;
  int get _revision => _initial['editRevision'] is int ? _initial['editRevision'] as int : 0;

  @override
  void initState() {
    super.initState();
    _business.text = widget.businessName ?? '';
    if (widget.sourceCollection == 'jobSubmissions') {
      _advertisementType = 'Professional';
    }
    if (_editing) {
      _business.text = (_initial['businessName'] ?? '').toString();
      _description.text = (_initial['description'] ?? '').toString();
      _promotion.text = (_initial['promotion'] ?? '').toString();
      _promoCode.text = (_initial['promoCode'] ?? '').toString();
      _externalUrl.text = (_initial['externalUrl'] ?? '').toString();
      _advertisementType = (_initial['advertisementType'] ?? 'Business').toString();
      _targetId = _initial['targetId']?.toString();
      _targetName = _initial['targetName']?.toString();
      _photo.format = (_initial['imageFormat'] ?? 'banner').toString();
      final start = _initial['startDate'];
      final end = _initial['endDate'];
      if (start is Timestamp) {
        final d = start.toDate().toLocal();
        _startDate = DateTime(d.year, d.month, d.day);
      }
      if (end is Timestamp) {
        final d = end.toDate().toLocal();
        _endDate = DateTime(d.year, d.month, d.day);
      }
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _service = PromotionRequestService(uid: uid,
      scope: _editing ? 'edit_${widget.editingRequestId}' :
        '${widget.sourceCollection ?? 'generic'}_${widget.businessId ?? 'all'}');
    _restore();
  }

  Future<void> _restore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final pending = user == null || user.isAnonymous ? null : await _service.loadPending();
      if (!mounted) {
        return;
      }
      setState(() { _pending = pending; _loaded = true; _loadError = null; });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() { _loaded = true;
        _loadError = 'Impossible de vérifier une demande enregistrée sur cet appareil.'; });
    }
  }

  @override
  void dispose() {
    for (final controller in [_business, _description, _promotion, _promoCode,
      _externalUrl, _budget, _ownerName, _ownerContact]) { controller.dispose(); }
    _photo.dispose();
    super.dispose();
  }

  void _message(String value) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _choosePhoto() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery,
        imageQuality: 88, maxWidth: 1920);
      if (image == null) {
        return;
      }
      final bytes = await image.readAsBytes();
      if (bytes.length >= 8 * 1024 * 1024) {
        throw StateError('Choisissez une photo de moins de 8 Mo.');
      }
      await _photo.load(bytes);
      if (!mounted) { _photo.dispose(); return; }
      setState(() => _preview = null);
    } catch (_) {
      _message('Impossible de préparer cette photo. Essayez une image JPEG, PNG ou WebP de moins de 8 Mo.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _date(DateTime? value) => value == null ? 'Choisir une date' :
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _selectDate(bool start) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = start ? today : (_startDate ?? today);
    var initial = (start ? _startDate : _endDate) ?? first;
    if (initial.isBefore(first)) {
      initial = first;
    }
    final result = await showDatePicker(context: context, initialDate: initial,
      firstDate: first, lastDate: today.add(const Duration(days: 730)),
      helpText: start ? 'Début de diffusion souhaité' : 'Fin de diffusion souhaitée',
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(primary: _gold, onPrimary: _dark,
          surface: _green, onSurface: Colors.white),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: _gold)),
      ), child: child!),
    );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      if (start) {
        _startDate = result;
        if (_endDate != null && _endDate!.isBefore(result)) {
          _endDate = null;
        }
      } else { _endDate = result; }
    });
  }

  Future<void> _continue() async {
    if (_step == 0) {
      if (_photo.image == null && !_hasExistingPhoto) {
        _message('La photo est obligatoire.');
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_startDate == null || _endDate == null || _endDate!.isBefore(_startDate!)) {
      _message('Choisissez les dates de début et de fin de diffusion.'); return;
    }
    setState(() => _busy = true);
    try {
      final bytes = _photo.image == null ? null : await _photo.export();
      if (!mounted) {
        return;
      }
      setState(() { _preview = bytes; _step = 2; });
    } catch (_) {
      _message('Impossible de préparer l’aperçu de la photo. Réessayez.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _send() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (_pending == null) {
        final photo = _preview;
        if ((photo == null && !_hasExistingPhoto) || _startDate == null || _endDate == null) {
          throw StateError('Revenez à l’aperçu avant d’envoyer la demande.');
        }
        final end = _endDate!;
        final payload = <String, dynamic>{
          'requestId': widget.editingRequestId ??
            FirebaseFirestore.instance.collection('advertisementRequests').doc().id,
          'businessName': _business.text.trim(), 'advertisementType': _advertisementType,
          'sourceCollection': widget.sourceCollection ?? '', 'sourceId': widget.businessId ?? '',
          'targetId': _targetId ?? '', 'promotion': _promotion.text.trim(),
          'description': _description.text.trim(), 'promoCode': _promoCode.text.trim(),
          'externalUrl': _externalUrl.text.trim(), 'imageFormat': _photo.format,
          'startMs': _startDate!.millisecondsSinceEpoch,
          'endMs': DateTime(end.year, end.month, end.day, 23, 59, 59, 999).millisecondsSinceEpoch,
          'isAdminCreated': widget.isAdminCreated,
          'businessOwnerName': _ownerName.text.trim(),
          'businessOwnerContact': _ownerContact.text.trim(), 'budget': _budget.text.trim(),
        };
        final Map<String, dynamic> frozen;
        if (_editing) {
          payload['editId'] = FirebaseFirestore.instance.collection('advertisementRequests').doc().id;
          payload['expectedRevision'] = _revision;
          frozen = await _service.prepareEdit(photo, payload,
            existingImageUrl: _existingImageUrl);
        } else {
          frozen = await _service.prepare(photo!, payload);
        }
        if (!mounted) {
          return;
        }
        setState(() => _pending = frozen);
      }
      final id = await _service.sendPending(_pending!);
      if (!mounted) {
        return;
      }
      if (_editing) {
        _message('Modifications enregistrées. La demande reste en attente de validation.');
        Navigator.of(context).pop();
        return;
      }
      _message('Demande enregistrée. Aucun paiement demandé. Validation admin nécessaire.');
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => AdvertisementRequestStatusScreen(requestId: id)));
    } on FirebaseFunctionsException catch (error) {
      if (['invalid-argument', 'permission-denied', 'unauthenticated',
          'failed-precondition', 'already-exists']
          .contains(error.code)) {
        try {
          await _service.clearPending();
          if (mounted) {
            setState(() => _pending = null);
          }
        } catch (_) { /* Keep the frozen request when confirmation is uncertain. */ }
      }
      _message(error.message ?? 'Envoi impossible. Réessayez lorsque la connexion est disponible.');
      final details = error.details;
      if (_editing && details is Map &&
          ['status-changed', 'revision-changed'].contains(details['reason']) && mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      _message(_pending != null ? 'La confirmation de l’envoi est incertaine. '
        'Utilisez « Vérifier l’envoi » : la même demande sera vérifiée.' : '$error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(labelText: label,
    labelStyle: const TextStyle(color: Colors.white70), filled: true, fillColor: _green,
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white24)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _gold)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));

  Widget _field(TextEditingController controller, String label, int limit,
      {bool isRequired = false, int lines = 1, bool readOnly = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 14), child: TextFormField(
      controller: controller, maxLength: limit, maxLines: lines, readOnly: readOnly,
      enabled: !_busy, style: const TextStyle(color: Colors.white),
      decoration: _decoration(label), validator: (value) => isRequired &&
        (value?.trim().isEmpty ?? true) ? 'Ce champ est obligatoire.' : null,
    ));

  Widget _targetSelector() {
    final collection = _advertisementType == 'Event' ? 'events' :
      _advertisementType == 'Marketplace' ? 'marketplace' : 'businesses';
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(padding: EdgeInsets.only(bottom: 14),
          child: Text('Les destinations sont momentanément indisponibles.',
            style: TextStyle(color: Colors.white70)));
        }
        if (!snapshot.hasData) {
          return const LinearProgressIndicator(color: _gold);
        }
        final docs = snapshot.data!.docs.where((doc) => ['approved', 'published', 'active']
          .contains(doc.data()['status'] ?? 'published')).toList();
        return Padding(padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(key: ValueKey('$_advertisementType-$_targetId'),
            initialValue: docs.any((d) => d.id == _targetId) ? _targetId : null,
            isExpanded: true, dropdownColor: _green,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Destination dans Euro Habesha (facultative)'),
            items: docs.map((doc) {
              final data = doc.data();
              final fields = data['fields'] is Map ? data['fields'] as Map : const {};
              final name = (fields['title'] ?? data['name'] ?? data['title'] ??
                data['businessName'] ?? 'Sans nom').toString();
              return DropdownMenuItem(value: doc.id,
                child: Text(name, overflow: TextOverflow.ellipsis));
            }).toList(),
            onChanged: _busy ? null : (id) => setState(() {
              _targetId = id;
              if (id == null) {
                return;
              }
              final data = docs.firstWhere((d) => d.id == id).data();
              final fields = data['fields'] is Map ? data['fields'] as Map : const {};
              _targetName = (fields['title'] ?? data['name'] ?? data['title'] ?? '').toString();
              if (_business.text.trim().isEmpty) {
                _business.text = _targetName ?? '';
              }
            }),
          ));
      },
    );
  }

  Widget _details() => Form(key: _formKey, child: Column(children: [
    _field(_business, 'advertising.business_name'.tr(), 150,
      isRequired: true, readOnly: _bound),
    if (!_bound && !_editing) ...[
      DropdownButtonFormField<String>(initialValue: _advertisementType,
        dropdownColor: _green, style: const TextStyle(color: Colors.white),
        decoration: _decoration('advertising.advertisement_type'.tr()),
        items: const {'Business': 'Commerce / restaurant', 'Professional': 'Professionnel',
          'Marketplace': 'Marketplace', 'Event': 'Événement', 'Service': 'Service'}
          .entries.map((entry) => DropdownMenuItem(value: entry.key,
            child: Text(entry.value))).toList(),
        onChanged: _busy ? null : (value) {
          if (value == null) {
            return;
          }
          setState(() { _advertisementType = value; _targetId = null; _targetName = null; });
        }),
      const SizedBox(height: 16),
      if (['Business', 'Marketplace', 'Event'].contains(_advertisementType)) _targetSelector(),
    ] else Padding(padding: const EdgeInsets.only(bottom: 16),
      child: Text(_editing ? 'Le type et la destination de cette demande restent conservés.' :
        'Votre page publique sera liée automatiquement à cette demande.',
        style: const TextStyle(color: Colors.white70))),
    _field(_promotion, 'Titre de la promotion *', 100, isRequired: true),
    _field(_description, 'advertising.description'.tr(), 1800, isRequired: true, lines: 4),
    _field(_promoCode, 'advertising.promo_code'.tr(), 40),
    Padding(padding: const EdgeInsets.only(bottom: 16), child: TextFormField(
      controller: _externalUrl, keyboardType: TextInputType.url, enabled: !_busy,
      style: const TextStyle(color: Colors.white), maxLength: 2048,
      decoration: _decoration('Lien externe HTTPS (facultatif)'),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) {
          return null;
        }
        final uri = Uri.tryParse(text);
        return uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
          uri.userInfo.isNotEmpty || !uri.host.contains('.') || uri.host.contains('..')
          ? 'Entrez une adresse HTTPS valide.' : null;
      },
    )),
    Wrap(spacing: 12, runSpacing: 8, children: [true, false].map((start) =>
      OutlinedButton.icon(onPressed: _busy ? null : () => _selectDate(start),
        icon: const Icon(Icons.event, color: _gold),
        label: Text('${start ? 'Début' : 'Fin'} : ${_date(start ? _startDate : _endDate)}'),
        style: OutlinedButton.styleFrom(foregroundColor: _gold,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          side: const BorderSide(color: _gold)),
      )).toList()),
    const SizedBox(height: 16),
    if (widget.isAdminCreated) ...[
      _field(_ownerName, 'advertising.owner_name'.tr(), 150, isRequired: true),
      _field(_ownerContact, 'advertising.owner_contact'.tr(), 150, isRequired: true),
      _field(_budget, 'Budget indicatif (facultatif, aucune facturation)', 40),
    ],
    const Text('Les dates sont souhaitées. La diffusion commencera après '
      'validation admin et dans la période approuvée.', style: TextStyle(color: Colors.white70)),
  ]));

  Widget _previewCard() => Card(color: _green, clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_preview != null) Image.memory(_preview!, height: 240, fit: BoxFit.contain)
      else if (_hasExistingPhoto) Image.network(_existingImageUrl, height: 240, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(20),
          child: Text('Photo momentanément indisponible.', style: TextStyle(color: Colors.white70)))),
      Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_promotion.text.trim(), style: const TextStyle(color: _gold,
            fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_business.text.trim(), style: const TextStyle(color: Colors.white,
            fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_description.text.trim(), style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Text('Du ${_date(_startDate)} au ${_date(_endDate)}',
            style: const TextStyle(color: Colors.white)),
          if (_promoCode.text.trim().isNotEmpty) Text('Code : ${_promoCode.text.trim()}',
            style: const TextStyle(color: _gold)),
          if (!_bound && _targetName != null) Text('Destination : $_targetName',
            style: const TextStyle(color: Colors.white70)),
        ])),
    ]));

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return PopScope(canPop: !_busy, child: Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(title: Text(_editing ? 'Modifier ma demande' : 'Créer une promotion'),
        backgroundColor: _dark, foregroundColor: _gold, actions: [
          IconButton(tooltip: 'Mes demandes', icon: const Icon(Icons.history),
            onPressed: _busy ? null : () => Navigator.push(context, MaterialPageRoute<void>(
              builder: (_) => AdvertisementRequestHistoryScreen(
                sourceCollection: widget.sourceCollection, sourceId: widget.businessId)))),
        ]),
      body: user == null || user.isAnonymous
        ? const Center(child: Padding(padding: EdgeInsets.all(24),
            child: Text('Connectez-vous pour envoyer une demande de promotion.',
              style: TextStyle(color: Colors.white))))
        : !_loaded ? const Center(child: CircularProgressIndicator(color: _gold))
        : _loadError != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_loadError!, style: const TextStyle(color: Colors.white)),
            TextButton(onPressed: _restore, child: const Text('Réessayer')),
          ]))
        : _pending != null ? ListView(padding: const EdgeInsets.all(20), children: [
            const Text('Vérifier l’envoi de ma demande', style: TextStyle(
              color: _gold, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text((_pending!['promotion'] ?? '').toString(),
              style: const TextStyle(color: Colors.white, fontSize: 18)),
            if (_pending!['_previewUrl'] is String) Padding(padding: const EdgeInsets.symmetric(vertical: 16),
              child: Image.network(_pending!['_previewUrl'] as String, height: 220,
                fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image, color: _gold))),
            const Text('Cette demande est conservée sur cet appareil. La vérification '
              'réutilise son identifiant pour éviter un deuxième envoi.',
              style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _busy ? null : _send,
              style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: _dark),
              child: Text(_busy ? 'Vérification en cours…' : 'Vérifier l’envoi')),
          ])
        : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: PromotionSettings.reference.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Padding(padding: EdgeInsets.all(24),
                child: Text('Les demandes de promotion sont momentanément indisponibles. '
                  'Vérifiez votre connexion et réessayez.', style: TextStyle(color: Colors.white))));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: _gold));
              }
              final settings = PromotionSettings.fromMap(snapshot.data!.data());
              if (!_editing && !settings.acceptsFreeRequests) {
                return PromotionPauseInfo(settings: settings);
              }
              return Column(children: [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(children: List.generate(3, (index) => Expanded(child: Column(children: [
                    CircleAvatar(radius: 17, backgroundColor: index <= _step ? _gold : _green,
                      child: Text('${index + 1}', style: TextStyle(
                        color: index <= _step ? _dark : Colors.white))),
                    const SizedBox(height: 4),
                    Text(['Photo', 'Offre', 'Aperçu'][index],
                      style: const TextStyle(color: Colors.white)),
                  ]))))),
                Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (_step == 0) ...[
                      const Text('1. Choisissez votre photo', style: TextStyle(color: Colors.white,
                        fontSize: 21, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Photo obligatoire de votre établissement ou de votre activité.',
                        style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      if (_photo.image != null) PromotionPhotoEditor(controller: _photo,
                        enabled: !_busy, onChanged: () => _preview = null),
                      if (_photo.image == null && _hasExistingPhoto) ...[
                        Image.network(_existingImageUrl, height: 220, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text('Photo actuelle indisponible. '
                            'Vous pouvez choisir une nouvelle photo.',
                            style: TextStyle(color: Colors.white70))),
                        const SizedBox(height: 10),
                        const Text('Photo actuelle conservée. Pour la remplacer ou la recadrer, '
                          'choisissez une nouvelle photo.', style: TextStyle(color: Colors.white70)),
                      ],
                      const SizedBox(height: 16),
                      OutlinedButton.icon(onPressed: _busy ? null : _choosePhoto,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(_photo.image == null ? 'advertising.choose_photo'.tr() :
                          'advertising.change_photo'.tr()),
                        style: OutlinedButton.styleFrom(foregroundColor: _gold,
                          side: const BorderSide(color: _gold), padding: const EdgeInsets.all(16))),
                    ] else if (_step == 1) ...[
                      const Text('2. Présentez votre offre', style: TextStyle(color: Colors.white,
                        fontSize: 21, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16), _details(),
                    ] else ...[
                      const Text('3. Vérifiez votre demande', style: TextStyle(color: Colors.white,
                        fontSize: 21, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16), _previewCard(),
                    ],
                    const SizedBox(height: 16),
                    const Card(color: _green, child: Padding(padding: EdgeInsets.all(14),
                      child: Text('Aucun paiement demandé actuellement. La publication '
                        'nécessite la validation de l’admin.', style: TextStyle(color: Colors.white70)))),
                  ]))),
                SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                  child: Row(children: [
                    if (_step > 0) ...[
                      OutlinedButton(onPressed: _busy ? null : () => setState(() => _step--),
                        style: OutlinedButton.styleFrom(foregroundColor: _gold), child: const Text('Retour')),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: ElevatedButton.icon(
                      onPressed: _busy ? null : _step == 2 ? _send : _continue,
                      style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: _dark,
                        minimumSize: const Size(0, 52)),
                      icon: Icon(_step == 2 ? Icons.send_outlined : Icons.arrow_forward),
                      label: Text(_busy ? 'Veuillez patienter…' :
                        _step == 2 ? (_editing ? 'Enregistrer les modifications' : 'Envoyer ma demande') : 'Continuer'),
                    )),
                  ]))),
              ]);
            }),
    ));
  }
}

class AdvertisementRequestHistoryScreen extends StatelessWidget {
  const AdvertisementRequestHistoryScreen({super.key, this.sourceCollection, this.sourceId, this.allRequests = false});
  final bool allRequests;
  final String? sourceCollection;
  final String? sourceId;
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(title: Text(allRequests ? 'Toutes les demandes de promotion' : 'Mes demandes de promotion'),
        backgroundColor: const Color(0xFF061E12), foregroundColor: const Color(0xFFFFD700)),
      body: uid == null ? const Center(child: Text('Connexion requise.')) :
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: (allRequests ? FirebaseFirestore.instance.collection('advertisementRequests') :
            FirebaseFirestore.instance.collection('advertisementRequests').where('userId', isEqualTo: uid)).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Impossible de charger les demandes.',
              style: TextStyle(color: Colors.white)));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
            }
            final docs = snapshot.data!.docs.where((doc) => sourceId == null ||
              (doc.data()['sourceId'] == sourceId && doc.data()['sourceCollection'] == sourceCollection)).toList()
              ..sort((a, b) {
                final x = a.data()['createdAt']; final y = b.data()['createdAt'];
                return (y is Timestamp ? y.millisecondsSinceEpoch : 0)
                  .compareTo(x is Timestamp ? x.millisecondsSinceEpoch : 0);
              });
            if (docs.isEmpty) {
              return const Center(child: Text('Aucune demande pour le moment.',
              style: TextStyle(color: Colors.white70)));
            }
            return ListView.builder(padding: const EdgeInsets.all(16), itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index]; final data = doc.data();
                return Card(color: const Color(0xFF004D40), child: ListTile(
                  leading: const Icon(Icons.campaign_outlined, color: Color(0xFFFFD700)),
                  title: Text((data['promotion'] ?? data['businessName'] ?? 'Promotion').toString(),
                    style: const TextStyle(color: Colors.white)),
                  subtitle: Text(promotionStatusLabel(data['status']),
                    style: const TextStyle(color: Colors.white70)),
                  onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                    builder: (_) => AdvertisementRequestStatusScreen(requestId: doc.id))),
                ));
              });
          }),
    );
  }
}

String promotionStatusLabel(dynamic status) => const {
  'pending': 'En attente de validation', 'approved': 'Approuvée', 'rejected': 'Refusée',
}[status?.toString()] ?? 'Statut à vérifier';

class AdvertisementRequestStatusScreen extends StatefulWidget {
  const AdvertisementRequestStatusScreen({super.key, required this.requestId});
  final String requestId;
  @override
  State<AdvertisementRequestStatusScreen> createState() => _AdvertisementRequestStatusScreenState();
}

class _AdvertisementRequestStatusScreenState extends State<AdvertisementRequestStatusScreen> {
  bool _busy = false;
  Future<void> _review(bool approved, int revision) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await PromotionRequestService.review(widget.requestId, approved: approved,
        expectedRevision: revision);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        approved ? 'Demande approuvée.' : 'Demande refusée.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Décision impossible : $error')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
  Future<void> _edit(Map<String, dynamic> data) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final source = (data['sourceCollection'] ?? '').toString();
      final sourceId = (data['sourceId'] ?? '').toString();
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => AdvertisementRequestScreen(editingRequestId: widget.requestId,
          initialData: Map<String, dynamic>.from(data),
          sourceCollection: source.isEmpty ? null : source,
          businessId: sourceId.isEmpty ? null : sourceId,
          businessName: (data['businessName'] ?? '').toString())));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF061E12),
    appBar: AppBar(title: const Text('Demande de promotion'),
      backgroundColor: const Color(0xFF061E12), foregroundColor: const Color(0xFFFFD700)),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('advertisementRequests').doc(widget.requestId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Cette demande n’est pas accessible avec ce compte.',
          style: TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
        }
        final data = snapshot.data!.data();
        if (data == null) {
          return const Center(child: Text('Demande introuvable.', style: TextStyle(color: Colors.white)));
        }
        String date(dynamic value) {
          if (value is! Timestamp) {
            return 'À vérifier';
          }
          final d = value.toDate().toLocal();
          return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
        }
        final url = (data['imageUrl'] ?? '').toString();
        final revision = data['editRevision'] is int ? data['editRevision'] as int : 0;
        final uid = FirebaseAuth.instance.currentUser?.uid;
        final owner = uid != null && data['userId'] == uid;
        return ListView(padding: const EdgeInsets.all(20), children: [
          Text(promotionStatusLabel(data['status']), style: const TextStyle(color: Color(0xFFFFD700),
            fontSize: 23, fontWeight: FontWeight.bold)),
          if (revision > 0) Padding(padding: const EdgeInsets.only(top: 12),
            child: Text('Demande modifiée · version ${revision + 1}',
              style: const TextStyle(color: Colors.white70))),
          if (owner && data['status'] == 'pending') Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton.icon(onPressed: _busy ? null : () => _edit(data),
              icon: const Icon(Icons.edit_outlined), label: const Text('Modifier ma demande'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF061E12), minimumSize: const Size(0, 52),
                padding: const EdgeInsets.all(16)))),
          const SizedBox(height: 16),
          if (url.isNotEmpty) Image.network(url, height: 260, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(20),
              child: Text('Photo momentanément indisponible.', style: TextStyle(color: Colors.white70)))),
          for (final text in [(data['businessName'] ?? '').toString(), (data['promotion'] ?? '').toString(),
            (data['description'] ?? '').toString(),
            'Du ${date(data['startDate'])} au ${date(data['endDate'])}',
            data['paymentRequired'] == true ? 'Paiement à vérifier avec l’administration.' :
              'Aucun paiement demandé pour cette demande.',
            if (data['status'] == 'approved') 'La diffusion suit les dates approuvées.',
          ]) Padding(padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16))),
          if (AppSession.isSuperAdmin && data['status'] == 'pending') Wrap(spacing: 12, children: [
            OutlinedButton(onPressed: _busy ? null : () => _review(false, revision),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white), child: const Text('Refuser')),
            ElevatedButton(onPressed: _busy ? null : () => _review(true, revision),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF061E12)), child: const Text('Approuver')),
          ]),
        ]);
      }),
  );
}
