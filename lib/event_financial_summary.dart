// Financial display uses saved ticket facts. It never invents a commission,
// processing fee, payout, or LIVE environment for a legacy ticket.
int? _cents(Object? value) {
  if (value is! num && value is! String) return null;
  final raw = value.toString().trim().replaceAll(',', '.');
  if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(raw)) return null;
  final parts = raw.split('.');
  return int.parse(parts[0]) * 100 +
      int.parse((parts.length > 1 ? parts[1] : '').padRight(2, '0'));
}

bool eventTicketFinancialIncluded(Map<String, dynamic> ticket) =>
    ticket['paymentStatus'] == 'purchased' &&
    ticket['livemode'] != false &&
    ticket['isTest'] != true &&
    ticket['environment'] != 'test' &&
    ticket['paymentEnvironment'] != 'test' &&
    !const {
      'refunded',
      'partial',
      'partially_refunded',
      'pending',
    }.contains(ticket['refundStatus']) &&
    (ticket['refundedAmountCents'] == null ||
        ticket['refundedAmountCents'] == 0);

String eventSavedMoney(int? cents) => cents == null
    ? 'Non renseigné'
    : '${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')} €';

class EventFinancialSummary {
  final int count;
  final int unknownMode;
  final int? grossCents;
  final int? customerFeesCents;
  final int? merchantCommissionCents;
  final int? stripeFeesCents;
  final int? merchantNetCents;

  const EventFinancialSummary._(
    this.count,
    this.unknownMode,
    this.grossCents,
    this.customerFeesCents,
    this.merchantCommissionCents,
    this.stripeFeesCents,
    this.merchantNetCents,
  );

  factory EventFinancialSummary.fromTickets(
    Iterable<Map<String, dynamic>> tickets,
    String eventId,
  ) {
    final included = tickets
        .where(
          (t) => t['eventId'] == eventId && eventTicketFinancialIncluded(t),
        )
        .toList();
    int? gross = 0;
    int? commission = 0;
    int? stripe = 0;
    final groups = <String, List<Map<String, dynamic>>>{};
    var unknownMode = 0;
    var orphanFees = false;
    for (final t in included) {
      if (t['livemode'] != true && t['environment'] != 'live') unknownMode++;
      final price = _cents(t['price']);
      gross = gross != null && price != null ? gross + price : null;
      // These are PER-TICKET fields only. Purchase-wide serviceFeeTotal is
      // handled below once per intent, never subtracted as merchant commission.
      final businessFee = _cents(t['businessFee']);
      final processing = t['stripeFeeCents'];
      final knownBusinessFee =
          businessFee ??
          (price == 0 && !t.containsKey('businessFee') ? 0 : null);
      final knownProcessing = processing is int && processing >= 0
          ? processing
          : price == 0 && !t.containsKey('stripeFeeCents')
          ? 0
          : null;
      commission = commission != null && knownBusinessFee != null
          ? commission + knownBusinessFee
          : null;
      stripe = stripe != null && knownProcessing != null
          ? stripe + knownProcessing
          : null;
      final intent = t['stripePaymentIntentId'];
      if (intent is String && intent.startsWith('pi_')) {
        groups.putIfAbsent(intent, () => []).add(t);
      } else if (price != 0) {
        orphanFees = true;
      }
    }
    int? customerFees = orphanFees ? null : 0;
    for (final group in groups.values) {
      final first = group.first;
      final quantity = first['purchaseQuantity'];
      final fee = _cents(first['serviceFeeTotal']);
      if (quantity is! int ||
          quantity < 1 ||
          group.length != quantity ||
          fee == null ||
          group.any(
            (t) =>
                t['purchaseQuantity'] != quantity ||
                _cents(t['serviceFeeTotal']) != fee,
          )) {
        customerFees = null;
      } else if (customerFees != null) {
        customerFees += fee;
      }
    }
    final net =
        gross != null &&
            commission != null &&
            stripe != null &&
            gross >= commission + stripe
        ? gross - commission - stripe
        : null;
    return EventFinancialSummary._(
      included.length,
      unknownMode,
      gross,
      customerFees,
      commission,
      stripe,
      net,
    );
  }
}
