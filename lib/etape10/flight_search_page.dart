import '../managed_illustration.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_ui.dart';
import 'workspace_ui.dart';

/// Native UI. No live offer is advertised until a partner is connected.
class EhFlightSearchPage extends StatefulWidget {
  const EhFlightSearchPage({super.key});
  @override
  State<EhFlightSearchPage> createState() => _EhFlightSearchPageState();
}

class _EhFlightSearchPageState extends State<EhFlightSearchPage> {
  final _form = GlobalKey<FormState>();
  final _from = TextEditingController(text: 'Lyon (LYS)');
  final _to = TextEditingController(text: 'Addis-Abeba (ADD)');
  DateTime? _departure, _return;
  int _adults = 1;
  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  Future<void> _date(bool returning) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final first = returning ? (_departure ?? today) : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: returning ? (_return ?? first) : (_departure ?? first),
      firstDate: first,
      lastDate: today.add(const Duration(days: 365)),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: ehGold,
            onPrimary: Colors.black,
            surface: ehCard,
            onSurface: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: ehGold),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted)
      setState(() {
        if (returning) {
          _return = picked;
        } else {
          _departure = picked;
          if (_return != null && _return!.isBefore(picked)) _return = null;
        }
      });
  }

  String _label(DateTime? d, String placeholder) => d == null
      ? ui(context, placeholder)
      : MaterialLocalizations.of(context).formatMediumDate(d);
  Future<void> _search() async {
    if (!_form.currentState!.validate()) return;
    if (_departure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(ui(context, 'Choisissez une date de départ.')),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ehCard,
        title: const AppText('Recherche de vols non connectée'),
        content: const AppText(
          'Les prix réels nécessitent un fournisseur partenaire. Aucune recherche réelle ni réservation n’a été effectuée.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ehGold),
            onPressed: () => Navigator.pop(c),
            child: const AppText('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Billets d’avion',
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                const EhManagedTravelBanner(height: 130),
                const Positioned(
                  left: 12,
                  bottom: 12,
                  child: AppText(
                    'Voyagez à votre rythme',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 6)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ehNote('Fournisseur à connecter · aucun prix réel disponible.'),
          for (final entry in [(_from, 'Départ'), (_to, 'Destination')])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextFormField(
                controller: entry.$1,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: ui(context, entry.$2),
                  filled: true,
                  fillColor: ehCard,
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? ui(context, 'Champ requis')
                    : null,
              ),
            ),
          ListTile(
            tileColor: ehCard,
            title: const AppText('Date de départ'),
            subtitle: Text(_label(_departure, 'Choisir une date')),
            trailing: const Icon(Icons.event, color: ehGold),
            onTap: () => _date(false),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: ehCard,
            title: const AppText('Retour (facultatif)'),
            subtitle: Text(_label(_return, 'Aller simple')),
            trailing: const Icon(Icons.event, color: ehGold),
            onTap: () => _date(true),
          ),
          DropdownButtonFormField<int>(
            initialValue: _adults,
            decoration: InputDecoration(labelText: ui(context, 'Adultes')),
            items: [
              for (int i = 1; i <= 9; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (v) => setState(() => _adults = v ?? 1),
          ),
          ehButton('Rechercher des vols', _search, icon: Icons.search),
          ehButton(
            'Voir un exemple de résultats',
            () => ehOpen<void>(context, const EhFlightExamplePage()),
            icon: Icons.preview,
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ehGold),
            onPressed: () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: ehCard,
                  title: const AppText('Ouvrir Ethiopian Airlines ?'),
                  content: const AppText(
                    'Vous allez quitter Euro Habesha. Les tarifs, la réservation et le paiement sont gérés par la compagnie.',
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: ehGold),
                      onPressed: () => Navigator.pop(c, false),
                      child: const AppText('Retour'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: ehGold,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => Navigator.pop(c, true),
                      child: const AppText('Continuer'),
                    ),
                  ],
                ),
              );
              if (yes == true)
                await launchUrl(
                  Uri.parse('https://www.ethiopianairlines.com/'),
                  mode: LaunchMode.externalApplication,
                );
            },
            child: const AppText('Consulter le site de la compagnie'),
          ),
        ],
      ),
    ),
  );
}

class EhFlightExamplePage extends StatelessWidget {
  const EhFlightExamplePage({super.key});
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Comparer les vols',
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: ehGold,
          child: const AppText(
            'TARIFS FICTIFS · EXEMPLE',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        ehNote('Lyon (LYS) → Addis-Abeba (ADD)'),
        for (final offer in [
          ('Ethiopian Airlines', '620 €'),
          ('Autre compagnie', '685 €'),
        ])
          Card(
            color: ehCard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    offer.$1,
                    style: const TextStyle(color: ehGold, fontSize: 20),
                  ),
                  Text(
                    offer.$2,
                    style: const TextStyle(color: ehGold, fontSize: 24),
                  ),
                  const AppText(
                    'Horaires, escales et bagages : exemple de présentation.',
                  ),
                  ehButton(
                    'Voir l’offre chez le vendeur',
                    () => showDialog<void>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: ehCard,
                        content: const AppText(
                          'Exemple uniquement : aucune offre réservable et aucun paiement.',
                        ),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: ehGold,
                            ),
                            onPressed: () => Navigator.pop(c),
                            child: const AppText('Fermer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ehNote(
          'Les prix réels et les liens de réservation seront fournis après connexion du partenaire.',
        ),
      ],
    ),
  );
}
