import 'l10n/app_ui.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'business_order_detail_screen.dart';
import 'business_checkout_screen.dart';
import 'professional_sales_summary.dart';

class BusinessOrdersScreen extends StatelessWidget {
  final String businessId;
  final String sourceCollection;
  final bool embedded;

  const BusinessOrdersScreen({
    super.key,
    required this.businessId,
    this.sourceCollection = '',
    this.embedded = false,
  });

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, auth) {
        if (auth.data == null || auth.data!.isAnonymous) {
          return const Scaffold(
            backgroundColor: primaryDarkGreen,
            body: Center(
              child: AppText(
                'Connectez-vous à votre compte professionnel.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
        return KeyedSubtree(
          key: ValueKey(auth.data!.uid),
          child: _signedIn(context),
        );
      },
    );
  }

  Widget _signedIn(BuildContext context) {
    const tabs = TabBar(
      indicatorColor: primaryGold,
      labelColor: primaryGold,
      unselectedLabelColor: Colors.white70,
      tabs: [
        Tab(text: 'En attente'),
        Tab(text: 'En cours'),
        Tab(text: 'Terminées'),
      ],
    );
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              Text(
                sourceCollection.isEmpty
                    ? 'Toutes les commandes de ce compte, y compris les anciennes sans établissement identifié.'
                    : embedded
                    ? 'Tout l’historique de cet établissement'
                    : 'Commandes liées précisément à cet établissement.',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (sourceCollection.isNotEmpty)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: primaryGold),
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          BusinessOrdersScreen(businessId: businessId),
                    ),
                  ),
                  child: const AppText(
                    'Commandes de tout mon compte',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              _PendingOrders(
                businessId: businessId,
                sourceCollection: sourceCollection,
              ),
              _ActiveOrders(
                businessId: businessId,
                sourceCollection: sourceCollection,
              ),
              _CompletedOrders(
                businessId: businessId,
                sourceCollection: sourceCollection,
              ),
            ],
          ),
        ),
      ],
    );
    if (embedded) {
      return DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const Material(color: primaryDarkGreen, child: tabs),
            Expanded(child: content),
          ],
        ),
      );
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: primaryDarkGreen,
        appBar: AppBar(
          backgroundColor: primaryDarkGreen,
          foregroundColor: primaryGold,
          title: Text(
            sourceCollection.isEmpty ? 'Commandes du compte' : 'Mes commandes',
            style: const TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: tabs,
        ),
        body: content,
      ),
    );
  }
}

class _PendingOrders extends StatelessWidget {
  final String businessId;
  final String sourceCollection;

