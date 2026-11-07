import '../l10n/app_ui.dart';

import 'package:flutter/material.dart';

import 'workspace_ui.dart';

class EhStoresPage extends StatelessWidget {
  const EhStoresPage({super.key});
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Épiceries et boutiques',
    actions: [
      IconButton(
        tooltip: 'Mes commandes',
        onPressed: () => ehOpen<void>(context, const EhOrdersPage()),
        icon: const Icon(Icons.receipt_long),
      ),
    ],
    body: EhLoad(
      load: () => ehCall('stores'),
      builder: (d, refresh) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          ehNote(
            'Choisissez une boutique. Le panier et le retrait concernent une seule boutique à la fois.',
          ),
          if (ehRows(d['items']).isEmpty)
            ehNote('Les boutiques n’ont pas encore activé leur catalogue.'),
          for (final s in ehRows(d['items']))
            ehTile(
              '${s['title']}',
              '${s['city']} · ${s['address']}',
              () => ehOpen<void>(context, EhStorePage(id: s['id'])),
            ),
        ],
      ),
    ),
  );
}

class EhStorePage extends StatefulWidget {
  const EhStorePage({super.key, required this.id});
  final String id;
  @override
  State<EhStorePage> createState() => _EhStorePageState();
}

class _EhStorePageState extends State<EhStorePage> {
  final _cart = <String, int>{};
  String _intent = ehId();
  bool _busy = false;
  Future<void> _checkout(EhData store, VoidCallback refresh) async {
    if (_busy || _cart.isEmpty) return;
    final slots = (store['slots'] as List? ?? [])
        .where((s) => DateTime.tryParse('$s')?.isAfter(DateTime.now()) == true)
        .toList();
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('Aucun créneau disponible.')),
      );
      return;
    }
    setState(() => _busy = true);
    final result = await ehOpen<bool>(
      context,
      EhForm(
        title: 'Confirmer le retrait',
        submit: 'Envoyer ma commande',
        note: 'Le prix et le stock sont vérifiés sur le serveur. Paiement au magasin lors du retrait. Aucun paiement Stripe n’est déclenché ici.',
        fields: [
          const EhField(
            'contactName',
            'Nom de la personne qui retire',
            max: 100,
          ),
          const EhField('contactPhone', 'Téléphone pour le retrait', max: 50),
          EhField(
            'slot',
            'Créneau de retrait',
            choices: {
              for (final s in slots)
                '$s': DateTime.parse('$s')
                    .toLocal()
                    .toString()
                    .substring(0, 16),
            },
          ),
        ],
        save: (v) async {
          await ehCall('order.create', {
            ...v,
            'storeId': widget.id,
            'intent': _intent,
            'items': _cart.entries
                .map((e) => {'id': e.key, 'quantity': e.value})
                .toList(),
          });
        },
      ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result == true) {
        _cart.clear();
        _intent = ehId();
      }
    });
    if (result == true) {
      await ehOpen<void>(context, const EhOrdersPage());
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Catalogue de la boutique',
    body: EhLoad(
      load: () => ehCall('store', {'id': widget.id}),
      builder: (d, refresh) {
        final store = ehMap(d['store']), products = ehRows(d['items']);
        final byId = {for (final p in products) p['id']: p};
        final total = _cart.entries.fold<int>(
          0,
          (s, e) =>
              s + ((byId[e.key]?['priceCents'] as num? ?? 0).toInt() * e.value),
        );
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            AppText(
              '${store['title']}',
              style: const TextStyle(color: ehGold, fontSize: 24),
            ),
            ehNote('${store['address']}'),
            if (products.isEmpty) ehNote('Aucun produit disponible.'),
            for (final p in products)
              Card(
                color: ehCard,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ehPhoto(p['imageUrl']?.toString()),
                      AppText(
                        '${p['title']}',
                        style: const TextStyle(color: ehGold, fontSize: 20),
                      ),
                      ehNote(
                        '${ehMoney(p['priceCents'])} / ${p['unit']} · Stock : ${p['stock']}',
                      ),
                      TextButton(
                        onPressed: () => ehOpen<void>(
                          context,
                          EhScaffold(
                            title: '${p['title']}',
                            body: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              children: [
                                ehPhoto(p['imageUrl']?.toString(), height: 230),
                                for (final f in {
                                  'description': 'Description',
                                  'brand': 'Marque',
                                  'category': 'Catégorie',
                                  'sku': 'Référence',
                                  'ingredients': 'Ingrédients',
                                  'allergens': 'Allergènes',
                                  'storage': 'Conservation',
                                  'origin': 'Origine',
                                }.entries)
                                  if ('${p[f.key] ?? ''}'.isNotEmpty)
                                    ehNote('${f.value} : ${p[f.key]}'),
                                ehNote(
                                  '${ehMoney(p['priceCents'])} / ${p['unit']}',
                                ),
                              ],
                            ),
                          ),
                        ),
                        child: const AppText('Voir les détails du produit'),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Retirer une unité',
                            onPressed: (_cart[p['id']] ?? 0) == 0
                                ? null
                                : () => setState(() {
                                    final q = (_cart[p['id']] ?? 0) - 1;
                                    if (q == 0) {
                                      _cart.remove(p['id']);
                                    } else {
                                      _cart[p['id']] = q;
                                    }
                                  }),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          AppText('${_cart[p['id']] ?? 0}'),
                          IconButton(
                            tooltip: 'Ajouter une unité',
                            onPressed:
                                (_cart[p['id']] ?? 0) >= (p['stock'] as num) ||
                                    (_cart[p['id']] ?? 0) >= 100
                                ? null
                                : () => setState(
                                    () => _cart[p['id']] =
                                        (_cart[p['id']] ?? 0) + 1,
                                  ),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ehNote(
              'Total indicatif : ${ehMoney(total)}. Le serveur confirme le total à l’envoi.',
            ),
            ehButton(
              'Choisir mon retrait (${_cart.values.fold<int>(0, (a, b) => a + b)} articles)',
              _busy || _cart.isEmpty ? null : () => _checkout(store, refresh),
              icon: Icons.shopping_bag_outlined,
            ),
          ],
        );
      },
    ),
  );
}

