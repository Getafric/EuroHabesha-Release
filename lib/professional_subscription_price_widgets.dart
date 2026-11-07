import 'l10n/app_ui.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_session.dart';
import 'professional_subscription_prices.dart';

const _gold = Color(0xFFFFD700),
    _green = Color(0xFF004D40),
    _dark = Color(0xFF061E12);
DocumentReference<Map<String, dynamic>> _pricesReference() => FirebaseFirestore
    .instance
    .collection('app_settings')
    .doc('professionalSubscriptionPrices');

/// Preparation label only; the future store SDK must supply the checkout price.
class ProfessionalSubscriptionPricePreview extends StatelessWidget {
  const ProfessionalSubscriptionPricePreview({super.key, required this.tier});
  final String tier;
  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: _pricesReference().snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const AppText(
          'Tarif de préparation indisponible.',
          style: TextStyle(color: Colors.white70),
        );
      }
      if (!snapshot.hasData) {
        return const AppText(
          'Chargement du tarif…',
          style: TextStyle(color: Colors.white70),
        );
      }
      final prices = ProfessionalSubscriptionPrices.fromMap(
        snapshot.data!.data(),
      );
      if (!prices.compatible) {
        return const AppText(
          'Offre à vérifier par l’administrateur.',
          style: TextStyle(color: Colors.white70),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            '${subscriptionPriceText(prices.centsFor(tier))} € / ${prices.periodLabel}',
            style: const TextStyle(
              color: _gold,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AppText(
            '${prices.discountFor(tier)} % de réduction prévue sur la commission professionnelle Euro Habesha.',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const AppText(
            'Hors frais Stripe, Google Play et Apple. Offres en préparation : achats fermés. '
            'Le prix final sera confirmé par la boutique.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      );
    },
  );
}

class ProfessionalSubscriptionPricesEditor extends StatefulWidget {
  const ProfessionalSubscriptionPricesEditor({super.key});
  @override
  State<ProfessionalSubscriptionPricesEditor> createState() =>
      _ProfessionalSubscriptionPricesEditorState();
}

class _ProfessionalSubscriptionPricesEditorState
    extends State<ProfessionalSubscriptionPricesEditor> {
  final _form = GlobalKey<FormState>();
  final _silver = TextEditingController(),
      _goldPrice = TextEditingController(),
      _vip = TextEditingController();
  final _silverDiscount = TextEditingController(),
      _goldDiscount = TextEditingController(),
      _vipDiscount = TextEditingController();
  int _revision = 0;
  String _period = 'P3M';
  bool _loading = true, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _silver.dispose();
    _goldPrice.dispose();
    _vip.dispose();
    _silverDiscount.dispose();
    _goldDiscount.dispose();
    _vipDiscount.dispose();
    super.dispose();
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
      final snapshot = await _pricesReference().get(
        const GetOptions(source: Source.server),
      );
      final prices = ProfessionalSubscriptionPrices.fromMap(snapshot.data());
      if (!prices.compatible) throw StateError('Offres incompatibles.');
      if (!mounted) return;
      _silver.text = subscriptionPriceText(prices.silverCents);
      _goldPrice.text = subscriptionPriceText(prices.goldCents);
      _vip.text = subscriptionPriceText(prices.vipCents);
      _silverDiscount.text = '${prices.silverDiscountPercent}';
      _goldDiscount.text = '${prices.goldDiscountPercent}';
      _vipDiscount.text = '${prices.vipDiscountPercent}';
      setState(() {
        _revision = prices.revision;
        _period = prices.period;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chargement impossible. Vérifiez la connexion et les règles des tarifs.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_loading ||
        _busy ||
        _error != null ||
        !AppSession.isSuperAdmin ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(
            'Reconnectez-vous avec votre compte Super Admin vérifié.',
          ),
        ),
      );
      return;
    }
    final prices = ProfessionalSubscriptionPrices(
      silverCents: subscriptionPriceCents(_silver.text)!,
      goldCents: subscriptionPriceCents(_goldPrice.text)!,
      vipCents: subscriptionPriceCents(_vip.text)!,
      period: _period,
      silverDiscountPercent: subscriptionDiscountPercent(_silverDiscount.text)!,
      goldDiscountPercent: subscriptionDiscountPercent(_goldDiscount.text)!,
      vipDiscountPercent: subscriptionDiscountPercent(_vipDiscount.text)!,
      revision: _revision,
    );
    if (!prices.progressive || !prices.progressiveDiscounts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(
            'Conservez des prix et réductions progressifs : Silver ≤ Gold ≤ VIP.',
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final ref = _pricesReference(),
            snapshot = await transaction.get(_pricesReference());
        final current = ProfessionalSubscriptionPrices.fromMap(snapshot.data());
        if (!current.compatible || current.revision != prices.revision) {
          throw StateError(
            'Les tarifs ont changé. Rechargez avant d’enregistrer.',
          );
        }
        if (FirebaseAuth.instance.currentUser?.uid != user.uid ||
            !AppSession.isSuperAdmin) {
          throw StateError('La session a changé. Reconnectez-vous.');
        }
        transaction.set(
          ref,
          prices.document(
            uid: user.uid,
            timestamp: FieldValue.serverTimestamp(),
          ),
        );
      });
      if (!mounted) return;
      setState(() => _revision = prices.revision + 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(
            'Tarifs et avantages enregistrés. Les achats restent fermés.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError ? error.message.toString() : 'Enregistrement impossible. Vérifiez les règles Firestore et la connexion.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _price(String title, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextFormField(
      controller: controller,
      enabled: !_busy && !_loading && _error == null,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      maxLength: 7,
      style: const TextStyle(color: Colors.white),
      validator: (text) => subscriptionPriceCents(text ?? '') == null
          ? 'Entre 0,01 et 9 999,99 €, avec deux décimales maximum.'
          : null,
      decoration: InputDecoration(
        labelText: title,
        suffixText: '€ / ${ProfessionalSubscriptionPrices.periods[_period]}',
        labelStyle: const TextStyle(color: Colors.white70),
        suffixStyle: const TextStyle(color: _gold),
        counterText: '',
        errorMaxLines: 3,
        filled: true,
        fillColor: _dark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
  Widget _discount(String title, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: TextFormField(
      controller: controller,
      enabled: !_busy && !_loading && _error == null,
      keyboardType: TextInputType.number,
      maxLength: 3,
      style: const TextStyle(color: Colors.white),
      validator: (text) {
        final value = subscriptionDiscountPercent(text ?? '');
        return value == null || value < 0 || value > 100
            ? 'Entre 0 et 100 %.'
            : null;
      },
      decoration: InputDecoration(
        labelText: title,
        suffixText: '%',
        counterText: '',
        labelStyle: const TextStyle(color: Colors.white70),
        suffixStyle: const TextStyle(color: _gold),
        filled: true,
        fillColor: _dark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (!AppSession.isSuperAdmin) return const SizedBox.shrink();
    return Card(
      color: _green,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppText(
                'Tarifs et avantages des formules',
                style: TextStyle(
                  color: _gold,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const AppText(
                'Montants en euros pour toute la période choisie · offres en préparation.',
                style: TextStyle(color: Colors.white70),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(color: _gold),
                ),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
                TextButton(
                  onPressed: _loading || _busy ? null : _load,
                  child: const AppText('Recharger les tarifs'),
                ),
              ],
              DropdownButton<String>(
                value: _period,
                isExpanded: true,
                dropdownColor: _green,
                style: const TextStyle(color: _gold),
                items: [
                  for (final entry
                      in ProfessionalSubscriptionPrices.periods.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: AppText('Facturation prévue : ${entry.value}'),
                    ),
                ],
                onChanged: _busy || _loading || _error != null
                    ? null
                    : (value) {
                        if (value != null) setState(() => _period = value);
                      },
              ),
              _price('Silver', _silver),
              _discount('Réduction commission Silver', _silverDiscount),
              _price('Gold', _goldPrice),
              _discount('Réduction commission Gold', _goldDiscount),
              _price('VIP', _vip),
              _discount('Réduction commission VIP', _vipDiscount),
              const SizedBox(height: 12),
              const AppText(
                'Les réductions concernent uniquement la commission professionnelle Euro Habesha, hors frais Stripe, Google et Apple. '
                'Ces tarifs et avantages ne modifient pas automatiquement les boutiques ni les commandes. Aucun achat ni badge n’est activé ici.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _loading || _busy || _error != null ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _dark,
                ),
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _busy
                      ? 'Enregistrement…'
                      : 'Enregistrer les tarifs et avantages',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
