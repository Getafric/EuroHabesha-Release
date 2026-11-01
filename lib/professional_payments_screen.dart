// EH_STRIPE_LIVE_UI_V1
import 'stripe_live_connection_card.dart';
import 'stripe_admin_trial_screen.dart';
import 'professional_verification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Stripe Connect TEST : aucun paiement réel n'est activé ici.
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
  bool _connecting = false;
  bool _checking = false;
  bool _hasAccount = false;
  Map<String, dynamic>? _stripeStatus;
  String? _stripeMessage;
  String? _eligibilityMessage;
  String? _reasonCode;
  bool? _eligible;

  bool get _isTrialAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user != null &&
        !user.isAnonymous &&
        user.emailVerified &&
        user.email == 'getafricshow1@gmail.com';
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
    _checkStripeStatus();
    _checkLiveStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStripeStatus();
      _checkLiveStatus();
    }
  }

  Map<String, dynamic> get _arguments => {
    'businessId': widget.businessId,
    'sourceCollection': widget.sourceCollection,
  };

  Future<void> _checkLiveStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_liveChecking || user == null) return;
    setState(() { _liveChecking = true; _liveReady = false; });
    try {
      await user.getIdToken(true);
      final response = await _functions
          .httpsCallable('getConnectLiveAccountStatus')
          .call<Map<String, dynamic>>(_arguments);
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) return;
      final result = Map<String, dynamic>.from(response.data);
      setState(() {
        _liveReady = result['environment'] == 'live' &&
            result['eligible'] == true && result['hasAccount'] == true &&
            result['chargesEnabled'] == true &&
            result['payoutsEnabled'] == true;
        _liveMessage = result['message']?.toString();
      });
    } catch (_) {
      if (mounted && FirebaseAuth.instance.currentUser?.uid == user.uid) {
        setState(() { _liveReady = false;
          _liveMessage = 'Vérification Stripe LIVE indisponible.'; });
      }
    } finally {
      if (mounted) setState(() => _liveChecking = false);
    }
  }

  Future<void> _checkStripeStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_checking || user == null) {
      return;
    }
    setState(() => _checking = true);
    try {
      await user.getIdToken(true);
      final result = await _functions
          .httpsCallable('getConnectTestAccountStatus')
          .call<Map<String, dynamic>>(_arguments);
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
        return;
      }
      setState(() {
        final data = Map<String, dynamic>.from(result.data);
        // Compatibility with the previous status endpoint until deployment.
        _eligible = data['eligible'] is bool ? data['eligible'] as bool : null;
        _reasonCode = data['reasonCode']?.toString();
        _eligibilityMessage = data['message']?.toString();
        _hasAccount = data['hasAccount'] is bool
            ? data['hasAccount'] == true
            : true;
        _stripeStatus = data;
        _stripeMessage = null;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
        return;
      }
      if (e.code == 'failed-precondition' &&
          (e.message ?? '').contains('Compte Stripe')) {
        setState(() {
          _hasAccount = false;
          _stripeStatus = null;
          _stripeMessage = null;
        });
      } else {
        setState(
          () => _stripeMessage =
              'Statut Stripe indisponible : ${e.message ?? e.code}',
        );
      }
    } catch (_) {
      if (mounted && FirebaseAuth.instance.currentUser?.uid == user.uid) {
        setState(
          () => _stripeMessage = 'Vérification indisponible. Réessayez.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _connectStripe() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_connecting || _checking || _eligible == false || user == null) {
      return;
    }
    setState(() => _connecting = true);
    try {
      // Réutilise le compte existant ; le backend est idempotent.
      await _functions
          .httpsCallable('createConnectTestAccount')
          .call<Map<String, dynamic>>(_arguments);
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
        return;
      }
      final result = await _functions
          .httpsCallable('createConnectTestOnboardingLink')
          .call<Map<String, dynamic>>(_arguments);
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
        return;
      }
      final url = result.data['url'];
      final uri = url is String ? Uri.tryParse(url) : null;
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.userInfo.isNotEmpty ||
          !(uri.host == 'stripe.com' || uri.host.endsWith('.stripe.com'))) {
        throw StateError('Lien Stripe invalide.');
      }
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw StateError('Impossible d’ouvrir Stripe.');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Terminez la vérification sur Stripe, puis revenez ici.',
            ),
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      _showError(e.message ?? e.code);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _connecting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connexion Stripe impossible : $message')),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Préférence enregistrée.')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Enregistrement impossible : $e')));
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
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final chargesEnabled = _stripeStatus?['chargesEnabled'] == true;
    final payoutsEnabled = _stripeStatus?['payoutsEnabled'] == true;
    final detailsSubmitted = _stripeStatus?['detailsSubmitted'] == true;
    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: dark,
        foregroundColor: gold,
        title: const Text('Paiements et versements'),
        actions: [
          if (_isTrialAdmin)
            IconButton(
              tooltip: 'Essai privé Stripe sans dossier professionnel',
              onPressed: _openAdminTrial,
              icon: const Icon(Icons.science_outlined),
            ),
          IconButton(
            tooltip: 'Actualiser Stripe',
            onPressed: _checking ? null : _checkStripeStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: Text(
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
                    child: Text(
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
                    child: Text(
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
                  padding: const EdgeInsets.all(20),
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
                    if (_isTrialAdmin) ...[
                      Card(
                        color: green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: gold),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Votre essai privé — Super Admin',
                                style: TextStyle(color: gold, fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text(
                                'Pour tester sans vrai restaurant ni documents : '
                                'ouvrez un compte fictif indépendant. Aucun badge '
                                'Vérifié ni paiement réel ne sera activé.',
                                style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: gold, foregroundColor: dark),
                                onPressed: _openAdminTrial,
                                icon: const Icon(Icons.science_outlined),
                                label: const Text('Essai privé Stripe TEST'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Card(
                      color: green,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stripe Connect — MODE TEST',
                              style: TextStyle(
                                color: gold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _checking
                                  ? 'Vérification du compte Stripe…'
                                  : _eligible == false
                                  ? 'Une étape est nécessaire avant Stripe'
                                  : chargesEnabled && payoutsEnabled
                                  ? 'Compte Stripe de test prêt'
                                  : _hasAccount
                                  ? detailsSubmitted
                                        ? 'Compte lié — activation en attente'
                                        : 'Compte créé — vérification à terminer'
                                  : 'Aucun compte Stripe lié',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'La connexion utilise Stripe TEST. Elle ne permet '
                              'pas encore de recevoir des paiements réels.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            if (_eligibilityMessage != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _eligibilityMessage!,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                            if ((_stripeStatus?['countryCode'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Pays du compte : ${_stripeStatus!['countryCode']}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                            if (_eligible == false &&
                                _reasonCode != 'profile_unpublished') ...[
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: gold,
                                  side: const BorderSide(color: gold),
                                ),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          ProfessionalVerificationScreen(
                                            businessId: widget.businessId,
                                            sourceCollection:
                                                widget.sourceCollection,
                                            currentStatus:
                                                (data['verificationStatus'] ??
                                                        'draft')
                                                    .toString(),
                                            isVerified:
                                                data['isVerified'] == true,
                                          ),
                                    ),
                                  );
                                  if (mounted) {
                                    await _checkStripeStatus();
                                  }
                                },
                                icon: const Icon(Icons.verified_user_outlined),
                                label: const Text(
                                  'Consulter mon dossier professionnel',
                                ),
                              ),
                            ],
                            if (_stripeMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _stripeMessage!,
                                style: const TextStyle(color: Colors.amber),
                              ),
                            ],
                            if (_hasAccount) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Paiements : ${chargesEnabled ? 'autorisés (test)' : 'en attente'}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                'Virements : ${payoutsEnabled ? 'autorisés (test)' : 'en attente'}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: gold,
                                foregroundColor: dark,
                              ),
                              onPressed:
                                  _connecting || _checking || _eligible == false
                                  ? null
                                  : _connectStripe,
                              icon: _connecting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.open_in_new),
                              label: Text(
                                _hasAccount
                                    ? 'Continuer sur Stripe'
                                    : 'Connecter mon compte Stripe',
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _checking ? null : _checkStripeStatus,
                              icon: const Icon(Icons.refresh, color: gold),
                              label: const Text(
                                'Vérifier mon statut Stripe',
                                style: TextStyle(color: gold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
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
                      onChanged: (_saving || _liveChecking ||
                              (!_liveReady && !online))
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
                      subtitle:
                          'Le client règle directement le professionnel à la livraison.',
                      value: delivery,
                      onChanged: _saving
                          ? null
                          : (value) => _saveOption('cashOnDelivery', value),
                      icon: Icons.local_shipping_outlined,
                    ),
                    _option(
                      title: 'Paiement au retrait / sur place',
                      subtitle:
                          'Le client règle directement le professionnel au retrait.',
                      value: pickup,
                      onChanged: _saving
                          ? null
                          : (value) => _saveOption('payAtPickup', value),
                      icon: Icons.storefront_outlined,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Les commissions sont définies dans les paramètres '
                      'administrateur et calculées pour chaque commande.',
                      style: TextStyle(color: gold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
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
