/// Local input checks only. This never proves registry existence or ownership.
/// Countries without a maintained format rule always require manual review.
String? registrationInputError({
  required String countryCode,
  required String kind,
  required String value,
  bool english = false,
}) {
  final number = value.trim().replaceAll(RegExp(r'\s+'), '');
  if (number.isEmpty) {
    return english
        ? 'Enter your official registration number.'
        : 'Saisissez votre numéro officiel.';
  }
  if (number.length > 100) {
    return english
        ? 'Check this number (100 characters maximum).'
        : 'Vérifiez ce numéro (100 caractères maximum).';
  }
  if (countryCode != 'FR') {
    return null;
  }
  final length = kind == 'SIREN' ? 9 : 14;
  if (!RegExp('^[0-9]{$length}\$').hasMatch(number) ||
      RegExp(r'^0+$').hasMatch(number)) {
    return english
        ? '$kind must contain $length digits.'
        : 'Le $kind doit contenir $length chiffres.';
  }
  // A local checksum is an input aid only; exceptional registry records must
  // remain reviewable instead of being silently marked verified or rejected.
  return null;
}

bool registrationChecksumMatches(String value) {
  final number = value.replaceAll(RegExp(r'\s+'), '');
  if (!RegExp(r'^([0-9]{9}|[0-9]{14})$').hasMatch(number) ||
      RegExp(r'^0+$').hasMatch(number)) {
    return false;
  }
  int luhn(String digits) {
    var sum = 0;
    for (var i = 0; i < digits.length; i++) {
      var digit = int.parse(digits[digits.length - 1 - i]);
      if (i.isOdd) {
        digit *= 2;
      }
      sum += digit > 9 ? digit - 9 : digit;
    }
    return sum % 10;
  }

  return luhn(number) == 0 &&
      (number.length == 9 || luhn(number.substring(0, 9)) == 0);
}
