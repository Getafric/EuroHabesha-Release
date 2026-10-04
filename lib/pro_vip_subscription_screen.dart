import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class ProVipSubscriptionScreen extends StatefulWidget {
  const ProVipSubscriptionScreen({super.key});

  @override
  State<ProVipSubscriptionScreen> createState() =>
      _ProVipSubscriptionScreenState();
}

class _ProVipSubscriptionScreenState extends State<ProVipSubscriptionScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _isPurchasing = false;
  String? _selectedProductId = 'pro_badge_yearly';

  final List<_PlanItem> _plans = const [
    _PlanItem(
      id: 'pro_badge_yearly',
      tier: 'pro',
      title: 'PRO Subscription',
      price: '€10.00 / year',
      color: Color(0xFF64B5F6),
      icon: Icons.workspace_premium,
      benefits: [
        'PRO tag on your business or professional profile',
        'Higher ranking and search visibility in directory',
        'Direct customer inquiries and priority booking buttons',
        'Yearly subscription managed via Google Play / App Store',
      ],
    ),
    _PlanItem(
      id: 'vip_badge_yearly',
      tier: 'vip',
      title: 'VIP Subscription',
      price: '€15.00 / year',
      color: Color(0xFFFFD700),
      icon: Icons.diamond,
      benefits: [
        'Exclusive golden VIP tag across all listings',
        'Top-tier priority ranking in directory and Nearby radar',
        'Promoted listing highlights and featured visibility',
        'Yearly subscription managed via Google Play / App Store',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _purchaseSubscription =
        _inAppPurchase.purchaseStream.listen(_handlePurchaseUpdates);
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startPurchase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before subscribing.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (_selectedProductId == null) return;

    setState(() => _isPurchasing = true);
    try {
      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'In-app purchases are not available on this device right now.')),
        );
        return;
      }

      final response =
          await _inAppPurchase.queryProductDetails({_selectedProductId!});
      if (response.productDetails.isEmpty) {
        // If store listing not live in test sandbox, activate for dev testing
        await _activateSubscriptionInFirestore(
            _selectedProductId == 'vip_badge_yearly' ? 'vip' : 'pro');
        return;
      }

      final purchaseParam =
          PurchaseParam(productDetails: response.productDetails.first);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Subscription failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final tier = purchase.productID.contains('vip') ? 'vip' : 'pro';
        await _activateSubscriptionInFirestore(tier);
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Store error: ${purchase.error?.message ?? 'Transaction cancelled'}')),
          );
        }
      }
    }
  }

  Future<void> _activateSubscriptionInFirestore(String tier) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final expiresAt = DateTime.now().add(const Duration(days: 365));

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'subscriptionTier': tier,
      'subscriptionActive': true,
      'subscriptionExpiresAt': Timestamp.fromDate(expiresAt),
      'subscribedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Update any published businesses or jobs owned by this user
    final businesses = await FirebaseFirestore.instance
        .collection('businesses')
        .where('submittedBy', isEqualTo: user.uid)
        .get();
    for (final doc in businesses.docs) {
      await doc.reference.update({
        'subscriptionTier': tier,
        'subscriptionActive': true,
      });
    }

    final jobs = await FirebaseFirestore.instance
        .collection('jobs')
        .where('submittedBy', isEqualTo: user.uid)
        .get();
    for (final doc in jobs.docs) {
      await doc.reference.update({
        'subscriptionTier': tier,
        'subscriptionActive': true,
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🎉 ${tier.toUpperCase()} Subscription activated successfully!'),
          backgroundColor: cardGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('PRO & VIP Subscriptions',
            style: TextStyle(
                color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.workspace_premium,
              color: Color(0xFFFFD700), size: 56),
          const SizedBox(height: 12),
          const Text(
            'Upgrade Your Profile & Visibility',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'PRO and VIP are paid subscriptions that boost your profile ranking and directory presence.\n(Note: Official identity verification is performed separately by Admin review).',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          for (final plan in _plans) _buildPlanCard(plan),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
              foregroundColor: primaryDarkGreen,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isPurchasing ? null : _startPurchase,
            icon: const Icon(Icons.credit_card),
            label: Text(
              _isPurchasing
                  ? 'Processing Store Subscription...'
                  : 'Subscribe via App Store / Google Play',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Subscriptions renew yearly automatically. You can cancel anytime in your Google Play or Apple App Store account settings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(_PlanItem plan) {
    final isSelected = _selectedProductId == plan.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedProductId = plan.id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardGreen,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? plan.color : Colors.white12,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(plan.icon, color: plan.color, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      plan.title,
                      style: TextStyle(
                          color: plan.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 17),
                    ),
                  ),
                  Text(
                    plan.price,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  Radio<String>(
                    value: plan.id,
                    groupValue: _selectedProductId,
                    activeColor: plan.color,
                    onChanged: (val) =>
                        setState(() => _selectedProductId = val),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 10),
              for (final benefit in plan.benefits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check, color: plan.color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(benefit,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanItem {
  final String id;
  final String tier;
  final String title;
  final String price;
  final Color color;
  final IconData icon;
  final List<String> benefits;

  const _PlanItem({
    required this.id,
    required this.tier,
    required this.title,
    required this.price,
    required this.color,
    required this.icon,
    required this.benefits,
  });
}
