import 'l10n/app_ui.dart';

import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A private TEST account, independent of every professional establishment.
class StripeAdminTrialScreen extends StatefulWidget {
  const StripeAdminTrialScreen({super.key});

  @override
  State<StripeAdminTrialScreen> createState() => _StripeAdminTrialScreenState();
}

class _StripeAdminTrialScreenState extends State<StripeAdminTrialScreen>
    with WidgetsBindingObserver {
  static const _dark = Color(0xFF061E12);
  static const _green = Color(0xFF004D40);
  static const _gold = Color(0xFFFFD700);
  static const _countries = <String, String>{
    'FR': 'France',
    'DE': 'Allemagne',
    'CH': 'Suisse',
    'BE': 'Belgique',
    'IT': 'Italie',
    'NL': 'Pays-Bas',
    'US': 'États-Unis',
    'GB': 'Royaume-Uni',
    'AU': 'Australie',
    'AT': 'Autriche',
    'CA': 'Canada',
    'ES': 'Espagne',
  };

  final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  StreamSubscription<User?>? _authSubscription;
  String? _country;
  String? _uid;
  String? _message;
  Map<String, dynamic>? _status;
  bool _busy = false;
  int _revision = 0;

  bool get _isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user != null &&
        user.email == 'getafricshow1@gmail.com' &&
        user.emailVerified &&
        !user.isAnonymous;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) {
        return;
      }
      if (user?.uid != _uid) {
        setState(() {
          _uid = user?.uid;
          _revision++;
          _status = null;
          _message = null;
          _busy = false;
        });
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _isAdmin &&
        _country != null &&
        !_busy) {
      unawaited(_perform());
    }
  }

  bool _current(String uid, String country, int revision) =>
      mounted &&
      _isAdmin &&
      FirebaseAuth.instance.currentUser?.uid == uid &&
      _country == country &&
      _revision == revision;

  Future<void> _confirmOpen() async {
    if (_busy || !_isAdmin || _country == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _green,
        title: const AppText(
          'Ouvrir un essai fictif',
          style: TextStyle(color: _gold),
        ),
        content: AppText(
          'Pays choisi : ${_countries[_country]}.\n\n'
          'Un compte Stripe TEST indépendant sera créé ou réutilisé. '
          'Utilisez les données de test proposées par Stripe. '
          'Cet essai ne vérifie aucun établissement et ne reçoit aucun argent réel.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText('Annuler', style: TextStyle(color: _gold)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _dark,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const AppText('Continuer en TEST'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _perform(openStripe: true);
    }
  }

  Future<void> _perform({bool openStripe = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    final country = _country;
    if (_busy || !_isAdmin || user == null || country == null) {
      return;
    }
    final uid = user.uid;
    final revision = _revision;
    final arguments = <String, dynamic>{
      'adminTrial': true,
      'countryCode': country,
    };
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await user.getIdToken(true);
      if (!_current(uid, country, revision)) {
        return;
      }
      if (openStripe) {
        await _functions
            .httpsCallable('createConnectTestAccount')
            .call<Map<String, dynamic>>(arguments);
        if (!_current(uid, country, revision)) {
          return;
        }
        final result = await _functions
            .httpsCallable('createConnectTestOnboardingLink')
            .call<Map<String, dynamic>>(arguments);
        if (!_current(uid, country, revision)) {
          return;
        }
        final raw = result.data['url'];
        final uri = raw is String ? Uri.tryParse(raw) : null;
        if (result.data['environment'] != 'test' ||
            result.data['adminTrial'] != true ||
            uri == null ||
            uri.scheme != 'https' ||
            uri.userInfo.isNotEmpty ||
            !(uri.host == 'stripe.com' || uri.host.endsWith('.stripe.com'))) {
          throw StateError('Lien d’essai Stripe invalide.');
        }
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened) {
          throw StateError('Impossible d’ouvrir Stripe.');
        }
        if (!_current(uid, country, revision)) {
          return;
        }
      }
      final result = await _functions
          .httpsCallable('getConnectTestAccountStatus')
          .call<Map<String, dynamic>>(arguments);
      if (!_current(uid, country, revision)) {
        return;
      }
      if (result.data['environment'] != 'test' ||
          result.data['adminTrial'] != true ||
          result.data['countryCode'] != country) {
        throw StateError('Le serveur n’a pas confirmé le mode d’essai privé.');
      }
      setState(() {
        _status = Map<String, dynamic>.from(result.data);
        if (openStripe) {
          _message =
              'Terminez le formulaire TEST chez Stripe, puis revenez '
              'ici et appuyez sur Actualiser.';
        }
      });
    } on FirebaseFunctionsException catch (error) {
      if (_current(uid, country, revision)) {
        setState(
          () => _message = error.message ?? 'Essai Stripe indisponible.',
        );
      }
    } catch (_) {
      if (_current(uid, country, revision)) {
        setState(
          () => _message =
              'Impossible de terminer l’essai. '
              'Vérifiez votre connexion et réessayez.',
        );
      }
    } finally {
      if (_current(uid, country, revision)) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAccount = _status?['hasAccount'] == true;
    final completed = _status?['detailsSubmitted'] == true;
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        backgroundColor: _dark,
        foregroundColor: _gold,
        title: const AppText('Essai privé Stripe'),
      ),
      body: !_isAdmin
          ? const Center(
              child: AppText(
                'Réservé au compte Super Admin vérifié.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(Icons.science_outlined, color: _gold, size: 48),
                const SizedBox(height: 14),
                const AppText(
                  'COMPTE FICTIF · STRIPE TEST',
                  style: TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                const AppText(
                  'Cet essai est indépendant de vos établissements. '
                  'Aucun dossier professionnel réel, SMS Firebase ou badge '
                  'Vérifié n’est nécessaire pour cet essai privé. '
                  'Aucun paiement réel n’est activé.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _country,
                  dropdownColor: _green,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Pays de l’essai',
                    labelStyle: TextStyle(color: _gold),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _gold),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _gold, width: 2),
                    ),
                  ),
                  items: [
                    for (final entry in _countries.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) {
                          setState(() {
                            _country = value;
                            _revision++;
                            _status = null;
                            _message = null;
                          });
                        },
                ),
                const SizedBox(height: 16),
                Card(
                  color: _green,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _busy
                              ? 'Opération en cours…'
                              : _status == null
                              ? 'Choisissez un pays puis ouvrez l’essai.'
                              : !hasAccount
                              ? 'Aucun compte fictif pour ce pays.'
                              : completed
                              ? 'Formulaire de test terminé.'
                              : 'Compte fictif créé : formulaire à terminer.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasAccount) ...[
                          const SizedBox(height: 10),
                          AppText(
                            'Paiements simulés : ${_status?['chargesEnabled'] == true ? 'prêts' : 'en attente'}\n'
                            'Virements simulés : ${_status?['payoutsEnabled'] == true ? 'prêts' : 'en attente'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                        if (_message != null) ...[
                          const SizedBox(height: 12),
                          Text(_message!, style: const TextStyle(color: _gold)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: _dark,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: _busy || _country == null ? null : _confirmOpen,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(
                    hasAccount
                        ? 'Continuer mon essai Stripe'
                        : 'Ouvrir mon essai Stripe TEST',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _gold,
                    side: const BorderSide(color: _gold),
                  ),
                  onPressed: _busy || _country == null
                      ? null
                      : () => _perform(),
                  icon: const Icon(Icons.refresh),
                  label: const AppText('Actualiser mon essai'),
                ),
                const SizedBox(height: 16),
                const AppText(
                  'Dans le formulaire Stripe, utilisez les possibilités de test '
                  'prévues par Stripe. Si Stripe TEST demande un code SMS, '
                  'le code de simulation est 000000. Ce code ne concerne pas '
                  'la vérification téléphonique Firebase de l’application.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
    );
  }
}
