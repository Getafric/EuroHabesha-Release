import 'notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'campaign_city_catalog.dart';

/// Separate, explicit subscription. It never disables booking notifications.
class LocalCampaignPreferencesCard extends StatefulWidget {
  const LocalCampaignPreferencesCard({super.key});
  @override
  State<LocalCampaignPreferencesCard> createState() =>
      _LocalCampaignPreferencesCardState();
}

class _LocalCampaignPreferencesCardState
    extends State<LocalCampaignPreferencesCard> {
  bool _busy = false;
  static const _gold = Color(0xFFFFD700);

  void _message(String text) {
    if (!mounted) { return; }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save(Map<String, dynamic> current,
      {bool? enabled, String? city, bool locate = false,
      bool clearLocation = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (_busy || user == null || user.isAnonymous) { return; }
    setState(() => _busy = true);
    try {
      if (enabled == true) {
        final permission = await FirebaseMessaging.instance.requestPermission();
        if (permission.authorizationStatus != AuthorizationStatus.authorized &&
            permission.authorizationStatus != AuthorizationStatus.provisional) {
          throw Exception('Autorisez les notifications dans les réglages du téléphone.');
        }
      }
      var latitude = current['latitude'];
      var longitude = current['longitude'];
      var locatedAt = current['locatedAt'];
      if (locate) {
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw Exception('Activez le GPS ou choisissez seulement une ville.');
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception('Localisation non autorisée. Le choix par ville reste possible.');
        }
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        ).timeout(const Duration(seconds: 15));
        latitude = double.parse(position.latitude.toStringAsFixed(3));
        longitude = double.parse(position.longitude.toStringAsFixed(3));
        locatedAt = FieldValue.serverTimestamp();
      }
      if (enabled == false || clearLocation) {
        latitude = null;
        longitude = null;
        locatedAt = null;
      }
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) { return; }
      if (enabled == true) { await NotificationService.instance.registerCurrentToken(); }
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) { return; }
      await FirebaseFirestore.instance.collection('localCampaignSubscriptions')
          .doc(user.uid).set({
        'enabled': enabled ?? current['enabled'] == true,
        'consentVersion': 1,
        'city': city ?? current['city']?.toString() ?? '',
        'latitude': latitude,
        'longitude': longitude,
        'locatedAt': locatedAt,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _message(enabled == false ? 'Offres locales désactivées.' : 'Préférence enregistrée.');
    } catch (error) {
      _message('Enregistrement impossible : $error');
    } finally {
      if (mounted) { setState(() => _busy = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return const ListTile(
        leading: Icon(Icons.local_offer_outlined, color: _gold),
        title: Text('Offres et découvertes locales', style: TextStyle(color: Colors.white)),
        subtitle: Text('Connectez-vous pour choisir de recevoir ces suggestions.',
            style: TextStyle(color: Colors.white60)),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('localCampaignSubscriptions')
          .doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final enabled = data['enabled'] == true;
        final storedCity = data['city']?.toString() ?? '';
        final city = localCampaignCities.containsKey(storedCity) ? storedCity : '';
        final ready = snapshot.hasData && !snapshot.hasError && !_busy;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile(
            secondary: const Icon(Icons.local_offer_outlined, color: _gold),
            title: const Text('Recevoir les offres et découvertes locales',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Suggestions Euro Habesha, au plus une par 24 h. '
                'Vous pouvez les désactiver ici. Vos réservations restent séparées.',
                style: TextStyle(color: Colors.white60)),
            activeThumbColor: _gold,
            value: enabled,
            onChanged: ready ? (value) => _save(data, enabled: value) : null,
          ),
          if (snapshot.hasError)
            const Padding(padding: EdgeInsets.all(16), child: Text(
              'Préférences momentanément indisponibles.',
              style: TextStyle(color: Colors.white70))),
          if (enabled) Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              DropdownButtonFormField<String>(
                key: ValueKey('$city:$_busy'),
                initialValue: city,
                isExpanded: true,
                dropdownColor: const Color(0xFF004D40),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Ma ville pour les suggestions',
                    labelStyle: TextStyle(color: _gold)),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Sans ville choisie')),
                  for (final name in localCampaignCities.keys)
                    DropdownMenuItem(value: name, child: Text(name)),
                ],
                onChanged: ready ? (value) => _save(data, city: value ?? '') : null,
              ),
              const SizedBox(height: 8),
              const Text('Facultatif : partager maintenant une position approximative '
                  'pour les campagnes ciblées autour de vous. Valable 7 jours, '
                  'sans suivi en arrière-plan.', style: TextStyle(color: Colors.white60)),
              TextButton.icon(
                onPressed: ready ? () => _save(data, locate: true) : null,
                icon: const Icon(Icons.my_location),
                label: Text(data['locatedAt'] == null
                    ? 'Partager ma position pour les offres' : 'Actualiser ma position partagée'),
                style: TextButton.styleFrom(foregroundColor: _gold),
              ),
              if (data['locatedAt'] != null) TextButton(
                onPressed: ready ? () => _save(data, clearLocation: true) : null,
                child: const Text('Retirer la position partagée',
                    style: TextStyle(color: Colors.white70)),
              ),
            ]),
          ),
          if (_busy) const LinearProgressIndicator(color: _gold),
        ]);
      },
    );
  }
}