class EhShopManager extends StatelessWidget {
  const EhShopManager({super.key, required this.source});
  final EhData source;
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Mes produits et mon retrait',
    actions: [
      IconButton(
        tooltip: 'Commandes clients',
        onPressed: () =>
            ehOpen<void>(context, const EhOrdersPage(seller: true)),
        icon: const Icon(Icons.receipt_long),
      ),
    ],
    body: EhLoad(
      load: () => ehCall('store.manage', source),
      builder: (d, refresh) {
        final s = ehMap(d['store']);
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            ehNote(
              'Ce catalogue utilise votre activité existante. Les produits ne sont proposés qu’après activation du retrait.',
            ),
            ehButton('Configurer la boutique et les créneaux', () async {
              await ehOpen<bool>(
                context,
                EhForm(
                  title: 'Configuration du retrait',
                  initial: {
                    ...s,
                    'slots': (s['slots'] as List? ?? []).join(', '),
                  },
                  note:
                      'Saisissez chaque date au format 2026-11-20T16:30:00+01:00, séparée par une virgule. Le fuseau est nécessaire. '
                      'Paiement sur place uniquement dans cette version.',
                  fields: const [
                    EhField('title', 'Enseigne'),
                    EhField('address', 'Adresse précise du retrait', max: 300),
                    EhField(
                      'slots',
                      'Dates et heures des créneaux',
                      lines: 4,
                      required: false,
                    ),
                    EhField('active', 'Activer mon catalogue', toggle: true),
                  ],
                  save: (v) async {
                    await ehCall('store.save', {
                      ...source,
                      ...v,
                      'slots': ehSplit(v['slots']),
                    });
                  },
                ),
              );
              refresh();
            }, icon: Icons.storefront),
            ehButton(
              'Ajouter un produit',
              s.isEmpty
                  ? null
                  : () async {
                      await _product(context, {});
                      refresh();
                    },
              icon: Icons.add,
            ),
            for (final p in ehRows(d['items']))
              ehTile(
                '${p['title']}',
                '${ehMoney(p['priceCents'])} · ${p['stock']} en stock · ${p['active'] == true ? 'Visible' : 'Masqué'}',
                () async {
                  await _product(context, p);
                  refresh();
                },
                icon: Icons.edit,
              ),
          ],
        );
      },
    ),
  );
  Future<void> _product(BuildContext context, EhData p) async {
    final productId = p['id'] ?? ehId();
    await ehOpen<bool>(
      context,
      EhForm(
        title: p.isEmpty ? 'Ajouter un produit' : 'Modifier le produit',
        photoKey: 'imageUrl',
        initial: {
          ...p,
          'price': p.isEmpty
              ? ''
              : ((p['priceCents'] as num) / 100).toStringAsFixed(2),
          'stock': p['stock'] ?? 0,
        },
        fields: const [
          EhField('title', 'Nom du produit', max: 120),
          EhField('category', 'Catégorie'),
          EhField('brand', 'Marque', required: false, max: 120),
          EhField('description', 'Description', lines: 4, required: false),
          EhField('unit', 'Unité / poids (ex. paquet de 500 g)'),
          EhField('price', 'Prix en euros', number: true),
          EhField('stock', 'Quantité en stock', number: true),
          EhField('sku', 'Référence du produit', required: false, max: 120),
          EhField('ingredients', 'Ingrédients', lines: 3, required: false),
          EhField(
            'allergens',
            'Allergènes',
            lines: 2,
            required: false,
            max: 1000,
          ),
          EhField('storage', 'Conservation', required: false, max: 1000),
          EhField('origin', 'Origine', required: false, max: 200),
          EhField('active', 'Rendre ce produit visible', toggle: true),
        ],
        save: (v) async {
          await ehCall('product.save', {
            ...source,
            ...v,
            'id': productId,
            'revision': p['revision'] ?? 0,
            'priceCents': ehCents(v['price']),
            'stock': int.tryParse('${v['stock']}') ?? -1,
          });
        },
      ),
    );
  }
}

