import 'dart:async';

import 'stripe_tools_policy.dart';
import 'business_checkout_screen.dart';
import 'l10n/app_ui.dart';
// EH_STRIPE_LIVE_UI_V1
import 'stripe_live_connection_card.dart';
import 'stripe_admin_trial_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Merchant LIVE settings. Testing tools stay on the separate admin screen.
class ProfessionalPaymentsScreen extends StatefulWidget {
  const ProfessionalPaymentsScreen({
    super.key,
    required this.businessId,
    required this.sourceCollection,
    required this.businessName,
  });

  final String businessId;
  final String sourceCollection;
  final String businessName;

  @override
  State<ProfessionalPaymentsScreen> createState() =>
      _ProfessionalPaymentsScreenState();
}

class _ProfessionalPaymentsScreenState extends State<ProfessionalPaymentsScreen>
    with WidgetsBindingObserver {
  static const Color dark = Color(0xFF061E12);
  static const Color gold = Color(0xFFFFD700);
  static const Color green = Color(0xFF004D40);

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );
  bool _saving = false;
  bool _liveChecking = false;
  bool _liveReady = false;
  String? _liveMessage;
  StreamSubscription<User?>? _authChanges;
  String? _accountUid;
  bool get _isTrialAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return showPrivateStripeTools(
      signedIn: user != null,
      anonymous: user?.isAnonymous ?? true,
      verified: user?.emailVerified ?? false,
      email: user?.email,
    );
  }

  Future<void> _openAdminTrial() async {
    if (!_isTrialAdmin) {
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const StripeAdminTrialScreen()),
    );
  }

  bool _owns(Map<String, dynamic> data, String uid) {
    for (final key in ['ownerId', 'submittedBy', 'creatorId']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value == uid;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _accountUid = FirebaseAuth.instance.currentUser?.uid;
    _authChanges = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _accountUid) return;
      setState(() {
        _accountUid = user?.uid;
        _liveReady = false;
        _liveChecking = false;
        _liveMessage = null;
        _saving = false;
      });
      _checkLiveStatus();
    });
    _checkLiveStatus();
  }

  @override
  void dispose() {
    _authChanges?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLiveStatus();
    }
  }

  Map<String, dynamic> get _arguments => {
    'businessId': widget.businessId,
    'sourceCollection': widget.sourceCollection,
  };

  Future<void> _checkLiveStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_liveChecking || user == null || user.isAnonymous) return;
    setState(() {
      _liveChecking = true;
      _liveReady = false;
    });
    try {
      await user.getIdToken(true);
      final response = await _functions
          .httpsCallable('getConnectLiveAccountStatus')
          .call<Map<String, dynamic>>(_arguments);
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid)
        return;
      final result = Map<String, dynamic>.from(response.data);
      setState(() {
        _liveReady =
            result['environment'] == 'live' &&
            result['eligible'] == true &&
            result['hasAccount'] == true &&
            result['chargesEnabled'] == true &&
            result['payoutsEnabled'] == true;
        _liveMessage = result['message']?.toString();
      });
    } catch (_) {
      if (mounted && FirebaseAuth.instance.currentUser?.uid == user.uid) {
        setState(() {
          _liveReady = false;
          _liveMessage = 'Vérification Stripe LIVE indisponible.';
        });
      }
    } finally {
      if (mounted && FirebaseAuth.instance.currentUser?.uid == user.uid)
        setState(() => _liveChecking = false);
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: AppText('Connexion Stripe impossible : $message')),
    );
  }

  Future<void> _saveOption(String key, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final ref = FirebaseFirestore.instance
          .collection(widget.sourceCollection)
          .doc(widget.businessId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snap = await transaction.get(ref);
        if (!snap.exists || !_owns(snap.data() ?? {}, user.uid)) {
          throw StateError('Accès non autorisé.');
        }
        transaction.update(ref, {
          'paymentSettings.$key': value,
          'paymentSettings.updatedAt': FieldValue.serverTimestamp(),
        });
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('Préférence enregistrée.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AppText('Enregistrement impossible : $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _option({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required IconData icon,
  }) {
    return Card(
      color: green,
      child: SwitchListTile(
        activeTrackColor: gold,
        activeThumbColor: dark,
        secondary: Icon(icon, color: gold),
        title: AppText(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: AppText(
          subtitle,
          style: const TextStyle(color: Colors.white70),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: dark,
        foregroundColor: gold,
        title: const AppText(
          'Paiements et versements',
          maxLines: 2,
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          if (_isTrialAdmin)
            PopupMenuButton<String>(
              tooltip: ui(context, 'Outils Stripe administrateur'),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              color: green,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'platform',
                  child: AppText(
                    'Configuration Stripe de la plateforme',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                PopupMenuItem(
                  value: 'orders',
                  child: AppText(
                    'Paiements des commandes',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                PopupMenuItem(
                  value: 'test',
                  child: AppText(
                    'Essai privé Stripe TEST',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
              onSelected: (choice) {
                if (!_isTrialAdmin) return;
                if (choice == 'test') {
                  _openAdminTrial();
                  return;
                }
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => choice == 'orders'
                        ? const OrderPaymentAdminScreen()
                        : const StripeLiveAdminScreen(),
                  ),
                );
              },
            ),
          IconButton(
            tooltip: 'Actualiser Stripe',
            onPressed: _liveChecking ? null : _checkLiveStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: AppText(
                'Connexion requise',
                style: TextStyle(color: Colors.white),
              ),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(widget.sourceCollection)
                  .doc(widget.businessId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: AppText(
                      'Profil indisponible',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: gold),
                  );
                }
                final doc = snapshot.data!;
                if (!doc.exists || !_owns(doc.data() ?? {}, user.uid)) {
                  return const Center(
                    child: AppText(
                      'Accès non autorisé',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                final data = doc.data()!;
                final raw = data['paymentSettings'];
                final settings = raw is Map
                    ? Map<String, dynamic>.from(raw)
                    : <String, dynamic>{};
                final online = settings['onlinePayment'] == true;
                final delivery = settings['cashOnDelivery'] != false;
                final pickup = settings['payAtPickup'] == true;
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.paddingOf(context).bottom + 28,
                  ),
                  children: [
                    Text(
                      widget.businessName,
                      style: const TextStyle(
                        color: gold,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StripeLiveConnectionCard(
                      businessId: widget.businessId,
                      sourceCollection: widget.sourceCollection,
                    ),
                    const SizedBox(height: 16),
                    const AppText(
                      'Moyens de paiement proposés',
                      style: TextStyle(
                        color: gold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _option(
                      title: 'Paiement en ligne (Stripe)',
                      subtitle: _liveReady
                          ? 'Compte Stripe LIVE vérifié. Les commandes en ligne '
                                'utiliseront Stripe Checkout sécurisé.'
                          : (_liveChecking
                                ? 'Vérification Stripe LIVE en cours…'
                                : (_liveMessage ??
                                      'Connectez et validez votre compte Stripe LIVE.')),
                      value: online,
                      onChanged:
                          (_saving || _liveChecking || (!_liveReady && !online))
                          ? null
                          : (value) async {
                              if (value) {
                                await _checkLiveStatus();
                                if (!_liveReady) {
                                  _showError('Compte Stripe LIVE non prêt.');
                                  return;
                                }
                              }
                              await _saveOption('onlinePayment', value);
                            },
                      icon: Icons.credit_card,
                    ),
                    _option(
                      title: 'Paiement à la livraison',
                      subtitle: 'Le client règle directement le professionnel à la livraison.',
                      value: delivery,
                      onChanged: _saving
                          ? null
                          : (value) => _saveOption('cashOnDelivery', value),
                      icon: Icons.local_shipping_outlined,
                    ),
                    _option(
                      title: 'Paiement au retrait / sur place',
                      subtitle: 'Le client règle directement le professionnel au retrait.',
                      value: pickup,
                      onChanged: _saving
                          ? null
                          : (value) => _saveOption('payAtPickup', value),
                      icon: Icons.storefront_outlined,
                    ),
                    const SizedBox(height: 12),
                    const AppText(
                      'Les commissions sont définies dans les paramètres '
                      'administrateur et calculées pour chaque commande.',
                      style: TextStyle(color: gold),
                    ),
                    const SizedBox(height: 12),
                    const AppText(
                      'Les ventes, soldes et virements Stripe seront intégrés '
                      'dans une étape distincte, après validation du lien sécurisé. '
                      'Aucun paiement réel n’est activé par cet écran.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
