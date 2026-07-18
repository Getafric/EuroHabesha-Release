import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'access_control.dart';

class CateringScreen extends StatefulWidget {
  const CateringScreen({super.key});

  @override
  State<CateringScreen> createState() => _CateringScreenState();
}

class _CateringScreenState extends State<CateringScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessCityController = TextEditingController();
  final TextEditingController _businessCountryController = TextEditingController();
  final TextEditingController _businessPhoneController = TextEditingController();
  final TextEditingController _businessDescriptionController = TextEditingController();

  final TextEditingController _menuItemNameController = TextEditingController();
  final TextEditingController _menuItemPriceController = TextEditingController();
  final TextEditingController _menuItemDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _businessNameController.dispose();
    _businessCityController.dispose();
    _businessCountryController.dispose();
    _businessPhoneController.dispose();
    _businessDescriptionController.dispose();
    _menuItemNameController.dispose();
    _menuItemPriceController.dispose();
    _menuItemDescriptionController.dispose();
    super.dispose();
  }

  Future<String?> _ensureBusinessProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to manage catering business profile.')),
      );
      return null;
    }

    final existing = await FirebaseFirestore.instance
        .collection('catering_profiles')
        .where('ownerUid', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final name = _businessNameController.text.trim();
    final city = _businessCityController.text.trim();
    final country = _businessCountryController.text.trim();
    final phone = _businessPhoneController.text.trim();
    final description = _businessDescriptionController.text.trim();

    if (name.isEmpty || city.isEmpty || country.isEmpty || phone.isEmpty || description.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill business profile fields first.')),
      );
      return null;
    }

    final ref = await FirebaseFirestore.instance.collection('catering_profiles').add({
      'ownerUid': user.uid,
      'ownerEmail': (user.email ?? '').trim(),
      'businessName': name,
      'city': city,
      'country': country,
      'phone': phone,
      'description': description,
      'category': 'Catering',
      'status': 'approved',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  Future<void> _saveBusinessProfile() async {
    if (!AccessControl.ensureApprovedContributor(context, actionLabel: 'Create Catering Business Profile')) {
      return;
    }
    final profileId = await _ensureBusinessProfile();
    if (profileId == null) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catering business profile saved.')),
    );
  }

  Future<void> _addMenuItem() async {
    if (!AccessControl.ensureApprovedContributor(context, actionLabel: 'Add Catering Menu Item')) {
      return;
    }

    final profileId = await _ensureBusinessProfile();
    if (profileId == null) return;

    final name = _menuItemNameController.text.trim();
    final price = double.tryParse(_menuItemPriceController.text.trim().replaceAll(',', '.'));
    final description = _menuItemDescriptionController.text.trim();

    if (name.isEmpty || price == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu item name and price are required.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('catering_profiles')
        .doc(profileId)
        .collection('menu_items')
        .add({
      'name': name,
      'price': price,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _menuItemNameController.clear();
    _menuItemPriceController.clear();
    _menuItemDescriptionController.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menu item added.')),
    );
  }

  Future<void> _sendOrderRequest({
    required String profileId,
    required String ownerUid,
    required String businessName,
    required List<Map<String, dynamic>> menu,
  }) async {
    if (!AccessControl.ensureVerified(context, actionLabel: 'Place Catering Order Request')) {
      return;
    }

    final customer = FirebaseAuth.instance.currentUser;
    if (customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place order request.')),
      );
      return;
    }

    final instructionsController = TextEditingController();
    final qtyControllers = <String, TextEditingController>{};
    for (final item in menu) {
      final itemId = (item['id'] ?? '').toString();
      qtyControllers[itemId] = TextEditingController(text: '0');
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0E2E1E),
          title: Text('Order Request to $businessName', style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select quantities and add any instructions (dietary needs, delivery timing, event details).',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  ...menu.map((item) {
                    final itemId = (item['id'] ?? '').toString();
                    final name = (item['name'] ?? '').toString();
                    final price = (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$name - EUR ${price.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: qtyControllers[itemId],
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Qty',
                                hintStyle: const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: const Color(0xFF123222),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  TextField(
                    controller: instructionsController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Comments / Instructions',
                      labelStyle: const TextStyle(color: Colors.white54),
                      hintText: 'Dietary preferences, delivery timing, event location, etc.',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF123222),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF061E12),
              ),
              onPressed: () async {
                final selectedItems = <Map<String, dynamic>>[];
                double total = 0;
                for (final item in menu) {
                  final itemId = (item['id'] ?? '').toString();
                  final qty = int.tryParse(qtyControllers[itemId]?.text.trim() ?? '0') ?? 0;
                  if (qty <= 0) continue;
                  final price = (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0;
                  final name = (item['name'] ?? '').toString();
                  selectedItems.add({
                    'itemId': itemId,
                    'name': name,
                    'price': price,
                    'qty': qty,
                  });
                  total += price * qty;
                }

                if (selectedItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one menu item quantity.')),
                  );
                  return;
                }

                final customerId = customer.uid;
                final customerEmail = (customer.email ?? '').trim();
                final customerName = (customer.displayName ?? customerEmail).trim();
                final instructions = instructionsController.text.trim();

                final orderRef = await FirebaseFirestore.instance
                    .collection('catering_profiles')
                    .doc(profileId)
                    .collection('orders')
                    .add({
                  'profileId': profileId,
                  'businessOwnerUid': ownerUid,
                  'businessName': businessName,
                  'customerUid': customerId,
                  'customerEmail': customerEmail,
                  'customerName': customerName,
                  'items': selectedItems,
                  'instructions': instructions,
                  'status': 'pending',
                  'orderType': 'inquiry',
                  'estimatedTotal': total,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                // Immediate in-app notification for business owner.
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(ownerUid)
                    .collection('notifications')
                    .add({
                  'toUid': ownerUid,
                  'fromUid': customerId,
                  'title': 'New Catering Order Request',
                  'body': 'New inquiry from $customerName for $businessName.',
                  'type': 'catering_order_request',
                  'payload': {
                    'profileId': profileId,
                    'orderId': orderRef.id,
                    'customerUid': customerId,
                  },
                  'read': false,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                // Immediate confirmation notification for customer.
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(customerId)
                    .collection('notifications')
                    .add({
                  'toUid': customerId,
                  'fromUid': customerId,
                  'title': 'Order Request Sent',
                  'body': 'Your catering inquiry was sent to $businessName.',
                  'type': 'catering_order_confirmation',
                  'payload': {
                    'profileId': profileId,
                    'orderId': orderRef.id,
                  },
                  'read': false,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (!mounted || !dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order request sent. Business has been notified and your confirmation is saved.'),
                  ),
                );
              },
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );

    instructionsController.dispose();
    for (final controller in qtyControllers.values) {
      controller.dispose();
    }
  }

  Widget _buildBrowseTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('catering_profiles')
          .where('status', isEqualTo: 'approved')
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No catering businesses listed yet.',
              style: TextStyle(color: Colors.white60),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(14),
          children: docs.map((doc) {
            final data = doc.data();
            final profileId = doc.id;
            final businessName = (data['businessName'] ?? 'Catering Business').toString();
            final city = (data['city'] ?? '').toString();
            final country = (data['country'] ?? '').toString();
            final phone = (data['phone'] ?? '').toString();
            final description = (data['description'] ?? '').toString();
            final ownerUid = (data['ownerUid'] ?? '').toString();

            return Card(
              color: const Color(0xFF0E2E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text('$city${city.isNotEmpty && country.isNotEmpty ? ', ' : ''}$country', style: const TextStyle(color: Colors.white60)),
                    if (phone.isNotEmpty)
                      Text('Phone: $phone', style: const TextStyle(color: Colors.white60)),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(description, style: const TextStyle(color: Colors.white70)),
                    ],
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('catering_profiles')
                          .doc(profileId)
                          .collection('menu_items')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, menuSnap) {
                        final menuDocs = menuSnap.data?.docs ?? [];
                        if (menuDocs.isEmpty) {
                          return const Text('No menu items listed yet.', style: TextStyle(color: Colors.white54));
                        }

                        final menu = menuDocs
                            .map((m) => {
                                  'id': m.id,
                                  ...m.data(),
                                })
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Menu', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            ...menu.map((item) {
                              final name = (item['name'] ?? '').toString();
                              final price = (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0;
                              final itemDesc = (item['description'] ?? '').toString();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '• $name - EUR ${price.toStringAsFixed(2)}${itemDesc.isNotEmpty ? ' | $itemDesc' : ''}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                foregroundColor: const Color(0xFF061E12),
                              ),
                              onPressed: () => _sendOrderRequest(
                                profileId: profileId,
                                ownerUid: ownerUid,
                                businessName: businessName,
                                menu: menu,
                              ),
                              icon: const Icon(Icons.shopping_bag_outlined),
                              label: const Text('Order / Inquiry'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildManageTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Please sign in to manage your catering business.', style: TextStyle(color: Colors.white60)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
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
                'Catering Business Profile',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _businessNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Business name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _businessCityController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('City'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _businessCountryController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Country'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _businessPhoneController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Contact phone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _businessDescriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Business description'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                ),
                onPressed: _saveBusinessProfile,
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Save Catering Profile'),
              ),
            ],
          ),
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
              const Text('Menu Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _menuItemNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Menu item name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _menuItemPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Price (EUR)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _menuItemDescriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Menu item description (optional)'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                ),
                onPressed: _addMenuItem,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Menu Item'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF123222),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF59E0B)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        title: const Text('Catering Services', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'Manage'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(),
          _buildManageTab(),
        ],
      ),
    );
  }
}
