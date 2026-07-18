import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_localization_helper.dart';
import 'market_registration_screen.dart';
import 'access_control.dart';
import 'registration_screen.dart';
import 'catering_screen.dart';
import 'provider_chat_thread_screen.dart';
import 'service_profile_detail_screen.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MarketHub();
  }
}

class _MarketHub extends StatefulWidget {
  const _MarketHub();

  @override
  State<_MarketHub> createState() => _MarketHubState();
}

class _MarketHubState extends State<_MarketHub> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';

  final List<Map<String, String>> _seedItems = const [
    {
      'title': 'Traditional Coffee Set',
      'city': 'Brussels, Belgium',
      'price': '€45',
      'tag': 'Home & Kitchen',
    },
    {
      'title': 'Event Catering Service',
      'city': 'Amsterdam, Netherlands',
      'price': '€220/day',
      'tag': 'Services',
    },
    {
      'title': 'Habesha Wedding Decor',
      'city': 'Paris, France',
      'price': '€380',
      'tag': 'Decor',
    },
    {
      'title': 'Used Delivery Van',
      'city': 'Frankfurt, Germany',
      'price': '€8,500',
      'tag': 'Vehicles',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final tags = _seedItems.map((e) => e['tag'] ?? '').where((e) => e.isNotEmpty).toSet().toList()..sort();
    return ['All', ...tags];
  }

  bool _matchItem(Map<String, String> item) {
    final tag = (item['tag'] ?? '').trim();
    if (_selectedCategory != 'All' && tag != _selectedCategory) return false;

    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    final text = '${item['title']} ${item['city']} $tag ${item['dynamic']} ${item['description']}'.toLowerCase();
    return text.contains(query);
  }

  List<Map<String, String>> _mapDocsToItems(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((doc) {
      final data = doc.data();
      String firstNonEmpty(List<dynamic> values) {
        for (final value in values) {
          final text = value == null ? '' : value.toString().trim();
          if (text.isNotEmpty) return text;
        }
        return '';
      }
      final title = (data['title'] ?? '').toString().trim();
      final category = (data['category'] ?? data['tag'] ?? '').toString().trim();
      final country = (data['country'] ?? '').toString().trim();
      final city = (data['city'] ?? '').toString().trim();
      final dynamicAttrs = (data['dynamicAttributes'] ?? const <String, dynamic>{}).toString();
      final description = (data['description'] ?? '').toString().trim();
      final priceText = (data['priceText'] ?? '').toString().trim();
      final priceValue = data['priceValue'];
      String price = priceText;
      if (price.isEmpty && priceValue is num) {
        price = 'EUR ${priceValue.toStringAsFixed(0)}';
      }
      if (price.isEmpty) {
        price = (data['price'] ?? 'Negotiable').toString();
      }

      final cityCountry = [city, country].where((v) => v.isNotEmpty).join(', ');
      return <String, String>{
        'id': doc.id,
        'title': title.isEmpty ? 'Marketplace listing' : title,
        'city': cityCountry.isEmpty ? 'Unknown location' : cityCountry,
        'price': price,
        'tag': category.isEmpty ? 'General' : category,
        'dynamic': dynamicAttrs,
        'description': description,
        'userId': firstNonEmpty([
          data['userId'],
          data['user_id'],
          data['providerUid'],
          data['ownerUid'],
          data['authorUid'],
          data['postedByUid'],
          data['postedBy'],
          data['createdByUid'],
          data['createdBy'],
          data['submittedByUid'],
          data['uid'],
        ]),
        'providerName': (data['authorName'] ?? data['providerName'] ?? title).toString().trim(),
        'phone': (data['phone'] ?? data['authorPhone'] ?? '').toString().trim(),
        'email': (data['email'] ?? '').toString().trim(),
        'website': (data['website'] ?? '').toString().trim(),
      };
    }).toList();
  }

  void _showRegistrationPrompt() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF061E12),
          title: const Text('Create an Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'Please register or sign in to contact a seller.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF061E12),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                );
              },
              child: const Text('Register / Sign In'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openMarketThread(Map<String, String> item) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showRegistrationPrompt();
      return;
    }

    final providerUid = (item['userId'] ?? '').trim();
    final providerName = (item['providerName'] ?? item['title'] ?? 'Seller').trim();
    if (providerUid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller chat is not available for this listing yet.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderChatThreadScreen(
          providerUid: providerUid,
          providerName: providerName.isEmpty ? 'Seller' : providerName,
          postId: (item['id'] ?? '').trim(),
          postType: 'market_items',
          postTitle: (item['title'] ?? '').trim(),
          postCategory: (item['tag'] ?? '').trim(),
          providerPhone: (item['phone'] ?? '').trim(),
          providerEmail: (item['email'] ?? '').trim(),
        ),
      ),
    );
  }

  List<String> _categoriesFromItems(List<Map<String, String>> items) {
    final tags = items.map((e) => e['tag'] ?? '').where((e) => e.isNotEmpty).toSet().toList()..sort();
    return ['All', ...tags];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Market Hub', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [AppLocalizationHelper.languageMenu(context)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('market_items')
              .where('status', isEqualTo: 'approved')
              .limit(200)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? const [];
            final sourceItems = docs.isEmpty ? _seedItems : _mapDocsToItems(docs);
            final categories = docs.isEmpty ? _categories : _categoriesFromItems(sourceItems);

            if (!categories.contains(_selectedCategory)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _selectedCategory = 'All';
                });
              });
            }

            final filtered = sourceItems.where(_matchItem).toList();

            return ListView(
              children: [
                _buildMarketHero(),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search market items and services',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0E2E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF59E0B)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((category) {
                    final selected = _selectedCategory == category;
                    return ChoiceChip(
                      selected: selected,
                      label: Text(category),
                      selectedColor: const Color(0xFFF59E0B),
                      backgroundColor: const Color(0xFF0E2E1E),
                      labelStyle: TextStyle(
                        color: selected ? const Color(0xFF061E12) : const Color(0xFFF5C542),
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E2E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Browse Marketplace Without Registration',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Visitors can view items. Create an account to publish products and build your business profile.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          foregroundColor: const Color(0xFFF59E0B),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                          );
                        },
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Create Account'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Listings (${filtered.length})',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E2E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Text(
                      'No listings match this search yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  ...filtered.map((item) => _MarketPreviewCard(
                        title: item['title'] ?? '',
                        city: item['city'] ?? '',
                        price: item['price'] ?? '',
                        tag: item['tag'] ?? '',
                        onOpen: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ServiceProfileDetailScreen(
                                title: item['title'] ?? '',
                                category: item['tag'] ?? '',
                                description: item['description'] ?? '',
                                providerName: (item['providerName'] ?? item['title'] ?? '').trim(),
                                city: item['city'] ?? '',
                                phone: item['phone'] ?? '',
                                email: item['email'] ?? '',
                                website: item['website'] ?? '',
                                userId: item['userId'] ?? '',
                                postId: item['id'] ?? '',
                                postType: 'market_items',
                              ),
                            ),
                          );
                        },
                        onContact: () => _openMarketThread(item),
                      )),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  icon: const Icon(Icons.restaurant_menu, color: Color(0xFF061E12)),
                  label: const Text('Open Catering Module', style: TextStyle(color: Color(0xFF061E12))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8D79B),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const CateringScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.storefront, color: Color(0xFF061E12)),
                  label: const Text('Register & Post Listing', style: TextStyle(color: Color(0xFF061E12))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (!AccessControl.ensureApprovedContributor(context, actionLabel: tr('sell_register_product'))) {
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const MarketRegistrationScreen()),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMarketHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF123222), Color(0xFF0A2418), Color(0xFF1F3F2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.35)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Hub: Browse, Search, Post',
            style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Browse trusted listings, search by category, and register new market posts from one hub.',
            style: TextStyle(color: Color(0xFFE8D79B), fontSize: 12.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _MarketPreviewCard extends StatelessWidget {
  final String title;
  final String city;
  final String price;
  final String tag;
  final VoidCallback onOpen;
  final VoidCallback onContact;

  const _MarketPreviewCard({
    required this.title,
    required this.city,
    required this.price,
    required this.tag,
    required this.onOpen,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0E2E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10),
      ),
      child: ListTile(
        onTap: onOpen,
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(city, style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: Text(tag, style: const TextStyle(color: Color(0xFFE8D79B), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(price, style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF59E0B)),
                foregroundColor: const Color(0xFFF59E0B),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: onContact,
              icon: const Icon(Icons.chat_bubble_outline, size: 14),
              label: const Text('Message', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
