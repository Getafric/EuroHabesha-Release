import 'l10n/app_ui.dart';
import 'admin_professional_subscriptions_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_session.dart';

/// Free launch only. Billing needs a separate verified integration before release.
class PromotionSettings {
  const PromotionSettings({
    this.requestsEnabled = true,
    this.monthlyLimit = 3,
    this.paidPromotionsEnabled = false,
    this.subscriptionsEnabled = false,
    this.version = 1,
  });

  final bool requestsEnabled;
  final int monthlyLimit;
  final bool paidPromotionsEnabled;
  final bool subscriptionsEnabled;
  final int version;

  factory PromotionSettings.fromMap(Map<String, dynamic>? data) {
    final value = data ?? <String, dynamic>{};
    return PromotionSettings(
      requestsEnabled:
          value['requestsEnabled'] == null || value['requestsEnabled'] == true,
      monthlyLimit: value['monthlyPromotionLimit'] == 4 ? 4 : 3,
      paidPromotionsEnabled:
          value['paidPromotionsEnabled'] != null &&
          value['paidPromotionsEnabled'] != false,
      subscriptionsEnabled:
          value['subscriptionsEnabled'] != null &&
          value['subscriptionsEnabled'] != false,
      version: value['schemaVersion'] is int
          ? value['schemaVersion'] as int
          : value.containsKey('schemaVersion')
          ? -1
          : 1,
    );
  }

  bool get acceptsFreeRequests =>
      version == 1 &&
      requestsEnabled &&
      !paidPromotionsEnabled &&
      !subscriptionsEnabled;

  static DocumentReference<Map<String, dynamic>> get reference =>
      FirebaseFirestore.instance.collection('app_settings').doc('advertising');
}

class PromotionSettingsScreen extends StatefulWidget {
  const PromotionSettingsScreen({super.key});
  @override
  State<PromotionSettingsScreen> createState() =>
      _PromotionSettingsScreenState();
}

class _PromotionSettingsScreenState extends State<PromotionSettingsScreen> {
  static const _dark = Color(0xFF061E12);
  static const _green = Color(0xFF004D40);
  static const _gold = Color(0xFFFFD700);
  bool _busy = false;

  Future<void> _save({bool? enabled, int? monthlyLimit}) async {
    if (_busy || !AppSession.isSuperAdmin) {
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snap = await transaction.get(PromotionSettings.reference);
        final current = PromotionSettings.fromMap(snap.data());
        if (current.version != 1 ||
            current.paidPromotionsEnabled ||
            current.subscriptionsEnabled) {
          throw StateError(
            'Mettez l’application à jour pour modifier ces réglages.',
          );
        }
        transaction.set(PromotionSettings.reference, {
          'schemaVersion': 1,
          'requestsEnabled': enabled ?? current.requestsEnabled,
          'paidPromotionsEnabled': false,
          'subscriptionsEnabled': false,
          'monthlyPromotionLimit': monthlyLimit ?? current.monthlyLimit,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedByUid': uid,
        });
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText('Réglages des promotions enregistrés.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AppText('Enregistrement impossible : $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _locked(String title, String detail) => Card(
    color: _green,
    child: ListTile(
      leading: const Icon(Icons.lock_outline, color: _gold),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(detail, style: const TextStyle(color: Colors.white70)),
      trailing: const Switch(value: false, onChanged: null),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _dark,
    appBar: AppBar(
      title: const AppText('Promotions et paiements'),
      backgroundColor: _dark,
      foregroundColor: _gold,
    ),
    body: !AppSession.isSuperAdmin
        ? const Center(
            child: AppText(
              'Réservé au Super Admin.',
              style: TextStyle(color: Colors.white),
            ),
          )
        : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: PromotionSettings.reference.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: AppText(
                      'Impossible de lire les réglages des promotions. '
                      'Vérifiez les autorisations puis réessayez.',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: _gold),
                );
              }
              final settings = PromotionSettings.fromMap(snapshot.data!.data());
              final canEdit =
                  !_busy &&
                  settings.version == 1 &&
                  !settings.paidPromotionsEnabled &&
                  !settings.subscriptionsEnabled;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const AppText(
                    'Tu décides quand ouvrir les demandes',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: _green,
                    child: SwitchListTile(
                      secondary: const Icon(
                        Icons.campaign_outlined,
                        color: _gold,
                      ),
                      title: const AppText(
                        'Demandes de promotion',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        settings.requestsEnabled
                            ? 'Actives · sans paiement'
                            : 'Nouvelles demandes suspendues',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      value: settings.requestsEnabled,
                      activeThumbColor: _gold,
                      onChanged: canEdit
                          ? (value) => _save(enabled: value)
                          : null,
                    ),
                  ),
                  const Card(
                    color: _green,
                    child: ListTile(
                      leading: Icon(Icons.verified_user_outlined, color: _gold),
                      title: AppText(
                        'Validation admin toujours requise',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: AppText(
                        'Aucune publication directe par le professionnel.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  _locked(
                    'Publicités payantes',
                    'Désactivées. Configuration et tests nécessaires avant activation.',
                  ),
                  Card(
                    color: _green,
                    child: ListTile(
                      leading: const Icon(
                        Icons.workspace_premium_outlined,
                        color: _gold,
                      ),
                      title: const AppText(
                        'Silver · Gold · VIP',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const AppText(
                        'Configurer la présentation et les avantages futurs. Achats fermés.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: _gold),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const AdminProfessionalSubscriptionsScreen(),
                        ),
                      ),
                    ),
                  ),
                  Card(
                    color: _green,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText(
                            'Ancien réglage préparatoire',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const AppText(
                            'Conservé pour compatibilité. Les trois formules se préparent dans Silver · Gold · VIP ; ce réglage ne limite pas les demandes gratuites.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            children: [3, 4]
                                .map(
                                  (limit) => ChoiceChip(
                                    label: AppText('$limit promotions'),
                                    selected: settings.monthlyLimit == limit,
                                    onSelected: canEdit
                                        ? (_) => _save(monthlyLimit: limit)
                                        : null,
                                    selectedColor: _gold,
                                    backgroundColor: _dark,
                                    labelStyle: TextStyle(
                                      color: settings.monthlyLimit == limit
                                          ? _dark
                                          : Colors.white,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Card(
                    color: _green,
                    child: ListTile(
                      leading: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: _gold,
                      ),
                      title: AppText(
                        'Moyens d’encaissement : à préparer',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: AppText(
                        'Aucun compte Stripe, PayPal ou bancaire n’est connecté '
                        'par cet écran. L’intégration publicitaire sera traitée séparément.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const AppText(
                    'La suspension concerne les nouvelles demandes. Les demandes '
                    'déjà envoyées et leurs conditions restent conservées.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(color: _gold),
                      ),
                    ),
                ],
              );
            },
          ),
  );
}
