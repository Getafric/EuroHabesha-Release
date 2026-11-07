import '../managed_illustration.dart';
import '../l10n/app_ui.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'workspace_ui.dart';
import 'shop_pages.dart';
import 'job_pages.dart';
import 'flight_search_page.dart';

class EhExploreShortcuts extends StatefulWidget {
  const EhExploreShortcuts({
    super.key,
    required this.onDiscover,
    required this.onConnect,
  });
  final void Function(String kind, String category) onDiscover;
  final VoidCallback onConnect;
  @override
  State<EhExploreShortcuts> createState() => _EhExploreShortcutsState();
}

class _EhExploreShortcutsState extends State<EhExploreShortcuts> {
  final _scroll = ScrollController();
  Timer? _timer;
  DateTime _lastTouch = DateTime.now();
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_scroll.hasClients ||
          DateTime.now().difference(_lastTouch).inSeconds < 12 ||
          !mounted ||
          MediaQuery.of(context).disableAnimations ||
          ModalRoute.of(context)?.isCurrent != true)
        return;
      final end = _scroll.position.maxScrollExtent;
      _scroll.animateTo(
        _scroll.offset >= end - 1
            ? 0
            : (_scroll.offset + 140).clamp(0.0, end).toDouble(),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = <(String, IconData, VoidCallback)>[
      (
        'Voyages',
        Icons.flight,
        () => ehOpen<void>(context, const EhTravelPage()),
      ),
      (
        'Épiceries',
        Icons.shopping_basket_outlined,
        () => ehOpen<void>(context, const EhStoresPage()),
      ),
      (
        'Restaurants',
        Icons.restaurant,
        () => widget.onDiscover('businesses', 'restaurants'),
      ),
      (
        'Commerces',
        Icons.storefront,
        () => widget.onDiscover('businesses', ''),
      ),
      ('Services', Icons.work_outline, () => widget.onDiscover('services', '')),
      (
        'Emplois',
        Icons.badge_outlined,
        () => ehOpen<void>(context, const EhJobsPage()),
      ),
      ('Événements', Icons.event, () => widget.onDiscover('events', '')),
      ('Habesha Connect', Icons.groups, widget.onConnect),
      (
        'Photographie',
        Icons.camera_alt_outlined,
        () => widget.onDiscover('services', 'photo'),
      ),
      (
        'Traduction',
        Icons.translate,
        () => widget.onDiscover('services', 'translation'),
      ),
      (
        'Marché',
        Icons.shopping_bag_outlined,
        () => widget.onDiscover('marketplace', ''),
      ),
      (
        'Coiffure',
        Icons.content_cut,
        () => widget.onDiscover('services', 'hair'),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: AppText(
                    'Explorez Euro Habesha',
                    style: TextStyle(
                      color: ehGold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: ehDark,
                    isScrollControlled: true,
                    builder: (sheet) => SafeArea(
                      child: SizedBox(
                        height: MediaQuery.sizeOf(sheet).height * .65,
                        child: ListView(
                          children: [
                            for (final item in items)
                              ListTile(
                                leading: Icon(item.$2, color: ehGold),
                                title: AppText(
                                  item.$1,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  Navigator.pop(sheet);
                                  item.$3();
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  child: const AppText(
                    'Voir tout',
                    style: TextStyle(color: ehGold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Listener(
            onPointerDown: (_) => _lastTouch = DateTime.now(),
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        backgroundColor: ehCard,
                        side: const BorderSide(color: ehGold),
                        avatar: Icon(item.$2, color: ehGold, size: 19),
                        visualDensity: VisualDensity.compact,
                        label: AppText(
                          item.$1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: item.$3,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _travelKinds = {
  'bus': 'Voyage en bus',
  'excursion': 'Visite / excursion',
  'rental': 'Location de véhicule',
  'partner': 'Offre partenaire',
};

class EhTravelPage extends StatefulWidget {
  const EhTravelPage({super.key});
  @override
  State<EhTravelPage> createState() => _EhTravelPageState();
}

class _EhTravelPageState extends State<EhTravelPage> {
  String _kind = '';
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Voyages',
    actions: [
      IconButton(
        tooltip: 'Mes propositions',
        icon: const Icon(Icons.add),
        onPressed: () => ehOpen<void>(context, const EhTravelProposals()),
      ),
      IconButton(
        tooltip: 'Modération',
        icon: const Icon(Icons.admin_panel_settings),
        onPressed: () => ehOpen<void>(context, const EhReviewPage()),
      ),
    ],
    body: EhLoad(
      load: () => ehCall('travel'),
      builder: (d, refresh) {
        final items = ehRows(d['items'])
            .where((r) => _kind.isEmpty || r['kind'] == _kind)
            .toList();
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: const EhManagedTravelBanner(height: 125),
            ),
            ehTile(
              'Billets d’avion',
              'Rechercher des vols dans Euro Habesha',
              () => ehOpen<void>(context, const EhFlightSearchPage()),
              icon: Icons.flight,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final e in {'': 'Tout', ..._travelKinds}.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: AppText(e.value),
                        selected: _kind == e.key,
                        onSelected: (_) => setState(() => _kind = e.key),
                      ),
                    ),
                ],
              ),
            ),
            if (items.isEmpty)
              ehNote('Aucune proposition de voyage publiée pour le moment.'),
            for (final t in items)
              Card(
                color: ehCard,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        '${t['title']}',
                        style: const TextStyle(color: ehGold, fontSize: 22),
                      ),
                      ehNote(
                        '${t['providerName']} · ${t['from']} → ${t['to']}',
                      ),
                      ehNote('${t['description']}'),
                      ehNote(
                        'Départ : ${DateTime.parse(t['startsAt']).toLocal()}',
                      ),
                      ehNote(
                        'Retour / fin : ${DateTime.parse(t['endsAt']).toLocal()}',
                      ),
                      ehNote(
                        'Tarif déclaré : ${ehMoney(t['priceCents'])}\n${t['priceDetails']}',
                      ),
                      if ('${t['link'] ?? ''}'.isNotEmpty)
                        ehButton(
                          'Consulter le site du prestataire',
                          () => ehRun(context, () async {
                            final yes = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                backgroundColor: ehCard,
                                title: const AppText('Site externe'),
                                content: AppText(
                                  'Ouvrir ${Uri.parse(t['link']).host} ? Le prestataire gère la réservation et le paiement.',
                                ),
                                actions: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: ehGold,
                                    ),
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const AppText('Retour'),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: ehGold,
                                    ),
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const AppText('Ouvrir'),
                                  ),
                                ],
                              ),
                            );
                            if (yes == true)
                              await launchUrl(
                                Uri.parse(t['link']),
                                mode: LaunchMode.externalApplication,
                              );
                          }),
                          icon: Icons.open_in_new,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class EhTravelProposals extends StatelessWidget {
  const EhTravelProposals({super.key});
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Proposer un voyage',
    body: EhLoad(
      load: () async {
        final d = await ehCall('businesses.mine');
        final proposals = await ehCall('travel.mine');
        return {...d, 'proposals': proposals['items']};
      },
      builder: (d, refresh) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          ehNote(
            'Choisissez une activité déjà publiée. Les propositions sont examinées par Euro Habesha avant leur affichage.',
          ),
          for (final b in ehRows(d['items']))
            ehButton('Proposer avec ${b['name']}', () async {
              final id = ehId();
              await ehOpen<bool>(
                context,
                EhForm(
                  title: 'Ma proposition de voyage',
                  submit: 'Envoyer pour examen',
                  fields: const [
                    EhField('title', 'Titre', max: 120),
                    EhField(
                      'kind',
                      'Type de proposition',
                      choices: _travelKinds,
                    ),
                    EhField('description', 'Programme et conditions', lines: 5),
                    EhField('from', 'Ville de départ', max: 150),
                    EhField('to', 'Destination', max: 150),
                    EhField('startsAt', 'Départ', date: true),
                    EhField('endsAt', 'Retour / fin', date: true),
                    EhField('price', 'Tarif en euros', number: true),
                    EhField(
                      'priceDetails',
                      'Ce que comprend le tarif / par personne ou véhicule',
                      lines: 3,
                      max: 1000,
                    ),
                    EhField(
                      'link',
                      'Lien HTTPS du prestataire (facultatif)',
                      required: false,
                      max: 1500,
                    ),
                  ],
                  save: (v) async {
                    await ehCall('travel.propose', {
                      ...b,
                      ...v,
                      'id': id,
                      'priceCents': ehCents(v['price']),
                      'startsAt': DateTime.parse(v['startsAt'])
                          .toUtc()
                          .toIso8601String(),
                      'endsAt': DateTime.parse(v['endsAt'])
                          .toUtc()
                          .toIso8601String(),
                    });
                  },
                ),
              );
              refresh();
            }, icon: Icons.add),
          for (final t in ehRows(d['proposals']))
            ehTile(
              '${t['title']}',
              '${t['status'] == 'pending'
                  ? 'En examen'
                  : t['status'] == 'published'
                  ? 'Publiée'
                  : 'Refusée'}',
              null,
            ),
        ],
      ),
    ),
  );
}

class EhReviewPage extends StatelessWidget {
  const EhReviewPage({super.key});
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Modération communauté / voyages',
    body: EhLoad(
      load: () => ehCall('admin.review'),
      builder: (d, refresh) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          ehNote('Propositions de voyages à examiner'),
          for (final t in ehRows(d['travel']))
            Card(
              color: ehCard,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      '${t['title']}',
                      style: const TextStyle(color: ehGold),
                    ),
                    ehNote(
                      '${t['providerName']}\n${t['from']} → ${t['to']}\n${t['startsAt']} → ${t['endsAt']}\n${t['description']}\n${ehMoney(t['priceCents'])}\n${t['priceDetails']}\n${t['link']}',
                    ),
                    ehButton(
                      'Approuver',
                      () => ehRun(context, () async {
                        await ehCall('travel.review', {
                          'id': t['id'],
                          'approve': true,
                        });
                        refresh();
                      }),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: ehGold),
                      onPressed: () => ehRun(context, () async {
                        await ehCall('travel.review', {
                          'id': t['id'],
                          'approve': false,
                        });
                        refresh();
                      }),
                      child: const AppText('Refuser'),
                    ),
                  ],
                ),
              ),
            ),
          ehNote('Signalements de membres'),
          for (final r in ehRows(d['reports']))
            ehTile(
              'Membre ${r['targetId']}',
              'Signalé par ${r['reporterId']}\n${r['reason']}',
              null,
            ),
        ],
      ),
    ),
  );
}
