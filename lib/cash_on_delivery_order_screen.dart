import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_session.dart';
import 'order_receipt_screen.dart';

class CashOnDeliveryOrderScreen extends StatefulWidget {
  final String itemType;
  final String itemTitle;
  final String sellerName;
  final String sellerContact;
  final String sellerId;
  final String price;
  final Map<String, dynamic> sourceData;
  final double depositPercentage;
  final List<Map<String, dynamic>> cartItems;
  final double cartTotal;

  const CashOnDeliveryOrderScreen({
    super.key,
    required this.itemType,
    required this.itemTitle,
    required this.sellerName,
    required this.sellerContact,
    required this.sellerId,
    required this.price,
    required this.sourceData,
    this.depositPercentage = 0,
    this.cartItems = const [],
    this.cartTotal = 0,
  });

  @override
  State<CashOnDeliveryOrderScreen> createState() =>
      _CashOnDeliveryOrderScreenState();
}

class _CashOnDeliveryOrderScreenState extends State<CashOnDeliveryOrderScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final TextEditingController _buyerNameController = TextEditingController();
  final TextEditingController _buyerPhoneController = TextEditingController();
  final TextEditingController _deliveryAddressController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  bool _isSubmitting = false;
  bool _payDepositInApp = false;

  @override
  void initState() {
    super.initState();
    _buyerNameController.text =
        AppSession.isGuest ? '' : AppSession.displayName;
    _buyerPhoneController.text = AppSession.phone;
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _deliveryAddressController.dispose();
    _notesController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please sign in or continue with an account before placing an order.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (_buyerNameController.text.trim().isEmpty ||
        _buyerPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter your name and phone number.')),
      );
      return;
    }

    final double? orderTotal = widget.cartItems.isNotEmpty
        ? widget.cartTotal
        : double.tryParse(_totalController.text.trim());

    final depositAmount =
        orderTotal == null ? 0 : orderTotal * widget.depositPercentage / 100;
    if (_payDepositInApp &&
        (orderTotal == null ||
            orderTotal <= 0 ||
            widget.depositPercentage <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Enter a valid order total before requesting the deposit payment.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final orderRef = await FirebaseFirestore.instance
          .collection('cashOnDeliveryOrders')
          .add({
        'itemType': widget.itemType,
        'itemTitle': widget.itemTitle,
        'sellerName': widget.sellerName,
        'sellerContact': widget.sellerContact,
        'price': widget.price,
        'sellerId': widget.sellerId,
        'buyerId': user.uid,
        'userId': user.uid,
        'buyerEmail': user.email ?? AppSession.email,
        'buyerName': _buyerNameController.text.trim(),
        'buyerPhone': _buyerPhoneController.text.trim(),
        'deliveryAddress': _deliveryAddressController.text.trim(),
        'notes': _notesController.text.trim(),
        'orderTotal': orderTotal,
        'depositPercentage': widget.depositPercentage,
        'cartItems': widget.cartItems,
        'cartTotal': widget.cartTotal,
        'depositAmount': depositAmount,
        'paymentMethod': _payDepositInApp ? 'appDeposit' : 'cashOnDelivery',
        'status': _payDepositInApp ? 'pendingPayment' : 'placed',
        'sourceData': Map<String, dynamic>.from(widget.sourceData)
          ..remove('icon'),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('sellerNotifications').add({
        'type': 'cashOnDeliveryOrder',
        'orderId': orderRef.id,
        'sellerId': widget.sellerId,
        'sellerContact': widget.sellerContact,
        'sellerName': widget.sellerName,
        'title': 'New order: ${widget.itemTitle}',
        'body':
            '${_buyerNameController.text.trim()} placed a cash-on-delivery order.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CashOnDeliveryConfirmationScreen(
            orderId: orderRef.id,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Order failed: $e')));
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
        title: const Text('Cash on Delivery',
            style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: primaryGold),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).padding.bottom + 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: cardGreen, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.itemTitle,
                    style: const TextStyle(
                        color: primaryGold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${widget.price} • ${widget.sellerName}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                const Text(
                    'No card or online payment will be requested. You will pay directly to the seller upon receiving your item or service.',
                    style: TextStyle(color: Colors.white, height: 1.4)),
                if (widget.depositPercentage > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                      'This caterer accepts a ${widget.depositPercentage.toStringAsFixed(0)}% deposit for app orders.',
                      style: const TextStyle(
                          color: Colors.greenAccent, height: 1.4)),
                ],
              ],
            ),
          ),
          if (widget.cartItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your order',
                    style: TextStyle(
                      color: primaryGold,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final item in widget.cartItems) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name']?.toString() ?? 'Item',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${item['quantity']} × €${(item['unitPrice'] as num).toDouble().toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '€${(item['total'] as num).toDouble().toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '€${widget.cartTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildField('Your name *', _buyerNameController),
          const SizedBox(height: 12),
          _buildField('Your phone number *', _buyerPhoneController,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildField(
              'Delivery address or meeting place', _deliveryAddressController,
              maxLines: 2),
          const SizedBox(height: 12),
          _buildField('Order notes', _notesController, maxLines: 4),
          if (widget.depositPercentage > 0) ...[
            const SizedBox(height: 12),
            _buildField(
                'Order total (€) for deposit calculation', _totalController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _totalController,
              builder: (context, value, child) {
                final total = double.tryParse(value.text.trim()) ?? 0;
                final deposit = total * widget.depositPercentage / 100;
                return Text(
                    'Deposit due: €${deposit.toStringAsFixed(2)} (${widget.depositPercentage.toStringAsFixed(0)}% of €${total.toStringAsFixed(2)})',
                    style: const TextStyle(
                        color: primaryGold, fontWeight: FontWeight.bold));
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pay deposit through the app',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                  'The payment gateway must be enabled before funds are captured.',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
              value: _payDepositInApp,
              activeThumbColor: primaryGold,
              onChanged: (value) => setState(() => _payDepositInApp = value),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                padding: const EdgeInsets.symmetric(vertical: 15)),
            onPressed: _isSubmitting ? null : _placeOrder,
            child: Text(
                _isSubmitting
                    ? 'Placing order...'
                    : 'Order Now & Pay on Delivery',
                style: const TextStyle(
                    color: primaryDarkGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }
}

class CashOnDeliveryConfirmationScreen extends StatelessWidget {
  final String orderId;

  const CashOnDeliveryConfirmationScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        title: const Text('Order Confirmed',
            style: TextStyle(
                color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF061E12),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  color: Color(0xFFFFD700), size: 76),
              const SizedBox(height: 18),
              const Text('Your order has been placed successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                'Order #${orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                  'You will pay directly to the seller upon receiving your item.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70, fontSize: 15, height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CashOnDeliveryOrderTrackingScreen(
                          orderId: orderId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text(
                    'View My Order',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700)),
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Back to App',
                    style: TextStyle(
                        color: Color(0xFF061E12), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CashOnDeliveryOrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const CashOnDeliveryOrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Order accepted';
      case 'preparing':
        return 'Preparing your order';
      case 'ready':
        return 'Your order is ready';
      case 'completed':
        return 'Order completed';
      case 'rejected':
        return 'Order rejected';
      case 'cancelled':
        return 'Order cancelled';
      case 'pendingPayment':
        return 'Waiting for payment';
      case 'placed':
      default:
        return 'Waiting for seller confirmation';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.thumb_up_alt_outlined;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.shopping_bag_outlined;
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }

  Future<void> _cancelOrder(
    BuildContext context,
    String reason,
  ) async {
    const dialogGreen = Color(0xFF063D32);
    const dialogDark = Color(0xFF021F18);
    const gold = Color(0xFFFFC928);
    const cancelRed = Color(0xFFFF5C57);

    final selectedReason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: dialogGreen,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: gold.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: gold,
                  size: 52,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Confirm cancellation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Do you really want to cancel this order?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dialogDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white24,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason for cancellation',
                        style: TextStyle(
                          color: gold,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _cancellationReasonOption(
                        label: 'Seller not responding',
                        onTap: () {
                          Navigator.pop(
                            dialogContext,
                            'Seller not responding',
                          );
                        },
                      ),
                      _cancellationReasonOption(
                        label: 'Waiting too long',
                        onTap: () {
                          Navigator.pop(
                            dialogContext,
                            'Waiting too long',
                          );
                        },
                      ),
                      _cancellationReasonOption(
                        label: 'Ordered by mistake',
                        onTap: () {
                          Navigator.pop(
                            dialogContext,
                            'Ordered by mistake',
                          );
                        },
                      ),
                      _cancellationReasonOption(
                        label: 'Changed my mind',
                        onTap: () {
                          Navigator.pop(
                            dialogContext,
                            'Changed my mind',
                          );
                        },
                      ),
                      _cancellationReasonOption(
                        label: 'Other',
                        onTap: () {
                          Navigator.pop(
                            dialogContext,
                            'Other',
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: gold.withValues(alpha: 0.55),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: gold,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Warning: Repeated cancellations after a seller '
                          'accepts your order may restrict your ability to '
                          'place new orders.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: gold,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      'Keep order',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedReason == null) {
      return;
    }

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: gold.withValues(alpha: 0.55),
            ),
          ),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: gold,
            size: 46,
          ),
          title: const Text(
            'Cancel this order?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Reason: $selectedReason\n\n'
            'Are you sure you want to continue?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(
                  color: gold,
                ),
              ),
              child: const Text('Keep order'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: cancelRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel order'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final orderRef = FirebaseFirestore.instance
          .collection('cashOnDeliveryOrders')
          .doc(orderId);

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final snapshot = await transaction.get(orderRef);

          if (!snapshot.exists) {
            throw Exception('Order not found.');
          }

          final currentStatus =
              snapshot.data()?['status']?.toString() ?? 'placed';

          if (currentStatus != 'placed') {
            throw Exception(
              'This order can no longer be cancelled.',
            );
          }

          transaction.update(orderRef, {
            'status': 'cancelled',
            'cancelReason': selectedReason,
            'cancelledBy': 'buyer',
            'cancelledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        },
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Widget _cancellationReasonOption({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 9,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.radio_button_unchecked,
              color: Color(0xFFFFC928),
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text(
          'My Order',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(
          color: primaryGold,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('cashOnDeliveryOrders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load this order.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Order not found.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final data = snapshot.data!.data() ?? {};

          final status = data['status']?.toString() ?? 'placed';

          final items = data['cartItems'] is List
              ? List<dynamic>.from(
                  data['cartItems'],
                )
              : <dynamic>[];

          final total = (data['cartTotal'] as num?)?.toDouble() ??
              (data['orderTotal'] as num?)?.toDouble() ??
              0;

          final shortOrderId = orderId.length > 8
              ? orderId.substring(0, 8).toUpperCase()
              : orderId.toUpperCase();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      'Order #$shortOrderId',
                      style: const TextStyle(
                        color: primaryGold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Icon(
                      _statusIcon(status),
                      color: primaryGold,
                      size: 46,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _statusLabel(status),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order details',
                        style: TextStyle(
                          color: primaryGold,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final item in items) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['name']?.toString() ?? 'Item',
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              '× ${item['quantity'] ?? 0}',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              '€${((item['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: primaryGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      const Divider(
                        color: Colors.white24,
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '€${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: primaryGold,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderReceiptScreen(
                          orderId: orderId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.receipt_long_outlined,
                  ),
                  label: const Text(
                    'Voir / télécharger le reçu',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGold,
                    foregroundColor: primaryDarkGreen,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              if (status == 'placed') ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _cancelOrder(
                        context,
                        'Cancelled by customer',
                      );
                    },
                    icon: const Icon(
                      Icons.cancel_outlined,
                    ),
                    label: const Text(
                      'Cancel order',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(
                        color: Colors.redAccent,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
