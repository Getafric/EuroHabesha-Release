const ehCurrencies = {
  'EUR': 'EUR — Euro',
  'GBP': 'GBP — Livre sterling',
  'CHF': 'CHF — Franc suisse',
  'USD': 'USD — Dollar',
  'NOK': 'NOK — Couronne norvégienne',
  'SEK': 'SEK — Couronne suédoise',
  'DKK': 'DKK — Couronne danoise',
  'ETB': 'ETB — Birr',
};
String ehMoney(dynamic cents, [String currency = 'EUR']) =>
    '${((cents as num? ?? 0) / 100).toStringAsFixed(2).replaceAll('.', ',')} ${currency == 'EUR' ? '€' : currency}';
int ehCents(dynamic value) {
  final s = value.toString().trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(s))
    throw const FormatException(
      'Saisissez un montant avec deux décimales maximum.',
    );
  return (double.parse(s) * 100).round();
}
