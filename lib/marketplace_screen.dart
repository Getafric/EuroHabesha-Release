import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'cash_on_delivery_order_screen.dart';
import 'dynamic_submission_screen.dart';
import 'chat_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  String selectedCategory = 'All';

  final List<String> categories = const [
    'All',
    'Habesha & Traditional',
    'Traditional Clothing',
    'Coffee & Ceremony',
    'Food & Spices',
    'Jewelry & Accessories',
    'Art & Decoration',
    'Vehicles',
    'Phones & Electronics',
    'Home & Furniture',
    'Fashion',
    'Beauty',
    'Baby & Kids',
    'Other',
  ];

  // ── የገበያው መነሻ እቃዎች (Starter Products) ──
  final List<Map<String, dynamic>> products = [
    {
      'title': 'Traditional Habesha Coffee Set (Sini)',
      'category': 'Coffee & Ceremony',
      'price': '\u20AC45',
      'location': 'Lyon, France',
      'condition': 'New',
      'time': 'Listed 2 hours ago',
      'sellerName': 'Abebe Kebede',
      'sellerPhone': '+33 6 12 34 56 78',
      'description':
          'Original Ethiopian clay coffee set (Jebena, 6 Sini, and Zelencha). Perfect condition, imported directly from Addis Ababa.',
      'image':
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'iPhone 13 Pro Max - 256GB',
      'category': 'Phones & Electronics',
      'price': '\u20AC550',
      'location': 'Paris, France',
      'condition': 'Used - Like New',
      'time': 'Listed 5 hours ago',
      'sellerName': 'Dawit M.',
      'sellerPhone': '+33 6 98 76 54 32',
      'description':
          'Battery health 88%. No scratches. Comes with original box and charger cable. Cash or instant transfer upon meetup in Paris.',
      'image':
          'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Volkswagen Golf 7 - 2018',
      'category': 'Vehicles',
      'price': '\u20AC12,500',
      'location': 'Marseille, France',
      'condition': 'Used - Good',
      'time': 'Listed 1 day ago',
      'sellerName': 'Samrawit T.',
      'sellerPhone': '+33 6 55 44 33 22',
      'description':
          'Diesel, Manual transmission, 140,000 km. Technical control (CT) passed last month. Full service history available.',
      'image':
          'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Ethiopian Traditional Dress (Habesha Kemis)',
      'category': 'Traditional Clothing',
      'price': '\u20AC120',
      'location': 'Frankfurt, Germany',
      'condition': 'New',
      'time': 'Listed 2 days ago',
      'sellerName': 'Marta E.',
      'sellerPhone': '+49 151 23456789',
      'description':
          'Hand-woven Habesha Kemis with traditional Tibeb. Size Medium-Large. Brand new, never worn.',
      'image':
          'https://images.unsplash.com/photo-1583391733958-d15317a86976?auto=format&fit=crop&w=800&q=80',
    },
  ];
  // ፖስት ማድረጊያ መቆጣጠሪያዎች (Controllers)

  // ── እቃ ለመሸጥ ፎርም (Sell Bottom Sheet) ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('Marketplace',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: primaryGold),
            tooltip: 'Post Listing',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DynamicSubmissionScreen(
                        type: SubmissionType.marketplace)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection('marketplace').snapshots(),
        builder: (context, snapshot) {
          final List<Map<String, dynamic>> combined = [];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data();
              final status = data['status']?.toString() ?? 'published';
              if (status == 'published' || status == 'approved') {
                final fields = Map<String, dynamic>.from(data['fields'] ?? {});

                final title = fields['title']?.toString() ??
                    data['title']?.toString() ??
                    'Listing';
                final price = fields['price']?.toString() ??
                    data['price']?.toString() ??
                    '€0';
                final location = fields['cityAddress']?.toString() ??
                    data['location']?.toString() ??
                    'Europe';
                final itemCat = fields['itemCategory']?.toString() ??
                    data['category']?.toString() ??
                    'All';
                final condition = fields['condition']?.toString() ??
                    data['condition']?.toString() ??
                    'Good';
                final desc = fields['description']?.toString() ??
                    data['description']?.toString() ??
                    '';

                final seller = fields['sellerName']?.toString() ??
                    data['submitterName']?.toString() ??
                    data['sellerName']?.toString() ??
                    'Habesha Member';
                final phone = fields['sellerPhone']?.toString() ??
                    fields['phone']?.toString() ??
                    data['sellerPhone']?.toString() ??
                    '';

                final media = data['media'] is Map
                    ? Map<String, dynamic>.from(data['media'])
                    : <String, dynamic>{};

                final marketplaceDetails = data['marketplaceDetails'] is Map
                    ? Map<String, dynamic>.from(data['marketplaceDetails'])
                    : <String, dynamic>{};

                final photoUrls = <String>[];

                void addPhotos(dynamic value) {
                  if (value is List) {
                    for (final photo in value) {
                      final url = photo?.toString().trim() ?? '';
                      if (url.isNotEmpty && !photoUrls.contains(url)) {
                        photoUrls.add(url);
                      }
                    }
                  }
                }

                addPhotos(media['photoUrls']);
                addPhotos(marketplaceDetails['photoUrls']);

                final legacyImage = fields['imageUrl']
                            ?.toString()
                            .trim()
                            .isNotEmpty ==
                        true
                    ? fields['imageUrl'].toString().trim()
                    : fields['image']?.toString().trim().isNotEmpty == true
                        ? fields['image'].toString().trim()
                        : data['imageUrl']?.toString().trim().isNotEmpty == true
                            ? data['imageUrl'].toString().trim()
                            : data['image']?.toString().trim() ?? '';

                if (legacyImage.isNotEmpty &&
                    !photoUrls.contains(legacyImage)) {
                  photoUrls.insert(0, legacyImage);
                }

                final image = photoUrls.isNotEmpty
                    ? photoUrls.first
                    : 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=800&q=80';

                combined.add({
                  'id': doc.id,
                  'submittedBy': data['submittedBy']?.toString() ?? '',
                  'ownerId': data['ownerId']?.toString() ?? '',
                  'creatorId': data['creatorId']?.toString() ?? '',
                  'title': title,
                  'price': price.startsWith('\u20AC') ? price : '\u20AC$price',
                  'location': location,
                  'category': itemCat,
                  'collection': 'marketplace',
                  'condition': condition,
                  'time': 'Recent',
                  'sellerName': seller,
                  'sellerPhone': phone,
                  'description': desc,
                  'image': image,
                  'photoUrls': photoUrls,
                });
              }
            }
          }

          for (final starter in products) {
            if (!combined.any((p) => p['title'] == starter['title'])) {
              combined.add(starter);
            }
          }

          final filtered = combined.where((product) {
            if (selectedCategory == 'All') return true;

            final category =
                (product['category'] ?? '').toString().trim().toLowerCase();

            final aliases = <String, List<String>>{
              'Habesha & Traditional': [
                'habesha & traditional',
                'habesha products',
                'traditional / habesha',
              ],
              'Traditional Clothing': [
                'traditional clothing',
              ],
              'Coffee & Ceremony': [
                'coffee & ceremony',
                'coffee',
              ],
              'Food & Spices': [
                'food & spices',
                'food',
              ],
              'Jewelry & Accessories': [
                'jewelry & accessories',
                'jewelry',
                'accessories',
              ],
              'Art & Decoration': [
                'art & decoration',
                'art',
                'decoration',
              ],
              'Vehicles': [
                'vehicles',
                'vehicle',
                'cars',
                'car',
                'motorcycles',
                'motorcycle',
              ],
              'Phones & Electronics': [
                'phones & electronics',
                'phones',
                'phone',
                'electronics',
              ],
              'Home & Furniture': [
                'home & furniture',
                'home',
                'furniture',
              ],
              'Fashion': [
                'fashion',
                'clothing',
                'shoes',
              ],
              'Beauty': [
                'beauty',
              ],
              'Baby & Kids': [
                'baby & kids',
                'baby',
                'kids',
              ],
              'Other': [
                'other',
                'services',
              ],
            };

            final accepted =
                aliases[selectedCategory] ?? [selectedCategory.toLowerCase()];

            return accepted.contains(category);
          }).toList();

          return Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        foregroundColor: primaryDarkGreen,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.edit_square, size: 18),
                      label: const Text('Sell',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DynamicSubmissionScreen(
                                  type: SubmissionType.marketplace)),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((cat) {
                            bool isSelected = selectedCategory == cat;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => selectedCategory = cat),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryGold.withValues(alpha: 0.2)
                                      : cardGreen,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: isSelected
                                          ? primaryGold
                                          : Colors.transparent),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected
                                        ? primaryGold
                                        : Colors.white70,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('No listings in this category.',
                            style: TextStyle(color: Colors.white54)))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailScreen(product: product),
                                ),
                              );
                            },
                            child: _buildProductCard(product),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                product['image'] ??
                    'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=800&q=80',
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white10,
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.white38),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['price'] ?? '€0',
                  style: TextStyle(
                      color: primaryGold,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  product['title'] ?? 'No Title',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.white54, size: 11),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        product['location'] ?? 'Europe',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF061E12);
    const Color primaryGold = Color(0xFFFFD700);
    const Color cardGreen = Color(0xFF004D40);

    final String title = product['title']?.toString().trim().isNotEmpty == true
        ? product['title'].toString().trim()
        : 'Product Details';

    final String price = product['price']?.toString().trim().isNotEmpty == true
        ? product['price'].toString().trim()
        : '\u20AC0';

    final String location =
        product['location']?.toString().trim().isNotEmpty == true
            ? product['location'].toString().trim()
            : 'Europe';

    final String time = product['time']?.toString().trim().isNotEmpty == true
        ? product['time'].toString().trim()
        : 'Recently listed';

    final String condition =
        product['condition']?.toString().trim().isNotEmpty == true
            ? product['condition'].toString().trim()
            : 'Good';

    final String sellerName =
        product['sellerName']?.toString().trim().isNotEmpty == true
            ? product['sellerName'].toString().trim()
            : 'Habesha Member';

    final String sellerPhone = product['sellerPhone']?.toString().trim() ?? '';

    final String description =
        product['description']?.toString().trim().isNotEmpty == true
            ? product['description'].toString().trim()
            : 'No description provided for this item.';

    final String sellerInitial =
        sellerName.isNotEmpty ? sellerName[0].toUpperCase() : 'H';

    // ---------------------------------------------------------
    // PHOTOS
    // Supports new listings with several photos and old listings
    // that only contain product['image'].
    // ---------------------------------------------------------

    final photoUrls = <String>[];

    final rawPhotoUrls = product['photoUrls'];

    if (rawPhotoUrls is List) {
      for (final photo in rawPhotoUrls) {
        final url = photo?.toString().trim() ?? '';

        if (url.isNotEmpty && !photoUrls.contains(url)) {
          photoUrls.add(url);
        }
      }
    }

    final fallbackImage = product['image']?.toString().trim() ?? '';

    if (fallbackImage.isNotEmpty && !photoUrls.contains(fallbackImage)) {
      photoUrls.insert(0, fallbackImage);
    }

    if (photoUrls.isEmpty) {
      photoUrls.add(
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30'
        '?auto=format&fit=crop&w=800&q=80',
      );
    }

    // ---------------------------------------------------------
    // SELLER ID
    // Compatible with new and older marketplace documents.
    // ---------------------------------------------------------

    final String sellerId =
        product['submittedBy']?.toString().trim().isNotEmpty == true
            ? product['submittedBy'].toString().trim()
            : product['ownerId']?.toString().trim().isNotEmpty == true
                ? product['ownerId'].toString().trim()
                : product['creatorId']?.toString().trim() ?? '';

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------
            // PRODUCT PHOTO GALLERY
            // Swipe left/right when several photos are available.
            // -------------------------------------------------

            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: photoUrls.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        photoUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return Container(
                            color: Colors.white10,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 52,
                              color: Colors.white38,
                            ),
                          );
                        },
                      ),

                      // Photo counter: 1/6, 2/6...
                      if (photoUrls.length > 1)
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${index + 1}/${photoUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PRICE
                  Text(
                    price,
                    style: const TextStyle(
                      color: primaryGold,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // TITLE
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // DATE + LOCATION
                  Wrap(
                    spacing: 15,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white54,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white54,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // CONDITION
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: primaryGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: primaryGold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Condition: $condition',
                      style: const TextStyle(
                        color: primaryGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Divider(
                    color: Colors.white24,
                    height: 30,
                  ),

                  // SELLER
                  const Text(
                    'Seller Information',
                    style: TextStyle(
                      color: primaryGold,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryGold.withValues(alpha: 0.2),
                          child: Text(
                            sellerInitial,
                            style: const TextStyle(
                              color: primaryGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sellerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Member of Euro Habesha Community',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // We intentionally do not show a fake
                        // verified badge here.
                        // It will be connected to real account
                        // verification later.
                      ],
                    ),
                  ),

                  const Divider(
                    color: Colors.white24,
                    height: 30,
                  ),

                  // DESCRIPTION
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: primaryGold,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardGreen,
                            foregroundColor: primaryGold,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                color: primaryGold,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.chat),
                          label: const Text(
                            'Send Message',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            await openDirectChat(
                              context: context,
                              otherUserId: sellerId,
                              otherUserName: sellerName,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGold,
                            foregroundColor: primaryDarkGreen,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.shopping_bag),
                          label: const Text(
                            'Order COD',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CashOnDeliveryOrderScreen(
                                  itemType: 'marketplace',
                                  itemTitle: title,
                                  sellerName: sellerName,
                                  sellerContact: sellerPhone,
                                  sellerId: sellerId,
                                  price: price,
                                  sourceData: product,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
