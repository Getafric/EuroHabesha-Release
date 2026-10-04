import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'cash_on_delivery_order_screen.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'pendingPayment':
        return 'Waiting for payment';
      case 'placed':
      default:
        return 'Waiting for seller';
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
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: primaryDarkGreen,
        appBar: AppBar(
          title: const Text(
            'My Orders',
            style: TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: primaryDarkGreen,
          iconTheme: const IconThemeData(
            color: primaryGold,
          ),
          bottom: const TabBar(
            indicatorColor: primaryGold,
            labelColor: primaryGold,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(
                icon: Icon(Icons.access_time),
                text: 'Active',
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'History',
              ),
            ],
          ),
        ),
        body: user == null
            ? const Center(
                child: Text(
                  'Please sign in to see your orders.',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('cashOnDeliveryOrders')
                    .where(
                      'buyerId',
                      isEqualTo: user.uid,
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Unable to load your orders.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
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

                  final orders = snapshot.data?.docs.toList() ?? [];

                  orders.sort((a, b) {
                    final aTime = a.data()['createdAt'] as Timestamp?;
                    final bTime = b.data()['createdAt'] as Timestamp?;

                    if (aTime == null && bTime == null) {
                      return 0;
                    }

                    if (aTime == null) return 1;
                    if (bTime == null) return -1;

                    return bTime.compareTo(aTime);
                  });

                  final activeOrders = orders.where((order) {
                    final status =
                        order.data()['status']?.toString() ?? 'placed';

                    return status == 'placed' ||
                        status == 'pendingPayment' ||
                        status == 'accepted' ||
                        status == 'preparing' ||
                        status == 'ready';
                  }).toList();

                  final historyOrders = orders.where((order) {
                    final status =
                        order.data()['status']?.toString() ?? 'placed';

                    return status == 'completed' ||
                        status == 'rejected' ||
                        status == 'cancelled';
                  }).toList();

                  if (orders.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: primaryGold,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No orders yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your orders will appear here after you place them.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return TabBarView(
                    children: [
                      _buildOrdersList(
                        context,
                        activeOrders,
                        emptyTitle: 'No active orders',
                        emptyMessage: 'Your current orders will appear here.',
                      ),
                      _buildOrdersList(
                        context,
                        historyOrders,
                        emptyTitle: 'No order history',
                        emptyMessage:
                            'Completed, rejected or cancelled orders will appear here.',
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildOrdersList(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> orders, {
    required String emptyTitle,
    required String emptyMessage,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: primaryGold,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final data = order.data();

        final status = data['status']?.toString() ?? 'placed';

        final sellerName = data['sellerName']?.toString() ?? 'Seller';

        final total = (data['cartTotal'] as num?)?.toDouble() ??
            (data['orderTotal'] as num?)?.toDouble() ??
            0;

        final shortId = order.id.length > 8
            ? order.id.substring(0, 8).toUpperCase()
            : order.id.toUpperCase();

        final items = data['cartItems'] is List
            ? List<dynamic>.from(data['cartItems'])
            : <dynamic>[];

        int quantity = 0;

        for (final item in items) {
          quantity += (item['quantity'] as num?)?.toInt() ?? 0;
        }

        return Material(
          color: cardGreen,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CashOnDeliveryOrderTrackingScreen(
                    orderId: order.id,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: primaryDarkGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon(status),
                      color: primaryGold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #$shortId',
                          style: const TextStyle(
                            color: primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sellerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_statusLabel(status)}'
                          '${quantity > 0 ? ' • $quantity item${quantity > 1 ? 's' : ''}' : ''}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '€${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 15,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
