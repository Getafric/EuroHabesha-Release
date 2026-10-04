import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminFeesSettingsScreen extends StatefulWidget {
  const AdminFeesSettingsScreen({super.key});

  @override
  State<AdminFeesSettingsScreen> createState() =>
      _AdminFeesSettingsScreenState();
}

class _AdminFeesSettingsScreenState extends State<AdminFeesSettingsScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final _doc =
      FirebaseFirestore.instance.collection('platformSettings').doc('fees');

  bool _loading = true;
  bool _saving = false;

  late Map<String, _FeeEditor> _fees;

  @override
  void initState() {
    super.initState();

    _fees = {
      'eventTicket': _FeeEditor(
        title: 'Tickets événement',
        subtitle: 'Frais de service par billet payant',
        icon: Icons.confirmation_number_outlined,
        enabled: true,
        type: 'fixed',
        value: 0.50,
      ),
      'catering': _FeeEditor(
        title: 'Catering',
        subtitle: 'Frais sur les commandes catering',
        icon: Icons.restaurant_outlined,
        enabled: true,
        type: 'percentage',
        value: 5,
      ),
      'marketplace': _FeeEditor(
        title: 'Marketplace',
        subtitle: 'Frais sur les ventes Marketplace',
        icon: Icons.shopping_bag_outlined,
        enabled: false,
        type: 'percentage',
        value: 2,
      ),
      'services': _FeeEditor(
        title: 'Services',
        subtitle: 'Frais sur les autres services payants',
        icon: Icons.handyman_outlined,
        enabled: false,
        type: 'fixed',
        value: 1,
      ),
    };

    _load();
  }

  Future<void> _load() async {
    try {
      final snapshot = await _doc.get();

      if (snapshot.exists) {
        final data = snapshot.data() ?? {};

        for (final entry in _fees.entries) {
          final saved = data[entry.key];

          if (saved is Map) {
            final map = Map<String, dynamic>.from(saved);

            entry.value.enabled = map['enabled'] == true;

            final type = map['type']?.toString();

            if (type == 'fixed' || type == 'percentage') {
              entry.value.type = type!;
            }

            final value = map['value'];

            if (value is num) {
              entry.value.value = value.toDouble();
            }
          }
        }
      }

      _syncControllers();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible de charger les frais.',
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _syncControllers() {
    for (final fee in _fees.values) {
      fee.controller.text = fee.value
          .toStringAsFixed(
            fee.type == 'fixed' ? 2 : 1,
          )
          .replaceAll('.', ',');
    }
  }

  double? _parseValue(String text) {
    return double.tryParse(
      text.trim().replaceAll(',', '.'),
    );
  }

  Future<void> _save() async {
    if (_saving) return;

    final payload = <String, dynamic>{};

    for (final entry in _fees.entries) {
      final value = _parseValue(entry.value.controller.text);

      if (value == null || value < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Valeur incorrecte : ${entry.value.title}',
            ),
          ),
        );
        return;
      }

      if (entry.value.type == 'percentage' && value > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${entry.value.title} : le pourcentage '
              'ne peut pas dépasser 100 %.',
            ),
          ),
        );
        return;
      }

      payload[entry.key] = {
        'enabled': entry.value.enabled,
        'type': entry.value.type,
        'value': value,
      };
    }

    payload['currency'] = 'EUR';
    payload['updatedAt'] = FieldValue.serverTimestamp();

    setState(() => _saving = true);

    try {
      await _doc.set(
        payload,
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Frais et commissions enregistrés.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enregistrement impossible.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _feeCard(
    String key,
    _FeeEditor fee,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryGold.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primaryGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  fee.icon,
                  color: primaryGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fee.title,
                      style: const TextStyle(
                        color: primaryGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      fee.subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: fee.enabled,
                activeThumbColor: primaryGold,
                onChanged: (value) {
                  setState(() {
                    fee.enabled = value;
                  });
                },
              ),
            ],
          ),
          if (fee.enabled) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: fee.type,
              dropdownColor: primaryDarkGreen,
              decoration: _decoration('Type de frais'),
              style: const TextStyle(
                color: Colors.white,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'fixed',
                  child: Text('Montant fixe (€)'),
                ),
                DropdownMenuItem(
                  value: 'percentage',
                  child: Text('Pourcentage (%)'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  fee.type = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: fee.controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9,.]'),
                ),
              ],
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration: _decoration(
                fee.type == 'fixed' ? 'Montant (€)' : 'Pourcentage (%)',
              ).copyWith(
                suffixText: fee.type == 'fixed' ? '€' : '%',
                suffixStyle: const TextStyle(
                  color: primaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: primaryDarkGreen,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGold),
      ),
    );
  }

  @override
  void dispose() {
    for (final fee in _fees.values) {
      fee.controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        title: const Text(
          'Frais & commissions',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                35,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: primaryGold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: primaryGold.withValues(
                        alpha: 0.25,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Ces valeurs contrôlent les frais '
                    'Euro Habesha. Vous pourrez les '
                    'modifier sans republier l’application.',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                for (final entry in _fees.entries)
                  _feeCard(entry.key, entry.value),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGold,
                      foregroundColor: primaryDarkGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _saving ? 'Enregistrement...' : 'ENREGISTRER',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FeeEditor {
  final String title;
  final String subtitle;
  final IconData icon;

  bool enabled;
  String type;
  double value;

  final TextEditingController controller = TextEditingController();

  _FeeEditor({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.type,
    required this.value,
  });
}