  const _PendingOrders({required this.businessId, this.sourceCollection = ''});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('cashOnDeliveryOrders')
          .where(
            'sellerId',
            isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '',
          )
          .where('status', isEqualTo: 'placed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: BusinessOrdersScreen.primaryGold,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppText(
                'Impossible de charger les commandes.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final orders = (snapshot.data?.docs ?? [])
            .where(
              (order) =>
                  sourceCollection.isEmpty ||
                  orderMatchesProfessional(
                    order.data(),
                    sourceCollection,
                    businessId,
                  ),
            )
            .toList();

        if (orders.isEmpty) {
          return const _EmptyOrders(
            icon: Icons.notifications_none,
            title: 'Aucune nouvelle commande',
            message: 'Les nouvelles commandes de vos clients apparaîtront ici.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            final data = order.data();

            final buyerName = data['buyerName']?.toString().trim() ?? '';

            final buyerPhone = data['buyerPhone']?.toString().trim() ?? '';

            final deliveryAddress =
                data['deliveryAddress']?.toString().trim() ?? '';

            final notes = data['notes']?.toString().trim() ?? '';

            final rawCartItems = data['cartItems'];

            final List<Map<String, dynamic>> cartItems = rawCartItems is List
                ? rawCartItems
                      .whereType<Map>()
                      .map((item) => Map<String, dynamic>.from(item))
                      .toList()
                : <Map<String, dynamic>>[];

            final money = OrderMoneySnapshot.fromOrder(data);
            final totalText = savedOrderMoney(
              money.consistent ? money.customerTotal : null,
              currency: orderText(data['currency']).isEmpty
                  ? '€'
                  : orderText(data['currency']).toUpperCase(),
            );

            final shortOrderId = order.id.length > 8
                ? order.id.substring(0, 8).toUpperCase()
                : order.id.toUpperCase();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BusinessOrdersScreen.cardGreen,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        color: BusinessOrdersScreen.primaryGold,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppText(
                          'Commande #$shortOrderId',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        totalText,
                        style: const TextStyle(
                          color: BusinessOrdersScreen.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.white70,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          buyerName.isEmpty ? 'Client' : buyerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (buyerPhone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          color: Colors.white54,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          buyerPhone,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                  if (deliveryAddress.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white54,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            deliveryAddress,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  const AppText(
                    'Détails de la commande',
                    style: TextStyle(
                      color: BusinessOrdersScreen.primaryGold,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (cartItems.isEmpty)
                    const AppText(
                      'Aucun détail disponible.',
                      style: TextStyle(color: Colors.white60),
                    )
                  else
                    ...cartItems.map((item) {
                      final name = item['name']?.toString() ?? 'Article';

                      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;

                      final rawLineTotal = item['total'];

                      final lineTotal = rawLineTotal is num
                          ? rawLineTotal.toDouble()
                          : double.tryParse(rawLineTotal?.toString() ?? '') ??
                                0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            AppText(
                              '× $quantity',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 72,
                              child: AppText(
                                '${lineTotal.toStringAsFixed(2)} €',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: BusinessOrdersScreen.primaryGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText(
                            'Note du client',
                            style: TextStyle(
                              color: BusinessOrdersScreen.primaryGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            notes,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12),
                  Row(
                    children: [
                      const AppText(
                        'Total',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        totalText,
                        style: const TextStyle(
                          color: BusinessOrdersScreen.primaryGold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            if (data['paymentProvider'] ==
                                'stripe_connect_live') {
                              await requestBusinessOrderRefund(
                                context,
                                order.id,
                              );
                              return;
                            }
                            await order.reference.update({
                              'status': 'rejected',
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                          child: const AppText('Refuser'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              data['paymentProvider'] ==
                                      'stripe_connect_live' &&
                                  data['paymentStatus'] != 'paid'
                              ? null
                              : () async {
                                  await order.reference.update({
                                    'status': 'accepted',
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BusinessOrdersScreen.primaryGold,
                            foregroundColor:
                                BusinessOrdersScreen.primaryDarkGreen,
                          ),
                          child: const AppText(
                            'Accepter',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyOrders({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 38,
                color: BusinessOrdersScreen.primaryGold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveOrders extends StatelessWidget {
  final String businessId;
  final String sourceCollection;

  const _ActiveOrders({required this.businessId, this.sourceCollection = ''});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('cashOnDeliveryOrders')
          .where(
            'sellerId',
            isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '',
          )
          .where('status', whereIn: ['accepted', 'preparing', 'ready'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: BusinessOrdersScreen.primaryGold,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppText(
                'Impossible de charger les commandes.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final orders = (snapshot.data?.docs ?? [])
            .where(
              (order) =>
                  sourceCollection.isEmpty ||
                  orderMatchesProfessional(
                    order.data(),
                    sourceCollection,
                    businessId,
                  ),
            )
            .toList();

        if (orders.isEmpty) {
          return const _EmptyOrders(
            icon: Icons.restaurant,
            title: 'Aucune commande en cours',
            message:
                'Les commandes acceptées et en préparation apparaîtront ici.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            final data = order.data();

            final customerName =
                data['buyerName']?.toString() ??
                data['customerName']?.toString() ??
                'Client';

            final status = data['status']?.toString() ?? 'accepted';

            final orderType = data['orderType']?.toString() ?? 'Commande';

            String statusText;

            switch (status) {
              case 'preparing':
                statusText = 'En préparation';
                break;
              case 'ready':
                statusText = 'Prête';
                break;
              default:
                statusText = 'Acceptée';
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BusinessOrdersScreen.cardGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.restaurant,
                        color: BusinessOrdersScreen.primaryGold,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          customerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: BusinessOrdersScreen.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    'Type : $orderType',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (status == 'accepted') ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            data['paymentProvider'] == 'stripe_connect_live' &&
                                data['paymentStatus'] != 'paid'
                            ? null
                            : () async {
                                await order.reference.update({
                                  'status': 'preparing',
                                  'preparingAt': FieldValue.serverTimestamp(),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BusinessOrdersScreen.primaryGold,
                          foregroundColor:
                              BusinessOrdersScreen.primaryDarkGreen,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        icon: const Icon(Icons.restaurant_menu),
                        label: const AppText(
                          'Commencer la préparation',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                  if (status == 'preparing') ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            data['paymentProvider'] == 'stripe_connect_live' &&
                                data['paymentStatus'] != 'paid'
                            ? null
                            : () async {
                                await order.reference.update({
                                  'status': 'ready',
                                  'readyAt': FieldValue.serverTimestamp(),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BusinessOrdersScreen.primaryGold,
                          foregroundColor:
                              BusinessOrdersScreen.primaryDarkGreen,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const AppText(
                          'Marquer comme prête',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                  if (status == 'ready') ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            data['paymentProvider'] == 'stripe_connect_live' &&
                                data['paymentStatus'] != 'paid'
                            ? null
                            : () async {
                                await order.reference.update({
                                  'status': 'completed',
                                  'completedAt': FieldValue.serverTimestamp(),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BusinessOrdersScreen.primaryGold,
                          foregroundColor:
                              BusinessOrdersScreen.primaryDarkGreen,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        icon: const Icon(Icons.done_all),
                        label: const AppText(
                          'Terminer la commande',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CompletedOrders extends StatelessWidget {
  final String businessId;
  final String sourceCollection;

  const _CompletedOrders({
    required this.businessId,
    this.sourceCollection = '',
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('cashOnDeliveryOrders')
          .where(
            'sellerId',
            isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '',
          )
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: BusinessOrdersScreen.primaryGold,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppText(
                'Impossible de charger les commandes terminées.\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final orders = (snapshot.data?.docs ?? [])
            .where(
              (order) =>
                  sourceCollection.isEmpty ||
                  orderMatchesProfessional(
                    order.data(),
                    sourceCollection,
                    businessId,
                  ),
            )
            .toList();

        if (orders.isEmpty) {
          return const _EmptyOrders(
            icon: Icons.check_circle_outline,
            title: 'Aucune commande terminée',
            message: 'Les commandes terminées apparaîtront ici.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            final data = order.data();

            final customerName =
                data['buyerName']?.toString() ??
                data['customerName']?.toString() ??
                'Client';

            final orderType = data['orderType']?.toString() ?? 'Commande';

            final money = OrderMoneySnapshot.fromOrder(data);
            final total = money.consistent ? money.customerTotal : null;

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BusinessOrderDetailScreen(orderId: order.id),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BusinessOrdersScreen.cardGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: BusinessOrdersScreen.primaryGold,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            customerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const AppText(
                          'Terminée',
                          style: TextStyle(
                            color: BusinessOrdersScreen.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AppText(
                      'Type : $orderType',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (total != null) ...[
                      const SizedBox(height: 4),
                      AppText(
                        'Total client : ${savedOrderMoney(total, currency: orderText(data['currency']).isEmpty ? '€' : orderText(data['currency']).toUpperCase())}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
