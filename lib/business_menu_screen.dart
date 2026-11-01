import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'business_cart_screen.dart';
import 'professional_capabilities.dart';

class BusinessMenuScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  final String sourceCollection;
  final bool allowOrdering;

  const BusinessMenuScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    this.sourceCollection = 'businessSubmissions',
    this.allowOrdering = true,
  });

  @override
  State<BusinessMenuScreen> createState() => _BusinessMenuScreenState();
}

class _BusinessMenuScreenState extends State<BusinessMenuScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);
  final Map<String, Map<String, dynamic>> _cart = {};

  String _type(Map<String, dynamic> item) {
    final raw =
        (item['productType'] ??
                item['itemType'] ??
                item['type'] ??
                item['category'] ??
                '')
            .toString()
            .toLowerCase();
    if (raw.contains('ebook') ||
        raw.contains('e-book') ||
        raw.contains('numérique') ||
        raw.contains('digital')) {
      return 'Ebook';
    }
    if (raw.contains('livre') || raw.contains('book')) return 'Livre papier';
    if (raw.contains('service')) return 'Service';
    if (raw.contains('plat') ||
        raw.contains('food') ||
        raw.contains('menu') ||
        raw.contains('restaurant')) {
      return 'Plat';
    }
    return 'Produit';
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'Ebook':
        return Icons.menu_book_outlined;
      case 'Livre papier':
        return Icons.auto_stories_outlined;
      case 'Service':
        return Icons.handyman_outlined;
      case 'Plat':
        return Icons.restaurant_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  String _imageUrl(Map<String, dynamic> item) {
    for (final key in ['imageUrl', 'photoUrl', 'coverUrl', 'image', 'photo']) {
      final value = item[key];
      if (value is String && value.trim().startsWith('https://')) {
        return value.trim();
      }
    }
    return '';
  }

  void _addToCart(String itemId, Map<String, dynamic> item) {
    setState(() {
      if (_cart.containsKey(itemId)) {
        final quantity = (_cart[itemId]!['quantity'] as int?) ?? 1;
        _cart[itemId]!['quantity'] = quantity + 1;
      } else {
        _cart[itemId] = {
          'id': itemId,
          'name': item['name']?.toString() ?? 'Produit',
          'price': item['price'] ?? 0,
          'productType':
              (item['productType'] ??
                      item['itemType'] ??
                      item['type'] ??
                      item['category'] ??
                      'product')
                  .toString(),
          'imageUrl': _imageUrl(item),
          'quantity': 1,
        };
      }
    });
  }

  Stream<List<_PublicMenuItem>> _items() {
    final parent = FirebaseFirestore.instance
        .collection(widget.sourceCollection)
        .doc(widget.businessId);
    if (widget.sourceCollection == 'jobSubmissions') {
      return parent.snapshots().map((snapshot) {
        final raw = snapshot.data()?['menuItems'];
        if (raw is! List) return <_PublicMenuItem>[];
        return <_PublicMenuItem>[
          for (var index = 0; index < raw.length; index++)
            if (raw[index] is Map &&
                (raw[index] as Map)['isAvailable'] != false)
              _PublicMenuItem(
                (raw[index] as Map)['id']?.toString() ?? '$index',
                Map<String, dynamic>.from(raw[index] as Map),
              ),
        ];
      });
    }
    return parent
        .collection('menuItems')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _PublicMenuItem(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = _cart.values.fold<int>(
      0,
      (total, item) => total + ((item['quantity'] as int?) ?? 0),
    );
    return ProfessionalCapabilitiesView(
      source: ProfessionalSource(widget.sourceCollection, widget.businessId),
      legacyOrders: true,
      builder: (context, actions) {
        final canOrder = widget.allowOrdering && actions.orders;
        return Scaffold(
          backgroundColor: primaryDarkGreen,
          appBar: AppBar(
            backgroundColor: primaryDarkGreen,
            foregroundColor: primaryGold,
            title: Text(
              widget.businessName,
              style: const TextStyle(
                color: primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Panier',
                    onPressed: !canOrder || cartItemCount == 0
                        ? null
                        : () async {
                            try {
                              final latest = await FirebaseFirestore.instance
                                  .collection(widget.sourceCollection)
                                  .doc(widget.businessId)
                                  .get(const GetOptions(source: Source.server));
                              if (!context.mounted) return;
                              if (!latest.exists ||
                                  latest.data()?['ordersEnabled'] == false) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Les commandes sont désactivées pour cet établissement.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BusinessCartScreen(
                                    businessId: widget.businessId,
                                    businessName: widget.businessName,
                                    cart: _cart,
                                    sourceCollection: widget.sourceCollection,
                                  ),
                                ),
                              );
                              if (mounted) setState(() {});
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Vérification impossible. Vérifiez la connexion puis réessayez.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.shopping_cart_outlined),
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: primaryGold,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$cartItemCount',
                          style: const TextStyle(
                            color: primaryDarkGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: StreamBuilder<List<_PublicMenuItem>>(
            stream: _items(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryGold),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Impossible de charger les produits.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              }
              final items = snapshot.data ?? <_PublicMenuItem>[];
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          color: primaryGold,
                          size: 64,
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Produits et services bientôt disponibles',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ce professionnel n’a pas encore publié d’articles.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = items[index];
                  final item = doc.data();
                  final name = item['name']?.toString() ?? 'Produit';
                  final description = item['description']?.toString() ?? '';
                  final type = _type(item);
                  final imageUrl = _imageUrl(item);
                  final price = item['price'];
                  final numericPrice = price is num
                      ? price.toDouble()
                      : double.tryParse(
                          price?.toString().replaceAll(',', '.') ?? '',
                        );
                  final hasPrice = numericPrice != null && numericPrice >= 0;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardGreen,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 84,
                                height: 100,
                                color: primaryDarkGreen,
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          _iconFor(type),
                                          color: primaryGold,
                                          size: 36,
                                        ),
                                      )
                                    : Icon(
                                        _iconFor(type),
                                        color: primaryGold,
                                        size: 36,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.toUpperCase(),
                                    style: const TextStyle(
                                      color: primaryGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      description,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                  if (hasPrice) ...[
                                    const SizedBox(height: 9),
                                    Text(
                                      '${numericPrice.toStringAsFixed(2).replaceAll('.', ',')} €',
                                      style: const TextStyle(
                                        color: primaryGold,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGold,
                              foregroundColor: primaryDarkGreen,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: !canOrder || !hasPrice
                                ? null
                                : () {
                                    _addToCart(doc.id, item);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '$name ajouté au panier.',
                                        ),
                                        duration: const Duration(
                                          milliseconds: 900,
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.add_shopping_cart_outlined),
                            label: Text(
                              canOrder
                                  ? 'Ajouter au panier'
                                  : 'Commandes désactivées',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _PublicMenuItem {
  final String id;
  final Map<String, dynamic> _data;
  const _PublicMenuItem(this.id, this._data);
  Map<String, dynamic> data() => _data;
}
