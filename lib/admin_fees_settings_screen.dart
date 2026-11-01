// EH_STRIPE_LIVE_UI_V1
import 'stripe_live_connection_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paramétrage des frais. ATTENTION : cet écran ne prélève pas d'argent.
/// Les frais doivent être calculés et validés côté serveur au paiement.
class AdminFeesSettingsScreen extends StatefulWidget {
  const AdminFeesSettingsScreen({super.key});

  @override
  State<AdminFeesSettingsScreen> createState() =>
      _AdminFeesSettingsScreenState();
}

class _AdminFeesSettingsScreenState extends State<AdminFeesSettingsScreen> {
  static const _dark = Color(0xFF061E12);
  static const _green = Color(0xFF004D40);
  static const _gold = Color(0xFFFFD700);
  final _doc = FirebaseFirestore.instance.collection('platformSettings').doc('fees');
  final Map<String, _CategoryFees> _categories = {};
  bool _loading = true;
  bool _saving = false;
  String _side = 'customer';

  @override
  void initState() {
    super.initState();
    for (final item in <(String, String, IconData)>[
      ('eventTicket', 'Tickets événement', Icons.confirmation_number_outlined),
      ('catering', 'Catering', Icons.restaurant_outlined),
      ('marketplace', 'Marketplace', Icons.shopping_bag_outlined),
      ('services', 'Services professionnels', Icons.handyman_outlined),
      ('business', 'Restaurants & commerces', Icons.storefront_outlined),
      ('jobs', 'Emplois / prestations payantes', Icons.work_outline),
    ]) {
      _categories[item.$1] = _CategoryFees(item.$2, item.$3);
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final snapshot = await _doc.get();
      final data = snapshot.data() ?? <String, dynamic>{};
      for (final entry in _categories.entries) {
        final raw = data[entry.key];
        if (raw is! Map) continue;
        final category = Map<String, dynamic>.from(raw);
        // Ne pas convertir automatiquement les anciens frais en prélèvements :
        // leur destinataire n'était pas défini dans l'ancien modèle.
        for (final side in ['customer', 'business']) {
          final rawSide = category[side];
          if (rawSide is! Map) continue;
          final settings = Map<String, dynamic>.from(rawSide);
          final editor = entry.value.forSide(side);
          editor.enabled = settings['enabled'] == true;
          final type = settings['type']?.toString();
          if (type == 'fixed' || type == 'percentage') editor.type = type!;
          final value = settings['value'];
          if (value is num) editor.controller.text = value.toString().replaceAll('.', ',');
        }
      }
    } catch (_) {
      if (mounted) _message('Impossible de charger les paramètres.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red.shade700 : _green,
    ));
  }

  Future<void> _save() async {
    if (_saving) return;
    final payload = <String, dynamic>{};
    for (final entry in _categories.entries) {
      final sides = <String, dynamic>{};
      for (final side in ['customer', 'business']) {
        final editor = entry.value.forSide(side);
        final value = double.tryParse(editor.controller.text.trim().replaceAll(',', '.'));
        if (value == null || !value.isFinite || value < 0 ||
            (editor.type == 'percentage' && value > 100)) {
          _message('Valeur incorrecte : ${entry.value.title} (${side == 'customer' ? 'utilisateur' : 'professionnel'}).', error: true);
          return;
        }
        sides[side] = {
          'enabled': editor.enabled,
          'type': editor.type,
          'value': value,
        };
      }
      payload[entry.key] = sides;
    }
    payload['currency'] = 'EUR';
    payload['feeSchemaVersion'] = 2;
    payload['updatedAt'] = FieldValue.serverTimestamp();
    setState(() => _saving = true);
    try {
      // merge:true préserve les anciennes clés enabled/type/value de chaque
      // catégorie, afin de ne pas casser les anciens parcours de commande.
      await _doc.set(payload, SetOptions(merge: true));
      if (!mounted) return;
      _message('Configuration enregistrée. Les paiements ne sont pas encore reliés à ces paramètres.');
    } catch (_) {
      if (mounted) _message('Enregistrement impossible. Vérifie tes droits Firestore.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: _dark,
        suffixStyle: const TextStyle(color: _gold),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _gold),
        ),
      );

  Widget _feeCard(_CategoryFees category) {
    final fee = category.forSide(_side);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(category.icon, color: _gold, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(category.title, style: const TextStyle(
            color: _gold, fontSize: 16, fontWeight: FontWeight.bold,
          ))),
          Switch(
            value: fee.enabled,
            activeThumbColor: _gold,
            onChanged: (value) => setState(() => fee.enabled = value),
          ),
        ]),
        if (fee.enabled) ...[
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey('${category.title}-$_side-${fee.type}'),
            initialValue: fee.type,
            dropdownColor: _dark,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Type de frais'),
            items: const [
              DropdownMenuItem(value: 'percentage', child: Text('Pourcentage (%)')),
              DropdownMenuItem(value: 'fixed', child: Text('Montant fixe (€)')),
            ],
            onChanged: (type) {
              if (type != null) setState(() => fee.type = type);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: fee.controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
            style: const TextStyle(color: Colors.white),
            decoration: _decoration(fee.type == 'fixed' ? 'Montant (€)' : 'Pourcentage (%)')
                .copyWith(suffixText: fee.type == 'fixed' ? '€' : '%'),
          ),
        ],
      ]),
    );
  }

  @override
  void dispose() {
    for (final category in _categories.values) {
      category.customer.controller.dispose();
      category.business.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _dark,
        appBar: AppBar(
          backgroundColor: _dark,
          foregroundColor: _gold,
          title: const Text('Frais & commissions', style: TextStyle(
            color: _gold, fontWeight: FontWeight.bold,
          )),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _gold))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Paramètres réservés au Super Admin. Les utilisateurs et les professionnels ne doivent voir que leurs propres frais. Les nouveaux frais ne seront prélevés qu’après raccordement sécurisé des commandes et paiements.',
                      style: TextStyle(color: Colors.white, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected) ? _dark : _gold),
                      backgroundColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected) ? _gold : _green),
                    ),
                    segments: const [
                      ButtonSegment(value: 'customer', label: Text('Utilisateurs'), icon: Icon(Icons.person_outline)),
                      ButtonSegment(value: 'business', label: Text('Professionnels'), icon: Icon(Icons.storefront_outlined)),
                    ],
                    selected: {_side},
                    onSelectionChanged: (selection) => setState(() => _side = selection.first),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _side == 'customer'
                        ? 'Frais ajoutés au total payé par le client'
                        : 'Commission déduite du montant dû au professionnel',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  for (final category in _categories.values) _feeCard(category),
                  const SizedBox(height: 12),
                  Card(
                    color: _green,
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_outlined, color: _gold),
                      title: const Text('Connexions Stripe réelles', style: TextStyle(color: _gold)),
                      subtitle: const Text('Ouverture réservée au Super Admin', style: TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.chevron_right, color: _gold),
                      onTap: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(
                        builder: (_) => const StripeLiveAdminScreen(),
                      )),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _dark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Enregistrement...' : 'ENREGISTRER',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
      );
}

class _FeeSetting {
  bool enabled = false;
  String type = 'percentage';
  final controller = TextEditingController(text: '0');
}

class _CategoryFees {
  final String title;
  final IconData icon;
  final customer = _FeeSetting();
  final business = _FeeSetting();
  _CategoryFees(this.title, this.icon);
  _FeeSetting forSide(String side) => side == 'customer' ? customer : business;
}
