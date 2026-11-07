import 'l10n/app_ui.dart';

import 'package:flutter/material.dart';

import 'discovery_catalog.dart';
import 'discovery_photo.dart';
import 'member_interface_text.dart';

class DiscoverySearchScreen extends StatefulWidget {
  const DiscoverySearchScreen({
    super.key,
    required this.onOpen,
    this.initialQuery = '',
    this.initialKind = 'all',
    this.initialCategory = '',
  });
  final Future<void> Function(Map<String, dynamic>) onOpen;
  final String initialQuery;
  final String initialKind;
  final String initialCategory;

  @override
  State<DiscoverySearchScreen> createState() => _DiscoverySearchScreenState();
}

class _DiscoverySearchScreenState extends State<DiscoverySearchScreen> {
  static const _dark = Color(0xFF061E12);
  static const _gold = Color(0xFFFFD700);
  static const _card = Color(0xFF004D40);
  late final DiscoveryCatalog _catalog;
  late final TextEditingController _query;
  late String _kind;
  late String _category;
  final _city = TextEditingController();
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _category = widget.initialCategory;
    _query = TextEditingController(text: widget.initialQuery);
    _catalog = DiscoveryCatalog()..addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _catalog.removeListener(_refresh);
    _catalog.dispose();
    _query.dispose();
    _city.dispose();
    super.dispose();
  }

  String _label(String kind) => switch (kind) {
    'services' => memberText(context, 'Services', 'Services'),
    'jobs' => memberText(context, 'Emplois', 'Jobs'),
    'businesses' => memberText(context, 'Commerces', 'Businesses'),
    'events' => memberText(context, 'Événements', 'Events'),
    'market' => memberText(context, 'Marché', 'Marketplace'),
    'associations' => memberText(context, 'Associations', 'Associations'),
    _ => memberText(context, 'Tout', 'All'),
  };

  String _categoryLabel(String category) => switch (category) {
    'photo' => memberText(context, 'Photographie', 'Photography'),
    'translation' => memberText(context, 'Traduction', 'Translation'),
    'hair' => memberText(context, 'Coiffure', 'Hairdressing'),
    'barber' => memberText(context, 'Barbiers', 'Barbers'),
    'transport' => memberText(context, 'Transport', 'Transport'),
    'restaurants' => memberText(context, 'Restaurants', 'Restaurants'),
    'cafes' => memberText(context, 'Cafés', 'Cafés'),
    'grocery' => memberText(context, 'Épiceries', 'Grocery stores'),
    'offers' => memberText(
      context,
      'Offres et promotions',
      'Offers and promotions',
    ),
    _ => category,
  };

  List<DiscoveryEntry> get _results {
    final words = discoveryFold(_query.text)
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final city = discoveryFold(_city.text);
    return _catalog.entries.where((entry) {
      if (_kind != 'all' && entry.kind != _kind) return false;
      if (!discoveryMatchesCategory(entry.data, _category)) return false;
      if (city.isNotEmpty && !discoveryFold(entry.location).contains(city))
        return false;
      final text = discoveryFold(
        [
          entry.title,
          entry.location,
          discoveryText(entry.data, [
            'description',
            'professionTitle',
            'jobCategory',
            'businessCategory',
          ]),
        ].join(' '),
      );
      return words.every(text.contains);
    }).toList();
  }

  Future<void> _open(DiscoveryEntry entry) async {
    if (_opening) return;
    FocusScope.of(context).unfocus();
    setState(() => _opening = true);
    try {
      await widget.onOpen(entry.navigationData);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        backgroundColor: _dark,
        foregroundColor: _gold,
        title: Text(
          memberText(
            context,
            'Que cherchez-vous ?',
            'What are you looking for?',
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * 0.60,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: TextField(
                          controller: _query,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (_) => setState(() {}),
                          decoration: _decoration(
                            memberText(
                              context,
                              'Service, commerce, article, événement…',
                              'Service, business, item, event…',
                            ),
                            Icons.search,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: TextField(
                          controller: _city,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (_) => setState(() {}),
                          decoration: _decoration(
                            memberText(
                              context,
                              'Ville ou adresse (facultatif)',
                              'City or address (optional)',
                            ),
                            Icons.location_on_outlined,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 52,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            for (final kind in const [
                              'all',
                              'services',
                              'businesses',
                              'jobs',
                              'events',
                              'market',
                              'associations',
                            ])
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: ChoiceChip(
                                  label: Text(_label(kind)),
                                  selected: _kind == kind,
                                  selectedColor: _gold,
                                  backgroundColor: _card,
                                  labelStyle: TextStyle(
                                    color: _kind == kind ? _dark : Colors.white,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _kind = kind),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_category.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: InputChip(
                              label: Text(_categoryLabel(_category)),
                              backgroundColor: _gold,
                              labelStyle: const TextStyle(color: _dark),
                              onDeleted: () => setState(() => _category = ''),
                            ),
                          ),
                        ),
                      if (_category.isEmpty && _query.text.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 6,
                            children: [
                              for (final category in const [
                                'photo',
                                'translation',
                                'hair',
                                'transport',
                                'restaurants',
                                'grocery',
                              ])
                                ActionChip(
                                  label: Text(
                                    _categoryLabel(category),
                                    style: const TextStyle(color: _gold),
                                  ),
                                  backgroundColor: _card,
                                  onPressed: () =>
                                      setState(() => _category = category),
                                ),
                            ],
                          ),
                        ),
                      if (_catalog.errors.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  memberText(
                                    context,
                                    'Certains résultats sont indisponibles.',
                                    'Some results are unavailable.',
                                  ),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  _catalog.reload();
                                  setState(() {});
                                },
                                child: Text(
                                  memberText(context, 'Réessayer', 'Try again'),
                                  style: const TextStyle(color: _gold),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_opening) const LinearProgressIndicator(color: _gold),
              Expanded(
                child: results.isEmpty && _catalog.loading.isNotEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: _gold),
                      )
                    : results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            memberText(
                              context,
                              'Aucun résultat pour ces filtres. Essayez une autre recherche.',
                              'No results for these filters. Try another search.',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: results.length,
                        itemBuilder: (_, index) {
                          final entry = results[index];
                          return Card(
                            color: _card,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              leading: SizedBox(
                                width: 62,
                                height: 62,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: DiscoveryPhoto(
                                    urls: discoveryImages(entry.data),
                                    fallback: const Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: _gold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                entry.title.isEmpty
                                    ? 'Euro Habesha'
                                    : entry.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: AppText(
                                '${_label(entry.kind)}${entry.location.isEmpty ? '' : ' • ${entry.location}'}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: _gold,
                              ),
                              onTap: _opening ? null : () => _open(entry),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white70),
    prefixIcon: Icon(icon, color: _gold),
    filled: true,
    fillColor: _card,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );
}
