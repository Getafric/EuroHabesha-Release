/// Group and association requests are independent of professional onboarding.
const connectSpaceKinds = ['group', 'association'];

String connectSpaceLabel(String kind) =>
    kind == 'association' ? 'Association' : 'Groupe';

String? connectSpaceValidation(
  Map<String, String> fields, {
  required bool hasLogo,
}) {
  if (!connectSpaceKinds.contains(fields['kind'])) {
    return 'Choisissez Groupe ou Association.';
  }
  for (final key in [
    'title',
    'description',
    'city',
    'country',
    'contactName',
    'contactPhone',
    'contactEmail',
  ]) {
    if ((fields[key] ?? '').trim().isEmpty) {
      return 'Complétez les informations et le contact privé.';
    }
  }
  if ((fields['title'] ?? '').length > 120 ||
      (fields['description'] ?? '').length > 3000) {
    return 'Le nom ou la présentation est trop long.';
  }
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
      .hasMatch(fields['contactEmail']!.trim())) {
    return 'Vérifiez l’adresse e-mail de contact.';
  }
  if (fields['kind'] == 'association') {
    if (!hasLogo) {
      return 'Ajoutez le logo de l’association.';
    }
    if ((fields['legalName'] ?? '').trim().isEmpty ||
        (fields['registrationNumber'] ?? '').trim().isEmpty) {
      return 'Indiquez le nom officiel et le numéro d’enregistrement de l’association.';
    }
  }
  return null;
}

/// Explicit whitelist: identity documents, registration numbers, contact phone,
/// contact e-mail and administrative notes never enter the public space record.
Map<String, dynamic> connectPublicSpaceFields(
  Map<String, dynamic> request,
  String id,
) => {
  'requestId': id,
  'ownerId': request['ownerId'],
  'kind': request['kind'],
  'title': request['title'],
  'description': request['description'],
  'city': request['city'],
  'country': request['country'],
  'topic': request['topic'],
  'logoUrl': request['logoUrl'],
  'audience': request['audience'],
  'status': 'published',
};

bool connectMayReadDiscussion({
  required bool published,
  required bool owner,
  required bool member,
}) => published && (owner || member);