class EhOrdersPage extends StatelessWidget {
  const EhOrdersPage({super.key, this.seller = false});
  final bool seller;
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: seller ? 'Commandes clients' : 'Mes commandes de retrait',
    body: EhLoad(
      load: () => ehCall('orders', {'seller': seller}),
      builder: (d, refresh) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (ehRows(d['items']).isEmpty)
            ehNote('Aucune commande pour le moment.'),
          for (final o in ehRows(d['items']))
            Card(
              color: ehCard,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      '${o['storeTitle']}',
                      style: const TextStyle(color: ehGold, fontSize: 20),
                    ),
                    ehNote('Commande ${o['id']}'),
                    ehNote(
                      'Retrait : ${DateTime.parse(o['slot']).toLocal().toString().substring(0, 16)}',
                    ),
                    for (final line in ehRows(o['lines']))
                      AppText(
                        '${line['quantity']} × ${line['title']} · ${ehMoney(line['priceCents'])}',
                      ),
                    ehNote(
                      'Total : ${ehMoney(o['totalCents'])} · À payer au magasin',
                    ),
                    ehNote(
                      'Statut : ${{'placed': 'Envoyée', 'ready': 'Prête', 'collected': 'Retirée', 'cancelled': 'Annulée'}[o['status']] ?? o['status']}',
                    ),
                    if (seller)
                      ehNote(
                        'Contact retrait : ${o['buyerName']} · ${o['contactPhone']}',
                      ),
                    if (seller && o['status'] == 'placed')
                      ehButton(
                        'Marquer prête',
                        () => _status(context, o, 'ready', refresh),
                      ),
                    if (seller && o['status'] == 'ready')
                      ehButton(
                        'Confirmer le retrait',
                        () => _status(context, o, 'collected', refresh),
                      ),
                    if (o['status'] == 'placed' ||
                        (seller && o['status'] == 'ready'))
                      TextButton(
                        onPressed: () async {
                          final yes = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const AppText('Annuler cette commande ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const AppText('Retour'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const AppText('Annuler la commande'),
                                ),
                              ],
                            ),
                          );
                          if (yes == true && context.mounted)
                            await _status(context, o, 'cancelled', refresh);
                        },
                        child: const AppText('Annuler la commande'),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
  Future<void> _status(
    BuildContext context,
    EhData o,
    String status,
    VoidCallback refresh,
  ) => ehRun(context, () async {
    await ehCall('order.status', {'id': o['id'], 'status': status});
    refresh();
  });
}
