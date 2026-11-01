// Pure Dart: all amounts come from saved orders, never today's fee settings.
const professionalOrderCollections = {'businessSubmissions', 'jobSubmissions'};

String orderText(Object? value) => value is String ? value.trim() : '';

Map<String, dynamic> orderMap(Object? value) => value is Map
    ? Map<String, dynamic>.fromEntries(
        value.entries
            .where((entry) => entry.key is String)
            .map((entry) => MapEntry(entry.key as String, entry.value)),
      )
    : <String, dynamic>{};

class ProfessionalOrderSource {
  final String collection;
  final String id;
  const ProfessionalOrderSource(this.collection, this.id);

  bool sameAs(ProfessionalOrderSource other) =>
      collection == other.collection && id == other.id;
}

// Exact original source only. Conflicting, incomplete and public-copy links
// cannot silently choose an establishment by owner, name or same document ID.
ProfessionalOrderSource? professionalOrderSource(Map<String, dynamic> data) {
  ProfessionalOrderSource? found;
  for (final map in [data, orderMap(data['sourceData'])]) {
    for (final keys in const [
      ['sourceCollection', 'sourceId'],
      ['roomLayoutSourceCollection', 'roomLayoutBusinessId'],
      ['professionalSourceCollection', 'professionalBusinessId'],
    ]) {
      final collection = orderText(map[keys[0]]);
      final id = orderText(map[keys[1]]);
      if (collection.isEmpty && id.isEmpty) continue;
      // Public copies may accompany an exact original room-layout link.
      if (collection == 'businesses' || collection == 'jobs') continue;
      if (!professionalOrderCollections.contains(collection) ||
          id.isEmpty ||
          id.length > 150 ||
          id.contains('/') ||
          id == '.' ||
          id == '..') {
        return null;
      }
      final candidate = ProfessionalOrderSource(collection, id);
      if (found != null && !found.sameAs(candidate)) return null;
      found = candidate;
    }
  }
  return found;
}

bool orderMatchesProfessional(
  Map<String, dynamic> data,
  String collection,
  String businessId,
) {
  final source = professionalOrderSource(data);
  return source != null &&
      source.collection == collection &&
      source.id == businessId;
}

// Invalid or absent financial values stay unknown, rather than becoming 0.
int? savedOrderCents(Object? value) {
  final double? amount;
  if (value is num) {
    amount = value.toDouble();
  } else if (value is String &&
      RegExp(r'^\d+(?:[.,]\d{1,2})?$').hasMatch(value.trim())) {
    amount = double.tryParse(value.trim().replaceAll(',', '.'));
  } else {
    return null;
  }
  if (amount == null || !amount.isFinite || amount < 0 || amount > 1000000000) {
    return null;
  }
  final cents = (amount * 100).round();
  if ((amount * 100 - cents).abs() > 0.0001) return null;
  return cents;
}

String savedOrderMoney(int? cents, {String currency = '€'}) => cents == null
    ? 'Non renseigné'
    : '${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')} $currency';

class OrderMoneySnapshot {
  final int? subtotal;
  final int? customerFee;
  final int? businessFee;
  final int? customerTotal;
  final bool legacyTotal;
  final bool consistent;

  const OrderMoneySnapshot({
    required this.subtotal,
    required this.customerFee,
    required this.businessFee,
    required this.customerTotal,
    required this.legacyTotal,
    required this.consistent,
  });

  factory OrderMoneySnapshot.fromOrder(Map<String, dynamic> data) {
    final subtotal = savedOrderCents(data['orderTotal'] ?? data['cartTotal']);
    final customerFee = savedOrderCents(data['customerFee']);
    final businessFee = savedOrderCents(data['businessFee']);
    final explicitTotal = data.containsKey('customerTotal');
    final legacy =
        !explicitTotal &&
        !data.containsKey('customerFee') &&
        !data.containsKey('feeConfigSnapshot');
    final total = explicitTotal
        ? savedOrderCents(data['customerTotal'])
        : customerFee != null && subtotal != null
        ? subtotal + customerFee
        : legacy
        ? subtotal
        : null;
    return OrderMoneySnapshot(
      subtotal: subtotal,
      customerFee: customerFee,
      businessFee: businessFee,
      customerTotal: total,
      legacyTotal: legacy,
      consistent:
          (subtotal == null ||
              customerFee == null ||
              total == null ||
              subtotal + customerFee == total) &&
          (businessFee == null || subtotal == null || businessFee <= subtotal),
    );
  }
}

bool orderIsTest(Map<String, dynamic> data) =>
    data['livemode'] == false ||
    data['isTest'] == true ||
    orderText(data['environment']).toLowerCase() == 'test' ||
    orderText(data['paymentEnvironment']).toLowerCase() == 'test';

bool orderReportedPaid(Map<String, dynamic> data) {
  final payment = orderText(data['paymentStatus']).toLowerCase();
  // A negative explicit payment state overrides a stale legacy isPaid flag.
  if (payment.isNotEmpty) return payment == 'paid';
  return data['isPaid'] == true;
}

