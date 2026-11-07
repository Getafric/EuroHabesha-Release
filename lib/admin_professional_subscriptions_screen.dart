import 'l10n/app_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_session.dart';
import 'professional_membership.dart';
// EH_SUBSCRIPTION_PRICE_DRAFT_V1
import 'professional_subscription_price_widgets.dart';
import 'professional_membership_badge.dart';
import 'pro_vip_subscription_screen.dart';

class AdminProfessionalSubscriptionsScreen extends StatefulWidget {
  const AdminProfessionalSubscriptionsScreen({super.key});
  @override
  State<AdminProfessionalSubscriptionsScreen> createState() =>
      _AdminProfessionalSubscriptionsScreenState();
}

class _AdminProfessionalSubscriptionsScreenState
    extends State<AdminProfessionalSubscriptionsScreen> {
  static const dark = Color(0xFF061E12);
  static const green = Color(0xFF004D40);
  static const gold = Color(0xFFFFD700);
  final _reference = FirebaseFirestore.instance
      .collection('app_settings')
      .doc('professionalSubscriptions');
  bool _loading = true;
  bool _busy = false;
  bool _display = false;
  int _silver = 1;
  int _gold = 2;
  int _vip = 4;
  int _revision = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AppSession.isSuperAdmin) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Réservé au Super Admin.';
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await _reference.get(
        const GetOptions(source: Source.server),
      );
      final settings = ProfessionalMembershipSettings.fromMap(snap.data());
      if (!settings.compatible) {
        throw StateError(
          'Réglages incompatibles. Mettez l’application à jour.',
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _display = settings.displayEnabled;
        _silver = settings.silverMonthlyPromotions;
        _gold = settings.goldMonthlyPromotions;
        _vip = settings.vipMonthlyPromotions;
        _revision = settings.revision;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chargement impossible. Vérifiez la connexion et les règles Firestore.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _message(String text) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text), backgroundColor: green));
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_busy || !AppSession.isSuperAdmin || user == null) {
      return;
    }
    if (_silver > _gold || _gold > _vip) {
      _message('Conservez des quantités progressives : Silver ≤ Gold ≤ VIP.');
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snap = await transaction.get(_reference);
        final current = ProfessionalMembershipSettings.fromMap(snap.data());
        if (!current.compatible || current.revision != _revision) {
          throw StateError(
            'Les réglages ont changé. Rechargez avant d’enregistrer.',
          );
        }
        if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
          throw StateError('La session a changé. Reconnectez-vous.');
        }
        final settings = ProfessionalMembershipSettings(
          displayEnabled: _display,
          silverMonthlyPromotions: _silver,
          goldMonthlyPromotions: _gold,
          vipMonthlyPromotions: _vip,
          revision: _revision,
        );
        transaction.set(
          _reference,
          settings.draft(
            uid: user.uid,
            timestamp: FieldValue.serverTimestamp(),
          ),
        );
      });
      if (!mounted) {
        return;
      }
      setState(() => _revision++);
      _message('Présentation enregistrée. Les ventes restent fermées.');
    } catch (error) {
      _message(
        error is StateError ? error.message.toString() : 'Enregistrement impossible. Vérifiez les autorisations et la connexion.',
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _quota(String tier, int value, ValueChanged<int> change) {
    return Card(
      color: green,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfessionalMembershipBadge(tier: tier, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tier.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const AppText(
              'Promotions incluses par mois — proposition',
              style: TextStyle(color: Colors.white70),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Diminuer',
                  onPressed: _busy || value <= 0
                      ? null
                      : () => setState(() => change(value - 1)),
                  icon: const Icon(Icons.remove_circle_outline),
                  color: gold,
                  disabledColor: Colors.white24,
                ),
                SizedBox(
                  width: 40,
                  child: AppText(
                    '$value',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 21),
                  ),
                ),
                IconButton(
                  tooltip: 'Augmenter',
                  onPressed: _busy || value >= 20
                      ? null
                      : () => setState(() => change(value + 1)),
                  icon: const Icon(Icons.add_circle_outline),
                  color: gold,
                  disabledColor: Colors.white24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: dark,
    appBar: AppBar(
      title: const AppText('Abonnements professionnels'),
      backgroundColor: dark,
      foregroundColor: gold,
      actions: [
        IconButton(
          tooltip: 'Recharger les réglages',
          onPressed: _busy || _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: gold))
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const AppText(
                'Silver · Gold · VIP',
                style: TextStyle(
                  color: gold,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const AppText(
                'Vous préparez les offres. Aucun abonnement n’est vendu ou activé par cet écran.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 16),
              Card(
                color: green,
                child: SwitchListTile(
                  value: _display,
                  activeThumbColor: gold,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _display = value),
                  title: const AppText(
                    'Afficher les formules',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const AppText(
                    'Après enregistrement, une entrée apparaît dans l’espace professionnel. '
                    'Les achats restent désactivés.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const Card(
                color: green,
                child: ListTile(
                  leading: Icon(Icons.lock_outline, color: gold),
                  title: AppText(
                    'Ouvrir les souscriptions',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: AppText(
                    'Verrouillé : produits des boutiques, vérification serveur et achats de test à configurer.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: Switch(value: false, onChanged: null),
                ),
              ),
              const SizedBox(height: 12),
              const ProfessionalSubscriptionPricesEditor(),
              const SizedBox(height: 12),
              _quota('silver', _silver, (value) => _silver = value),
              _quota('gold', _gold, (value) => _gold = value),
              _quota('vip', _vip, (value) => _vip = value),
              const SizedBox(height: 12),
              const AppText(
                'Tarifs et durée de facturation : à définir dans Google Play Console et App Store Connect. '
                'Ces quantités préparent les futures offres ; elles ne limitent pas les demandes gratuites actuelles.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: dark,
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _busy ? 'Enregistrement…' : 'Enregistrer la présentation',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const ProVipSubscriptionScreen(
                            adminPreview: true,
                          ),
                        ),
                      ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: gold,
                  side: const BorderSide(color: gold),
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.visibility_outlined),
                label: const AppText('Voir l’aperçu enregistré'),
              ),
              const SizedBox(height: 18),
              const Card(
                color: green,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: AppText(
                    'Au lancement : une formule sera liée à un établissement précis. '
                    'Une pause des nouvelles ventes ne devra pas supprimer les droits déjà payés. '
                    'Les promotions resteront soumises à validation admin. '
                    'Les badges de formule ne remplacent pas la vérification professionnelle.',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
  );
}
