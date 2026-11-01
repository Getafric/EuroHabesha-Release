/// Draft offer only: no purchase, verification badge or fee entitlement.
int? subscriptionPriceCents(String input) {
  final value = input.trim();
  if (!RegExp(r'^\d{1,4}(?:[,.]\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.replaceAll(',', '.').split('.');
  final cents =
      int.parse(parts[0]) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  return cents >= 1 && cents <= 999999 ? cents : null;
}

int? subscriptionDiscountPercent(String input) {
  final text = input.trim();
  if (!RegExp(r'^\d{1,3}$').hasMatch(text)) return null;
  final value = int.parse(text);
  return value >= 0 && value <= 100 ? value : null;
}

String subscriptionPriceText(int cents) =>
    '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';

class ProfessionalSubscriptionPrices {
  const ProfessionalSubscriptionPrices({
    this.silverCents = 599,
this.goldCents = 999,
this.vipCents = 1499,
this.period = 'P6M',
    this.silverDiscountPercent = 25,
    this.goldDiscountPercent = 50,
    this.vipDiscountPercent = 100,
    this.revision = 0,
    this.compatible = true,
  });

  static const periods = {
    'P1M': '1 mois',
    'P2M': '2 mois',
    'P3M': '3 mois',
    'P4M': '4 mois',
    'P5M': '5 mois',
    'P6M': '6 mois',
    'P7M': '7 mois',
    'P8M': '8 mois',
    'P9M': '9 mois',
    'P10M': '10 mois',
    'P11M': '11 mois',
    'P1Y': '1 an',
  };

  static const fields = {
    'schemaVersion',
    'currency',
    'period',
    'silverCents',
    'goldCents',
    'vipCents',
    'silverDiscountPercent',
    'goldDiscountPercent',
    'vipDiscountPercent',
    'revision',
    'updatedAt',
    'updatedByUid',
  };
  final int silverCents, goldCents, vipCents, revision;
  final int silverDiscountPercent, goldDiscountPercent, vipDiscountPercent;
  final String period;
  final bool compatible;
  String get periodLabel => periods[period] ?? '6 mois';
  bool get progressive => silverCents <= goldCents && goldCents <= vipCents;
  bool get progressiveDiscounts =>
      silverDiscountPercent <= goldDiscountPercent &&
      goldDiscountPercent <= vipDiscountPercent;
  int centsFor(String tier) => switch (tier) {
    'silver' => silverCents,
    'gold' => goldCents,
    'vip' => vipCents,
    _ => throw ArgumentError('Formule inconnue.'),
  };
  int discountFor(String tier) => switch (tier) {
    'silver' => silverDiscountPercent,
    'gold' => goldDiscountPercent,
    'vip' => vipDiscountPercent,
    _ => throw ArgumentError('Formule inconnue.'),
  };
  bool get _valid =>
      compatible &&
      progressive &&
      progressiveDiscounts &&
      periods.containsKey(period) &&
      revision >= 0 &&
      [
        silverCents,
        goldCents,
        vipCents,
      ].every((value) => value >= 1 && value <= 999999) &&
      [
        silverDiscountPercent,
        goldDiscountPercent,
        vipDiscountPercent,
      ].every((value) => value >= 0 && value <= 100);

  factory ProfessionalSubscriptionPrices.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const ProfessionalSubscriptionPrices();
    final s = data['silverCents'], g = data['goldCents'], v = data['vipCents'];
    final ds = data['silverDiscountPercent'],
        dg = data['goldDiscountPercent'],
        dv = data['vipDiscountPercent'];
    final revision = data['revision'], period = data['period'];
    if (s is! int ||
        g is! int ||
        v is! int ||
        ds is! int ||
        dg is! int ||
        dv is! int ||
        revision is! int ||
        revision < 1 ||
        period is! String ||
        data['schemaVersion'] != 1 ||
        data['currency'] != 'EUR' ||
        data.keys.any((key) => !fields.contains(key))) {
      return const ProfessionalSubscriptionPrices(compatible: false);
    }
    final prices = ProfessionalSubscriptionPrices(
      silverCents: s,
      goldCents: g,
      vipCents: v,
      silverDiscountPercent: ds,
      goldDiscountPercent: dg,
      vipDiscountPercent: dv,
      revision: revision,
      period: period,
    );
    return prices._valid
        ? prices
        : const ProfessionalSubscriptionPrices(compatible: false);
  }

  Map<String, dynamic> document({
    required String uid,
    required Object timestamp,
  }) {
    if (!_valid || uid.trim().isEmpty) {
      throw ArgumentError('Tarifs ou avantages invalides.');
    }
    return {
      'schemaVersion': 1,
      'currency': 'EUR',
      'period': period,
      'silverCents': silverCents,
      'goldCents': goldCents,
      'vipCents': vipCents,
      'silverDiscountPercent': silverDiscountPercent,
      'goldDiscountPercent': goldDiscountPercent,
      'vipDiscountPercent': vipDiscountPercent,
      'revision': revision + 1,
      'updatedAt': timestamp,
      'updatedByUid': uid,
    };
  }
}
