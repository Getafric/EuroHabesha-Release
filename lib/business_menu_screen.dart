import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'business_cart_screen.dart';

class BusinessMenuScreen extends StatefulWidget {
  final String businessId;
  final String businessName;

  const BusinessMenuScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<BusinessMenuScreen> createState() => _BusinessMenuScreenState();
}

class _BusinessMenuScreenState extends State<BusinessMenuScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);
  final Map<String, Map<String, dynamic>> _cart = {};

  void _addToCart(
    String itemId,
    Map<String, dynamic> item,
  ) {
    setState(() {
      if (_cart.containsKey(itemId)) {
        final currentQuantity = (_cart[itemId]!['quantity'] as int?) ?? 1;

        _cart[itemId]!['quantity'] = currentQuantity + 1;
      } else {
        _cart[itemId] = {
          'id': itemId,
          'name': item['name']?.toString() ?? 'Produit',
          'price': item['price'] ?? 0,
          'quantity': 1,
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = _cart.values.fold<int>(
      0,
      (total, item) => total + ((item['quantity'] as int?) ?? 0),
    );
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
                onPressed: cartItemCount == 0
                    ? null
                    : () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessCartScreen(
                              businessId: widget.businessId,
                              businessName: widget.businessName,
                              cart: _cart,
                            ),
                          ),
                        );
                      },
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('businessSubmissions')
            .doc(widget.businessId)
            .collection('menuItems')
            .where('isAvailable', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Impossible de charger le menu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ),
            );
          }

          final items = snapshot.data?.docs ?? [];

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      color: primaryGold,
                      size: 64,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Menu bientôt disponible',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.businessName} n’a pas encore ajouté de produits.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index].data();

              final name = item['name']?.toString() ?? 'Produit';

              final description = item['description']?.toString() ?? '';

              final price = item['price'];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardGreen,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryGold.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: primaryGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: primaryGold,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (price != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '$price €',
                              style: const TextStyle(
                                color: primaryGold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _addToCart(
                          items[index].id,
                          item,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$name ajouté au panier.',
                            ),
                            duration: const Duration(
                              milliseconds: 800,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.add_circle,
                        color: primaryGold,
                        size: 30,
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
  }
}
