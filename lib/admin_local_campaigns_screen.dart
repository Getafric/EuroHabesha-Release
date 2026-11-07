import 'l10n/app_ui.dart';
import 'notification_service.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_session.dart';
import 'campaign_city_catalog.dart';

class AdminLocalCampaignsScreen extends StatefulWidget {
  const AdminLocalCampaignsScreen({super.key});
  @override
  State<AdminLocalCampaignsScreen> createState() =>
      _AdminLocalCampaignsScreenState();
}

class _AdminLocalCampaignsScreenState extends State<AdminLocalCampaignsScreen> {
  static const _dark = Color(0xFF061E12), _gold = Color(0xFFFFD700);
  static const _pendingKey = 'eh_local_campaign_pending_v1';
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _business = TextEditingController();
  String _audience = 'all';
  String _city = localCampaignCities.keys.first;
  String _destination = 'nearbyRestaurants';
  int _radius = 10;
  bool _busy = false, _loading = true;
  Map<String, dynamic>? _pending;
  String _status = '';
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        _pendingKey,
      );
      if (raw != null) {
        final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        _pending = data;
        _title.text = data['title']?.toString() ?? '';
        _body.text = data['body']?.toString() ?? '';
        _business.text = data['businessId']?.toString() ?? '';
        _imageUrl = data['imageUrl']?.toString() ?? '';
        _audience = data['audience']?.toString() ?? 'all';
        _destination = data['destination']?.toString() ?? 'nearbyRestaurants';
        final city = data['city']?.toString() ?? '';
        if (localCampaignCities.containsKey(city)) {
          _city = city;
        }
        _radius = (data['radiusKm'] as num?)?.toInt() ?? 10;
        _status = 'Envoi à vérifier : reprenez la même demande pour éviter un doublon.';
      }
    } catch (_) {
      _status = 'Impossible de relire la demande locale. Vérifiez l’historique avant un nouvel envoi.';
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _business.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    if (_busy || _pending != null || !AppSession.isSuperAdmin) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null) {
        return;
      }
      final bytes = await file.readAsBytes();
      if (bytes.length < 12 || bytes.length > 8 * 1024 * 1024) {
        throw Exception('Choisissez une photo de moins de 8 Mo.');
      }
      String ext;
      String mime;
      if (bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff) {
        ext = 'jpg';
        mime = 'image/jpeg';
      } else if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4e) {
        ext = 'png';
        mime = 'image/png';
      } else if (ascii.decode(bytes.sublist(0, 4), allowInvalid: true) ==
              'RIFF' &&
          ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
        ext = 'webp';
        mime = 'image/webp';
      } else {
        throw Exception('Formats acceptés : JPEG, PNG et WebP.');
      }
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
        return;
      }
      final ref = FirebaseStorage.instance.ref(
        'announcements/${user.uid}/'
        'campaign_${DateTime.now().microsecondsSinceEpoch}.$ext',
      );
      await ref.putData(bytes, SettableMetadata(contentType: mime));
      final url = await ref.getDownloadURL();
      if (mounted) {
        setState(() => _imageUrl = url);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _status = 'Photo impossible : $error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Map<String, dynamic> _payload() {
    final point = localCampaignCities[_city]!;
    return {
      'title': _title.text.trim(),
      'body': _body.text.trim(),
      'audience': _audience,
      'city': _audience == 'all' ? '' : _city,
      'destination': _destination,
      if (_imageUrl.isNotEmpty) 'imageUrl': _imageUrl,
      if (_audience == 'radius') ...{
        'latitude': point[0],
        'longitude': point[1],
        'radiusKm': _radius,
      },
      if (_destination == 'business') 'businessId': _business.text.trim(),
    };
  }

  String _audienceLabel(Map<String, dynamic> data) {
    if (data['audience'] == 'all') {
      return 'Tous les abonnés aux offres locales';
    }
    if (data['audience'] == 'city') {
      return 'Ville choisie : ${data['city']}';
    }
    return 'Autour de ${data['city']}, rayon ${data['radiusKm']} km';
  }

  Future<void> _send({required bool test}) async {
    if (_busy || !AppSession.isSuperAdmin) {
      return;
    }
    var data = _pending ?? _payload();
    if (data['title'].toString().isEmpty || data['body'].toString().isEmpty) {
      setState(() => _status = 'Renseignez un titre et un message.');
      return;
    }
    if (!test && _pending == null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF004D40),
          title: const AppText(
            'Confirmer cet envoi ?',
            style: TextStyle(color: _gold),
          ),
          content: AppText(
            '${data['title']}\n\n${data['body']}\n\n'
            '${_audienceLabel(data)}\n\n'
            'Au clic : ${localCampaignDestinations[data['destination']]}\n'
            '${data['destination'] == 'business' ? data['businessId'] : ''}\n'
            'Une suggestion maximum par compte toutes les 24 h. '
            'Le nombre de notifications créées sera affiché dans l’historique.',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const AppText('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const AppText('Confirmer l’envoi'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) {
        return;
      }
    }
    setState(() {
      _busy = true;
      _status = '';
    });
    try {
      if (!data.containsKey('requestId')) {
        data = {
          ...data,
          'requestId': FirebaseFirestore.instance
              .collection('localCampaigns')
              .doc()
              .id,
        };
      }
      if (!test) {
        final saved = await (await SharedPreferences.getInstance()).setString(
          _pendingKey,
          jsonEncode(data),
        );
        if (!saved) {
          throw Exception('Sauvegarde de la demande impossible.');
        }
        _pending = data;
      }
      if (test) {
        await NotificationService.instance.registerCurrentToken();
      }
      final fn = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable(test ? 'testLocalCampaign' : 'createLocalCampaign');
      await fn.call<Map<String, dynamic>>(data);
      if (!test) {
        await (await SharedPreferences.getInstance()).remove(_pendingKey);
        _pending = null;
      }
      if (!mounted) {
        return;
      }
      setState(
        () => _status = test
            ? 'Test créé uniquement pour votre compte admin. Vérifiez votre téléphone.'
            : 'Campagne enregistrée. Consultez son avancement dans l’historique ci-dessous.',
      );
    } on FirebaseFunctionsException catch (error) {
      if ([
        'invalid-argument',
        'permission-denied',
        'unauthenticated',
        'failed-precondition',
        'not-found',
        'unimplemented',
      ].contains(error.code)) {
        if (!test) {
          await (await SharedPreferences.getInstance()).remove(_pendingKey);
        }
        _pending = null;
      }
      if (!mounted) {
        return;
      }
      // A timeout can occur after the server accepted the campaign.
      setState(
        () => _status =
            '${error.code} : ${error.message ?? 'Envoi non confirmé.'}'
            '${_pending == null ? '' : '\nUtilisez « Vérifier la demande » ; aucun nouvel identifiant ne sera créé.'}',
      );
    } catch (error) {
      if (mounted) {
        setState(() => _status = 'Envoi non confirmé : $error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _businessLabel(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final fields = data['fields'];
    final name = fields is Map ? fields['title'] : null;
    return '${name ?? data['name'] ?? data['title'] ?? 'Commerce'}'
        ' · ${data['location'] ?? ''}';
  }

  InputDecoration _label(String text) => InputDecoration(
    labelText: text,
    labelStyle: const TextStyle(color: _gold),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white38),
    ),
    border: const OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    if (!AppSession.isSuperAdmin) {
      return const Center(
        child: AppText(
          'Réservé au Super Admin',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _gold));
    }
    final locked = _busy || _pending != null;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/euro_habesha_logo.png',
              width: 44,
              height: 44,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'EURO ',
                      style: TextStyle(color: _gold),
                    ),
                    TextSpan(
                      text: 'HABESHA',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const AppText(
          'Campagnes et découvertes locales',
          style: TextStyle(
            color: _gold,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const AppText(
          'Les destinataires ont choisi de recevoir ces suggestions. '
          'Pour une zone ciblée, leur position partagée doit dater de moins de 7 jours. '
          'Aucun suivi GPS en arrière-plan.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _audience,
          dropdownColor: const Color(0xFF004D40),
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
          decoration: _label('Destinataires'),
          items: const [
            DropdownMenuItem(
              value: 'all',
              child: AppText('Tous les abonnés aux offres locales'),
            ),
            DropdownMenuItem(
              value: 'city',
              child: AppText('Par ville choisie'),
            ),
            DropdownMenuItem(value: 'radius', child: AppText('Zone ciblée')),
          ],
          onChanged: locked ? null : (v) => setState(() => _audience = v!),
        ),
        if (_audience != 'all') ...[
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _city,
            isExpanded: true,
            dropdownColor: const Color(0xFF004D40),
            style: const TextStyle(color: Colors.white),
            decoration: _label(
              _audience == 'radius' ? 'Centre de la zone' : 'Ville et pays',
            ),
            items: [
              for (final city in localCampaignCities.keys)
                DropdownMenuItem(value: city, child: Text(city)),
            ],
            onChanged: locked ? null : (v) => setState(() => _city = v!),
          ),
        ],
        if (_audience == 'radius') ...[
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: _radius,
            dropdownColor: const Color(0xFF004D40),
            style: const TextStyle(color: Colors.white),
            decoration: _label('Rayon'),
            items: [
              for (final n in [5, 10, 15, 25, 50])
                DropdownMenuItem(value: n, child: AppText('$n km')),
            ],
            onChanged: locked ? null : (v) => setState(() => _radius = v!),
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _title,
          enabled: !locked,
          maxLength: 90,
          style: const TextStyle(color: Colors.white),
          decoration: _label('Titre'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _body,
          enabled: !locked,
          maxLength: 300,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: _label('Message'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _destination,
          isExpanded: true,
          dropdownColor: const Color(0xFF004D40),
          style: const TextStyle(color: Colors.white),
          decoration: _label('Ouvrir au clic'),
          items: [
            for (final e in localCampaignDestinations.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: locked ? null : (v) => setState(() => _destination = v!),
        ),
        if (_destination == 'business') ...[
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('businesses')
                .where('status', whereIn: ['published', 'approved'])
                .limit(200)
                .snapshots(),
            builder: (context, snapshot) {
              final docs =
                  snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final selected = docs.any((doc) => doc.id == _business.text)
                  ? _business.text
                  : null;
              if (snapshot.hasError) {
                return const AppText(
                  'Liste des commerces indisponible.',
                  style: TextStyle(color: Colors.white70),
                );
              }
              return DropdownButtonFormField<String>(
                key: ValueKey(selected),
                initialValue: selected,
                isExpanded: true,
                dropdownColor: const Color(0xFF004D40),
                style: const TextStyle(color: Colors.white),
                decoration: _label('Commerce publié (200 premières fiches)'),
                items: [
                  for (final doc in docs)
                    DropdownMenuItem(
                      value: doc.id,
                      child: Text(_businessLabel(doc)),
                    ),
                ],
                onChanged: locked
                    ? null
                    : (v) => setState(() => _business.text = v ?? ''),
              );
            },
          ),
        ],
        const SizedBox(height: 18),
        if (_imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              _imageUrl,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const AppText(
                'Aperçu indisponible.',
                style: TextStyle(color: Colors.white60),
              ),
            ),
          ),
        TextButton.icon(
          onPressed: locked ? null : _choosePhoto,
          style: TextButton.styleFrom(foregroundColor: _gold),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const AppText('Ajouter / remplacer une photo (facultatif)'),
        ),
        if (_imageUrl.isNotEmpty)
          TextButton(
            onPressed: locked ? null : () => setState(() => _imageUrl = ''),
            child: const AppText(
              'Retirer la photo du message',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        OutlinedButton.icon(
          onPressed: locked ? null : () => _send(test: true),
          style: OutlinedButton.styleFrom(foregroundColor: _gold),
          icon: const Icon(Icons.smartphone),
          label: const AppText('Tester sur mes appareils admin'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _busy ? null : () => _send(test: false),
          style: FilledButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: _dark,
          ),
          icon: const Icon(Icons.send_outlined),
          label: Text(
            _pending != null ? 'Vérifier la demande' : 'Vérifier avant envoi',
          ),
        ),
        if (_busy) const LinearProgressIndicator(color: _gold),
        if (_status.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SelectableText(
              _status,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        const SizedBox(height: 20),
        const AppText(
          'Historique — notifications créées',
          style: TextStyle(
            color: _gold,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const AppText(
          'Ce compteur ne prouve pas la réception sur chaque téléphone.',
          style: TextStyle(color: Colors.white60),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('localCampaigns')
              .orderBy('createdAt', descending: true)
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const AppText(
                'Historique indisponible.',
                style: TextStyle(color: Colors.white60),
              );
            }
            return Column(
              children: [
                for (final doc
                    in snapshot.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      doc.data()['title']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: AppText(
                      '${const {'queued': 'En préparation', 'processing': 'Préparation en cours', 'queued_complete': 'Notifications créées', 'expired': 'Expirée'}[doc.data()['status']] ?? 'En préparation'} · '
                      '${doc.data()['queuedCount'] ?? 0} notifications créées · '
                      '${doc.data()['skippedCount'] ?? 0} comptes écartés',
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
