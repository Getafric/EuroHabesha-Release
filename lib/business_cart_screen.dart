import 'package:flutter/material.dart';
import 'business_checkout_screen.dart';

class BusinessCartScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  final String sourceCollection;
  final Map<String, Map<String, dynamic>> cart;

  const BusinessCartScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    this.sourceCollection = 'businessSubmissions',
    required this.cart,
  });

  @override
  State<BusinessCartScreen> createState() => _BusinessCartScreenState();
}

class _BusinessCartScreenState extends State<BusinessCartScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  late Map<String, Map<String, dynamic>> _cart;

  @override
  void initState() {
    super.initState();

    _cart = widget.cart.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    );
  }

  String _itemType(Map<String, dynamic> item) {
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
      return 'Ebook numérique';
    }
    if (raw.contains('book') || raw.contains('livre')) {
      return 'Livre papier';
    }
    if (raw.contains('service')) return 'Service';
    if (raw.contains('food') ||
        raw.contains('plat') ||
        raw.contains('restaurant')) {
      return 'Plat';
    }
    return 'Produit';
  }

  IconData _itemIcon(Map<String, dynamic> item) {
    switch (_itemType(item)) {
      case 'Ebook numérique':
        return Icons.menu_book_outlined;
      case 'Livre papier':
        return Icons.auto_stories_outlined;
      case 'Service':
        return Icons.handyman_outlined;
      case 'Plat':
        return Icons.restaurant_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  double _priceOf(Map<String, dynamic> item) {
    final value = item['price'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  double get _total {
    double total = 0;

    for (final item in _cart.values) {
      final quantity = (item['quantity'] as int?) ?? 1;
      total += _priceOf(item) * quantity;
    }

    return total;
  }

  void _increaseQuantity(String itemId) {
    setState(() {
      final item = _cart[itemId];
      if (item == null) return;

      final quantity = (item['quantity'] as int?) ?? 1;
      item['quantity'] = quantity + 1;
    });
  }

  void _decreaseQuantity(String itemId) {
    setState(() {
      final item = _cart[itemId];
      if (item == null) return;

      final quantity = (item['quantity'] as int?) ?? 1;

      if (quantity <= 1) {
        _cart.remove(itemId);
      } else {
        item['quantity'] = quantity - 1;
      }
    });
  }

  void _removeItem(String itemId) {
    setState(() {
      _cart.remove(itemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = _cart.entries.toList();

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        title: const Text(
          'Mon panier',
          style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
        ),
      ),
      body: _cart.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      color: primaryGold,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Votre panier est vide',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final itemId = entry.key;
                      final item = entry.value;

                      final name = item['name']?.toString() ?? 'Produit';

                      final quantity = (item['quantity'] as int?) ?? 1;

                      final price = _priceOf(item);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardGreen,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryGold.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: primaryGold.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_itemIcon(item), color: primaryGold),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _itemType(item),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${price.toStringAsFixed(2)} €',
                                    style: const TextStyle(
                                      color: primaryGold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _decreaseQuantity(itemId),
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '$quantity',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _increaseQuantity(itemId),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: primaryGold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeItem(itemId),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  decoration: const BoxDecoration(
                    color: cardGreen,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_total.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                color: primaryGold,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Ce total est indicatif. Le serveur vérifiera le prix des '
                          'articles physiques avant de payer sur Stripe. '
                          'Les ebooks et prestations sur devis ne sont pas payés ici.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (widget.sourceCollection !=
                                  'businessSubmissions') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Le paiement des menus Services sera raccordé séparément.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => BusinessCheckoutScreen(
                                    businessId: widget.businessId,
                                    businessName: widget.businessName,
                                    items: _cart.entries
                                        .map(
                                          (entry) => <String, dynamic>{
                                            'itemId': entry.key,
                                            'quantity': entry.value['quantity'],
                                          },
                                        )
                                        .toList(),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGold,
                              foregroundColor: primaryDarkGreen,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text(
                              'Continuer la commande',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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
