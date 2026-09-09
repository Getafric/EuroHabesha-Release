import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  String? _selectedTier;
  XFile? _selectedDocument;
  bool _isPurchasing = false;
  bool _isCompletingVerification = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  final List<_VerificationTier> _tiers = const [
    _VerificationTier(
      id: 'silver_badge_yearly',
      title: 'Silver Badge',
      price: '€5 / year',
      subtitle: 'For personal profile trust verification',
      icon: Icons.verified,
      color: Color(0xFFC0C0C0),
    ),
    _VerificationTier(
      id: 'pro_badge_yearly',
      title: 'Pro Badge (for Businesses)',
      price: '€10 / year',
      subtitle: 'For restaurants, businesses, and professionals',
      icon: Icons.workspace_premium,
      color: Color(0xFF64B5F6),
    ),
    _VerificationTier(
      id: 'vip_badge_yearly',
      title: 'VIP Badge',
      price: '€15 / year',
      subtitle: 'Premium visibility and highest trust tier',
      icon: Icons.diamond,
      color: Color(0xFFFFD700),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(_handlePurchaseUpdates);
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    const typeGroup = XTypeGroup(
      label: 'Verification documents',
      extensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file != null) {
      setState(() => _selectedDocument = file);
    }
  }

  Future<void> _submitVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_selectedTier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Silver, Pro, or VIP before continuing.')),
      );
      return;
    }

    if (user == null || !user.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in and verify your email before requesting a badge.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (_selectedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach an official document or image for review.')),
      );
      return;
    }

    setState(() => _isPurchasing = true);
    try {
      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store billing is not available on this device yet.')),
        );
        return;
      }

      final response = await _inAppPurchase.queryProductDetails({_selectedTier!});
      if (response.productDetails.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Badge product is not configured in Google Play / App Store yet.')),
        );
        return;
      }

      final purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
      final launched = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open store billing. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification purchase failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != _selectedTier) {
        continue;
      }

      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _isPurchasing = true);
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        if (mounted) {
          setState(() => _isPurchasing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Store billing failed: ${purchase.error?.message ?? 'Unknown error'}')),
          );
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        await _completeVerificationRequest(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<void> _completeVerificationRequest(PurchaseDetails purchase) async {
    if (_isCompletingVerification || _selectedTier == null || _selectedDocument == null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      return;
    }

    setState(() {
      _isPurchasing = true;
      _isCompletingVerification = true;
    });

    try {
      final tier = _tiers.firstWhere((item) => item.id == purchase.productID);
      final bytes = await _selectedDocument!.readAsBytes();
      final safeName = _selectedDocument!.name.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
      final storagePath = 'verificationDocs/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final storageRef = FirebaseStorage.instance.ref(storagePath);
      await storageRef.putData(bytes);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('verificationRequests').add({
        'submittedBy': user.uid,
        'submitterEmail': user.email,
        'tierId': tier.id,
        'tierTitle': tier.title,
        'tierPrice': tier.price,
        'purchaseId': purchase.purchaseID,
        'transactionDate': purchase.transactionDate,
        'status': 'pendingAdminReview',
        'documentName': _selectedDocument!.name,
        'documentStoragePath': storagePath,
        'documentDownloadUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tier.title} request submitted for admin review.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not complete verification request: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _isCompletingVerification = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('Get Verified', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 32),
        children: [
          const Icon(Icons.verified, color: primaryGold, size: 76),
          const SizedBox(height: 18),
          const Text(
            'Choose Your Verification Tier',
            textAlign: TextAlign.center,
            style: TextStyle(color: primaryGold, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Badge subscriptions are yearly and use Google Play / Apple App Store billing. Physical goods still use Cash on Delivery only.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          for (final tier in _tiers) _buildTierCard(tier),
          if (_selectedTier == null) ...[
            const SizedBox(height: 4),
            const Text('Required: select one yearly badge tier.', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 22),
          _buildDocumentUpload(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
              foregroundColor: primaryDarkGreen,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isPurchasing ? null : _submitVerification,
            icon: const Icon(Icons.payment),
            label: Text(_isPurchasing ? 'Processing selected tier...' : 'Continue with Selected Tier', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(_VerificationTier tier) {
    final selected = _selectedTier == tier.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _selectedTier = tier.id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardGreen,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? tier.color : Colors.white12, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(tier.icon, color: tier.color, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tier.title, style: TextStyle(color: tier.color, fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 3),
                    Text(tier.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(tier.price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Radio<String>(
                    value: tier.id,
                    groupValue: _selectedTier,
                    activeColor: tier.color,
                    onChanged: (value) => setState(() => _selectedTier = value),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentUpload() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Official Document Upload', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Attach a PDF or image for admin review. Text-only proof is no longer accepted.', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryGold), minimumSize: const Size(double.infinity, 48)),
            onPressed: _pickDocument,
            icon: const Icon(Icons.upload_file, color: primaryGold),
            label: Text(_selectedDocument?.name ?? 'Choose document or image', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _VerificationTier {
  final String id;
  final String title;
  final String price;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _VerificationTier({
    required this.id,
    required this.title,
    required this.price,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
