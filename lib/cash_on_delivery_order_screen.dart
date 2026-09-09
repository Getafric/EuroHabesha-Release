import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_session.dart';

class CashOnDeliveryOrderScreen extends StatefulWidget {
  final String itemType;
  final String itemTitle;
  final String sellerName;
  final String sellerContact;
  final String price;
  final Map<String, dynamic> sourceData;

  const CashOnDeliveryOrderScreen({
    super.key,
    required this.itemType,
    required this.itemTitle,
    required this.sellerName,
    required this.sellerContact,
    required this.price,
    required this.sourceData,
  });

  @override
  State<CashOnDeliveryOrderScreen> createState() => _CashOnDeliveryOrderScreenState();
}

class _CashOnDeliveryOrderScreenState extends State<CashOnDeliveryOrderScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final TextEditingController _buyerNameController = TextEditingController();
  final TextEditingController _buyerPhoneController = TextEditingController();
  final TextEditingController _deliveryAddressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _buyerNameController.text = AppSession.isGuest ? '' : AppSession.displayName;
    _buyerPhoneController.text = AppSession.phone;
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _deliveryAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in or continue with an account before placing an order.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (_buyerNameController.text.trim().isEmpty || _buyerPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and phone number.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final orderRef = await FirebaseFirestore.instance.collection('cashOnDeliveryOrders').add({
        'itemType': widget.itemType,
        'itemTitle': widget.itemTitle,
        'sellerName': widget.sellerName,
        'sellerContact': widget.sellerContact,
        'price': widget.price,
        'buyerId': user.uid,
        'userId': user.uid,
        'buyerEmail': user.email ?? AppSession.email,
        'buyerName': _buyerNameController.text.trim(),
        'buyerPhone': _buyerPhoneController.text.trim(),
        'deliveryAddress': _deliveryAddressController.text.trim(),
        'notes': _notesController.text.trim(),
        'paymentMethod': 'cashOnDelivery',
        'status': 'placed',
        'sourceData': widget.sourceData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('sellerNotifications').add({
        'type': 'cashOnDeliveryOrder',
        'orderId': orderRef.id,
        'sellerContact': widget.sellerContact,
        'sellerName': widget.sellerName,
        'title': 'New order: ${widget.itemTitle}',
        'body': '${_buyerNameController.text.trim()} placed a cash-on-delivery order.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CashOnDeliveryConfirmationScreen(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('Cash on Delivery', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: primaryGold),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.itemTitle, style: const TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${widget.price} • ${widget.sellerName}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                const Text('No card or online payment will be requested. You will pay directly to the seller upon receiving your item or service.', style: TextStyle(color: Colors.white, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildField('Your name *', _buyerNameController),
          const SizedBox(height: 12),
          _buildField('Your phone number *', _buyerPhoneController, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildField('Delivery address or meeting place', _deliveryAddressController, maxLines: 2),
          const SizedBox(height: 12),
          _buildField('Order notes', _notesController, maxLines: 4),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGold, padding: const EdgeInsets.symmetric(vertical: 15)),
            onPressed: _isSubmitting ? null : _placeOrder,
            child: Text(_isSubmitting ? 'Placing order...' : 'Order Now & Pay on Delivery', style: const TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: cardGreen,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class CashOnDeliveryConfirmationScreen extends StatelessWidget {
  const CashOnDeliveryConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        title: const Text('Order Confirmed', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF061E12),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFFFFD700), size: 76),
              const SizedBox(height: 18),
              const Text('Your order has been placed successfully.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('You will pay directly to the seller upon receiving your item.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Back to App', style: TextStyle(color: Color(0xFF061E12), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