// Deposits and refunds are separate movements, never a full sale by default.
bool orderExcludedFromSales(Map<String, dynamic> data) {
  final status = orderText(data['status']).toLowerCase();
  final refund = orderText(data['refundStatus']).toLowerCase();
  if (const {
        'cancelled',
        'canceled',
        'rejected',
        'refunded',
        'pendingpayment',
        'partiallyrefunded',
        'partially_refunded',
      }.contains(status) ||
      const {
        'refunded',
        'partially_refunded',
        'partial',
        'pending',
      }.contains(refund)) {
    return true;
  }
  for (final key in ['refundAmount', 'refundedAmountCents']) {
    if (!data.containsKey(key) || data[key] == null) continue;
    final value = key == 'refundAmount'
        ? savedOrderCents(data[key])
        : data[key] is int && data[key] >= 0
        ? data[key] as int
        : null;
    if (value == null || value > 0) return true;
  }
  return orderText(data['paymentMethod']).toLowerCase() == 'appdeposit';
}

String savedOrderPaymentLabel(Map<String, dynamic> data) {
  if (orderExcludedFromSales(data)) {
    return 'Statut à consulter dans la commande';
  }
  return orderReportedPaid(data) ? 'Déclaré payé' : 'Paiement non confirmé';
}

bool orderCashPayment(Map<String, dynamic> data) => const {
  'cashondelivery',
  'cash_on_delivery',
  'cash',
  'cod',
  'cashonpickup',
}.contains(orderText(data['paymentMethod']).toLowerCase());

bool orderOnlinePayment(Map<String, dynamic> data) => const {
  'stripe',
  'card',
  'online',
  'stripeconnect',
}.contains(orderText(data['paymentMethod']).toLowerCase());

class ProfessionalSalesSummary {
  int received = 0;
  int paid = 0;
  int cashPaid = 0;
  int onlinePaid = 0;
  int otherPaid = 0;
  int grossCents = 0;
  int customerTotalsCents = 0;
  int registeredCommissionCents = 0;
  int collectedCommissionCents = 0;
  int uncollectedCommissionCents = 0;
  int stripeFeesCents = 0;
  int missingAmounts = 0;
  int missingTotals = 0;
  int missingCommissions = 0;
  int missingStripeFees = 0;
  int missingPaidDates = 0;
  int excludedPaidOrders = 0;
  int invalidCurrency = 0;
  int inconsistentOrders = 0;
  int unmatched = 0;
  int testOrders = 0;

  ProfessionalSalesSummary.fromOrders(
    Iterable<Map<String, dynamic>> orders, {
    required String sourceCollection,
    required String businessId,
    required String ownerId,
    required DateTime start,
    required DateTime end,
  }) {
    bool inPeriod(Object? value) =>
        value is DateTime && !value.isBefore(start) && value.isBefore(end);
    for (final data in orders) {
      if (orderText(data['sellerId']) != ownerId) continue;
      if (!orderMatchesProfessional(data, sourceCollection, businessId)) {
        if (professionalOrderSource(data) == null) unmatched++;
        continue;
      }
      if (orderIsTest(data)) {
        testOrders++;
        continue;
      }
      if (inPeriod(data['createdAt'])) received++;
      if (!orderReportedPaid(data)) continue;
      final paidDate = data['paidAt'];
      // Do not put an old payment in today's sales using the order date.
      if (paidDate is! DateTime) {
        missingPaidDates++;
        continue;
      }
      if (!inPeriod(paidDate)) continue;
      if (orderExcludedFromSales(data)) {
        excludedPaidOrders++;
        continue;
      }
      final currency = orderText(data['currency']).toUpperCase();
      if (currency.isNotEmpty && currency != 'EUR') {
        invalidCurrency++;
        continue;
      }
      final money = OrderMoneySnapshot.fromOrder(data);
      if (!money.consistent) {
        inconsistentOrders++;
        continue;
      }
      paid++;
      if (orderCashPayment(data)) {
        cashPaid++;
      } else if (orderOnlinePayment(data)) {
        onlinePaid++;
      } else {
        otherPaid++;
      }
      if (money.subtotal == null) {
        missingAmounts++;
      } else {
        grossCents += money.subtotal!;
      }
      if (money.customerTotal == null) {
        missingTotals++;
      } else {
        customerTotalsCents += money.customerTotal!;
      }
      if (money.businessFee == null) {
        missingCommissions++;
      } else {
        registeredCommissionCents += money.businessFee!;
        if (data['commissionCollectionStatus'] == 'collected') {
          collectedCommissionCents += money.businessFee!;
        } else {
          uncollectedCommissionCents += money.businessFee!;
        }
      }
      if (orderOnlinePayment(data)) {
        final cents = data['stripeFeeCents'];
        if (cents is int && cents >= 0 && cents <= 100000000000) {
          stripeFeesCents += cents;
        } else {
          missingStripeFees++;
        }
      }
    }
  }
}
